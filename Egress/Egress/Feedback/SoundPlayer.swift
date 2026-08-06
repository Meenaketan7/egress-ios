import AVFoundation
import Foundation

// MARK: - SoundPlayer

/// The reduced §3.6 sound system: a small library of **all-original 8-bit-style** cues, synthesized in
/// memory from square- and triangle-wave oscillators (no bundled or copyrighted audio) and played
/// through one `AVAudioEngine`. v3 cuts the five-bus graph and ducking; what ships is the handful of
/// cues that carry the demo — the alarm, the threshold stings and the verdict motifs.
///
/// The session is `.ambient` + `.mixWithOthers`, so the **silent switch is respected** and the user's
/// own music is never interrupted. Audio carries no rubric weight of its own and is never the sole
/// channel for a safety event (§5.5 rule 6), so every failure path here is a silent no-op — the banner,
/// haptic and VoiceOver announcement already cover the event.
@MainActor
final class SoundPlayer {
    /// The cues the app actually plays. `sting` doubles for every escalation band and the WARN verdict;
    /// `verdictPass`/`verdictFail` are the ascending/descending verdict motifs.
    enum Cue { case klaxon, sting, verdictPass, verdictFail }

    init(settings: FeedbackSettings) {
        self.settings = settings
        // Render once up front — the buffers are tiny (< 1.5 s each) and never change.
        buffers = [
            .klaxon: Self.render(Self.klaxonScore),
            .sting: Self.render(Self.stingScore),
            .verdictPass: Self.render(Self.passScore),
            .verdictFail: Self.render(Self.failScore),
        ]
        // The two looping ambience beds — an all-original crowd murmur and a fire crackle, both ~4 s
        // and seamlessly loopable. Rendered once; their live level is set per frame by `setAmbience`.
        murmurBuffer = Self.renderMurmur()
        crackleBuffer = Self.renderCrackle()
    }

    /// Play a cue. Honours the master toggle and the −6 dB Reduce Audio Intensity cap; queues onto the
    /// player node so overlapping cues don't cut each other off.
    func play(_ cue: Cue) {
        guard settings.soundEnabled, let buffer = buffers[cue] else { return }
        do {
            try startIfNeeded()
            player.volume = settings.reduceAudioIntensity ? 0.5 : 1.0 // −6 dB ≈ ×0.5
            player.scheduleBuffer(buffer, at: nil, options: [], completionCallbackType: .dataPlayedBack) { _ in }
            if !player.isPlaying { player.play() }
        } catch {
            // Silent: the event's banner / haptic / announcement already carry it.
        }
    }

    // MARK: Ambient beds (crowd murmur + fire crackle)

    /// Begin the looping ambience under a run. Both beds start silent; `setAmbience` fades them in to
    /// match the crowd. A no-op when sound is off, so the silent switch and master toggle still win.
    func startAmbience() {
        guard settings.soundEnabled else { return }
        do { try startIfNeeded() } catch { return }
        if !ambienceScheduled {
            murmur.scheduleBuffer(murmurBuffer, at: nil, options: [.loops], completionCallbackType: .dataPlayedBack) { _ in }
            crackle.scheduleBuffer(crackleBuffer, at: nil, options: [.loops], completionCallbackType: .dataPlayedBack) { _ in }
            ambienceScheduled = true
        }
        murmur.volume = 0
        crackle.volume = 0
        if !murmur.isPlaying { murmur.play() }
        if !crackle.isPlaying { crackle.play() }
        ambienceOn = true
    }

    /// Set the live ambience level. `crowd` and `fire` are 0…1 — the murmur swells with the crowd's
    /// arousal, the crackle with how much fire is on the floor. Held well below the one-shot cues so it
    /// never masks the alarm or a sting.
    func setAmbience(crowd: Double, fire: Double) {
        guard ambienceOn else { return }
        let cap: Float = settings.reduceAudioIntensity ? 0.5 : 1.0
        murmur.volume = Float(min(1, max(0, crowd))) * 0.22 * cap
        crackle.volume = Float(min(1, max(0, fire))) * 0.34 * cap
    }

    /// Stop the ambience (a pause, the end of a run, or leaving the screen). One-shot cues are unaffected.
    func stopAmbience() {
        murmur.stop()
        crackle.stop()
        ambienceOn = false
        ambienceScheduled = false
    }

