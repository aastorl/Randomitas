internal import SwiftUI

extension View {
    @ViewBuilder
    func appGlassEffect() -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(.clear)
        } else {
            // Fallback for iOS < 26. Keep it subtle and rely on existing clipShape.
            self.background(.ultraThinMaterial)
        }
    }
}
