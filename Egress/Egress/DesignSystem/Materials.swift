import SwiftUI

extension View {
    /// Glass chrome (HUD, sheets): a material tinted with the app's dark glass tint.
    /// Depth = a 1 pt hairline, never a shadow (design spec §3.3).
    func egGlassSurface(cornerRadius: CGFloat = EgressRadius.md) -> some View {
        self
            .background {
                ZStack {
                    RoundedRectangle.egSquircle(cornerRadius).fill(.ultraThinMaterial)
                    RoundedRectangle.egSquircle(cornerRadius).fill(Color.egGlassTint)
                }
            }
            .overlay {
                RoundedRectangle.egSquircle(cornerRadius)
                    .strokeBorder(Color.egSeparator, lineWidth: 1)
            }
    }

    /// Raised solid surface (cards): raised colour + hairline, no shadow.
    func egRaisedSurface(cornerRadius: CGFloat = EgressRadius.lg) -> some View {
        self
            .background {
                RoundedRectangle.egSquircle(cornerRadius).fill(Color.egSurfaceRaised)
            }
            .overlay {
                RoundedRectangle.egSquircle(cornerRadius)
                    .strokeBorder(Color.egSeparator, lineWidth: 1)
            }
    }
}

#Preview {
    VStack(spacing: EgressSpacing.lg) {
        Label("Simulate", app: .simulate)
            .egData()
            .foregroundStyle(Color.egTextPrimary)
            .padding(EgressSpacing.md)
            .egGlassSurface()

        HStack(spacing: EgressSpacing.md) {
            Image(app: .pass).foregroundStyle(Color.egVerdictPass)
            Image(app: .warn).foregroundStyle(Color.egVerdictWarn)
            Image(app: .fail).foregroundStyle(Color.egVerdictFail)
            Image(app: .density).foregroundStyle(Color.egTextSecondary)
        }
        .font(.title2)
        .padding(EgressSpacing.md)
        .egRaisedSurface()
    }
    .padding(EgressSpacing.xl)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.egCanvasBase)
    .preferredColorScheme(.dark)
}
