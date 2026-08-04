import SwiftUI

extension View {
    /// Raised card — the signature look: a solid cream fill inside a chunky charcoal outline, no shadow.
    /// Depth comes from the 2 pt outline, never a blur (design: "chunky charcoal outlines, cream ground").
    func egRaisedSurface(cornerRadius: CGFloat = EgressRadius.lg) -> some View {
        self
            .background {
                RoundedRectangle.egSquircle(cornerRadius).fill(Color.egSurfaceRaised)
            }
            .overlay {
                RoundedRectangle.egSquircle(cornerRadius)
                    .strokeBorder(Color.egOutline, lineWidth: 2)
            }
    }

    /// Sunken chip / inset field — a slightly darker cream with a soft tan hairline. Used for chips,
    /// HUD pills and inline metrics that should read *inside* a card rather than lifting off it.
    /// (Retains the old `egGlassSurface` name; the app has no blur glass in this theme.)
    func egGlassSurface(cornerRadius: CGFloat = EgressRadius.md) -> some View {
        self
            .background {
                RoundedRectangle.egSquircle(cornerRadius).fill(Color.egSurfaceSunken)
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
    .background(Color.egGround)
    .preferredColorScheme(.light)
}
