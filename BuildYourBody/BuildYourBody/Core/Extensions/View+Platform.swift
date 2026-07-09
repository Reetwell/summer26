import SwiftUI

// Safe array subscript — returns nil instead of crashing on out-of-bounds
extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// Cross-platform helpers — iOS-only modifiers become no-ops on macOS
extension View {
    @ViewBuilder
    func hideNavigationBar() -> some View {
        #if os(iOS)
        self.toolbar(.hidden, for: .navigationBar)
        #else
        self
        #endif
    }

    @ViewBuilder
    func inlineNavigationTitle() -> some View {
        #if os(iOS)
        self.navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }

    @ViewBuilder
    func emailKeyboard() -> some View {
        #if os(iOS)
        self.keyboardType(.emailAddress)
            .textInputAutocapitalization(.never)
        #else
        self
        #endif
    }

    /// Caps content width on wide screens (iPad/tablet) so it sits as a
    /// comfortable centred column instead of stretching. No effect on
    /// iPhone (the screen is narrower than the cap).
    func readableWidth(_ maxWidth: CGFloat = 720) -> some View {
        self
            .frame(maxWidth: maxWidth)
            .frame(maxWidth: .infinity)
    }
}
