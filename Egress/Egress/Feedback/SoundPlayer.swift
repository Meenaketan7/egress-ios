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

    /// Tear the engine down on backgrounding (§5.4); it restarts lazily on the next `play`.
    func stop() {
        player.stop()
        engine.stop()
        try? session.setActive(false, options: .notifyOthersOnDeactivation)
        started = false
    }

    // MARK: Engine

    private let settings: FeedbackSettings
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let session = AVAudioSession.sharedInstance()
    private let buffers: [Cue: AVAudioPCMBuffer]
    private var started = false

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
}