    /// Tear the engine down on backgrounding (§5.4); it restarts lazily on the next `play`.
    func stop() {
        player.stop()
        stopAmbience()
        engine.stop()
        try? session.setActive(false, options: .notifyOthersOnDeactivation)
        started = false
    }

    // MARK: Engine

    private let settings: FeedbackSettings
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    /// The two looping ambience voices, mixed in under the one-shot cues.
    private let murmur = AVAudioPlayerNode()
    private let crackle = AVAudioPlayerNode()
    private let session = AVAudioSession.sharedInstance()
    private let buffers: [Cue: AVAudioPCMBuffer]
    private let murmurBuffer: AVAudioPCMBuffer
    private let crackleBuffer: AVAudioPCMBuffer
    private var started = false
    private var ambienceOn = false
    private var ambienceScheduled = false

    /// One mono 44.1 kHz float format shared by every buffer and the player→mixer connection.
    private static let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
    private static let sampleRate: Double = 44_100

    private func startIfNeeded() throws {
        guard !started else { return }
        try session.setCategory(.ambient, options: [.mixWithOthers]) // respect silent switch + others' audio
        try session.setActive(true)
        if engine.attachedNodes.contains(player) == false {
            engine.attach(player)
            engine.connect(player, to: engine.mainMixerNode, format: Self.format)
        }
        for node in [murmur, crackle] where engine.attachedNodes.contains(node) == false {
            engine.attach(node)
            engine.connect(node, to: engine.mainMixerNode, format: Self.format)
        }
        try engine.start()
        started = true
    }

    // MARK: - Synthesis

    /// One note in a cue: pitch, length, timbre and gain.
    private struct Note { let hz: Double; let seconds: Double; let wave: Wave; let gain: Float }
    private enum Wave { case square, triangle }

    // Cue scores. Frequencies are plain equal-tempered pitches; the retro character comes from the
    // square/triangle timbre, not from any sample.

    /// 2-tone square alarm, 3 repetitions (A5 ↔ E5).
    private static let klaxonScore: [Note] = (0 ..< 3).flatMap { _ in
        [Note(hz: 880, seconds: 0.16, wave: .square, gain: 0.9),
         Note(hz: 659, seconds: 0.16, wave: .square, gain: 0.9)]
    }

    /// 3-note descending square sting — the threshold / WARN cue.
    private static let stingScore: [Note] = [
        Note(hz: 784, seconds: 0.11, wave: .square, gain: 0.8),
        Note(hz: 659, seconds: 0.11, wave: .square, gain: 0.8),
        Note(hz: 523, seconds: 0.16, wave: .square, gain: 0.8),
    ]

    /// Ascending 5-note major arpeggio — the PASS fanfare (C E G C E).
    private static let passScore: [Note] = [
        Note(hz: 523, seconds: 0.10, wave: .square, gain: 0.75),
        Note(hz: 659, seconds: 0.10, wave: .square, gain: 0.75),
        Note(hz: 784, seconds: 0.10, wave: .square, gain: 0.75),
        Note(hz: 1046, seconds: 0.10, wave: .square, gain: 0.75),
        Note(hz: 1318, seconds: 0.20, wave: .square, gain: 0.8),
    ]

    /// Descending 4-note minor motif on soft triangle waves — low and sombre, never comedic.
    private static let failScore: [Note] = [
        Note(hz: 440, seconds: 0.16, wave: .triangle, gain: 0.7),
        Note(hz: 392, seconds: 0.16, wave: .triangle, gain: 0.7),
        Note(hz: 349, seconds: 0.16, wave: .triangle, gain: 0.7),
        Note(hz: 262, seconds: 0.30, wave: .triangle, gain: 0.7),
    ]

    /// Render a note sequence into one PCM buffer, with a short linear attack/release per note so the
    /// square edges don't click.
    private static func render(_ notes: [Note]) -> AVAudioPCMBuffer {
        let totalFrames = notes.reduce(0) { $0 + Int($1.seconds * sampleRate) }
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(totalFrames))!
        buffer.frameLength = AVAudioFrameCount(totalFrames)
        let samples = buffer.floatChannelData![0]

        var cursor = 0
        for note in notes {
            let frames = Int(note.seconds * sampleRate)
            let ramp = min(frames / 2, Int(0.005 * sampleRate)) // ≤5 ms fade in/out
            for i in 0 ..< frames {
                let phase = Double(i) / sampleRate * note.hz
                let raw: Float = note.wave == .square
                    ? (phase.truncatingRemainder(dividingBy: 1) < 0.5 ? 1 : -1)
                    : Float(4 * abs(phase.truncatingRemainder(dividingBy: 1) - 0.5) - 1) // triangle
                var envelope: Float = 1
                if i < ramp { envelope = Float(i) / Float(ramp) }
                else if i > frames - ramp { envelope = Float(frames - i) / Float(ramp) }
                samples[cursor + i] = raw * note.gain * envelope * 0.3 // 0.3 = headroom against clipping
            }
            cursor += frames
        }
        return buffer
    }

    // MARK: - Ambience synthesis

    /// A tiny seeded xorshift so the ambience beds render identically every launch (and their loops
    /// are reproducible), without pulling in the engine's RNG.
    private struct Noise {
        var state: UInt64
        /// Next sample in −1…1.
        mutating func bipolar() -> Double {
            state ^= state << 13
            state ^= state >> 7
            state ^= state << 17
            return Double(state % 20001) / 10000.0 - 1.0
        }

        /// Next sample in 0…1.
        mutating func unit() -> Double { (bipolar() + 1) / 2 }
    }

    /// The crowd murmur: brown noise band-limited into the vocal range with a slow amplitude sway, so it
    /// reads as a room full of anxious people rather than static. All-original, no sample. The sway
    /// completes whole cycles across the buffer so the 4 s loop meets itself cleanly.
    private static func renderMurmur() -> AVAudioPCMBuffer {
        let seconds = 4.0
        let frames = Int(seconds * sampleRate)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frames))!
        buffer.frameLength = AVAudioFrameCount(frames)
        let samples = buffer.floatChannelData![0]

        var rng = Noise(state: 0x9E37_79B9_7F4A_7C15)
        var brown = 0.0
        var low = 0.0
        var highPrevIn = 0.0
        var highPrevOut = 0.0
        var peak = 1e-6
        for i in 0 ..< frames {
            let white = rng.bipolar()
            brown = (brown + 0.02 * white) * 0.995 // leaky integrator → warm low rumble
            low += 0.18 * (brown - low) // one-pole low-pass (~1.2 kHz)
            let highOut = 0.92 * (highPrevOut + low - highPrevIn) // one-pole high-pass (~200 Hz)
            highPrevIn = low
            highPrevOut = highOut
            let t = Double(i) / Double(frames)
            let sway = 0.6 + 0.4 * sin(2 * .pi * 3 * t) // 3 whole cycles → seamless loop
            let value = highOut * sway
            samples[i] = Float(value)
            peak = max(peak, abs(value))
        }
        let gain = Float(0.6 / peak) // normalise so the bed sits at a predictable level
        for i in 0 ..< frames { samples[i] *= gain }
        return buffer
    }

    /// The fire bed: a low roar (band-limited brown noise) plus scattered decaying crackle pops. Pops are
    /// placed by the seeded RNG and never in the last tenth of a second, so the loop's tail is quiet and
    /// the seam is silent.
    private static func renderCrackle() -> AVAudioPCMBuffer {
        let seconds = 4.0
        let frames = Int(seconds * sampleRate)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frames))!
        buffer.frameLength = AVAudioFrameCount(frames)
        let samples = buffer.floatChannelData![0]

        var rng = Noise(state: 0xD1B5_4A32_D192_ED03)
        // Low roar underlay.
        var brown = 0.0
        var low = 0.0
        for i in 0 ..< frames {
            brown = (brown + 0.02 * rng.bipolar()) * 0.995
            low += 0.05 * (brown - low)
            samples[i] = Float(low * 2.4)
        }
        // Crackle pops — short, quick-decaying filtered-noise bursts.
        let quietTail = Int(0.1 * sampleRate)
        for _ in 0 ..< 40 {
            let start = Int(rng.unit() * Double(frames - quietTail))
            let length = Int((0.005 + rng.unit() * 0.02) * sampleRate)
            let amp = 0.4 + rng.unit() * 0.5
            for k in 0 ..< length where start + k < frames {
                let envelope = exp(-Double(k) / Double(length) * 5) // fast decay = a "tick"
                samples[start + k] += Float(rng.bipolar() * envelope * amp)
            }
        }
        // Normalise.
        var peak: Float = 1e-6
        for i in 0 ..< frames { peak = max(peak, abs(samples[i])) }
        let gain = 0.7 / peak
        for i in 0 ..< frames { samples[i] *= gain }
        return buffer
    }
}
