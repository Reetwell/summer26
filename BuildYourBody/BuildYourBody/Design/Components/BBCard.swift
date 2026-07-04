import SwiftUI

// Soft card surface used across every screen — mirrors the web app's cards
struct BBCard<Content: View>: View {
    var padding: CGFloat = Spacing.md
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.bbSurface)
            .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
            .shadow(color: .black.opacity(0.05), radius: 12, y: 4)
    }
}

// Staggered entrance — cards slide up + fade in, like the web's acctCardIn
struct SlideIn: ViewModifier {
    let delay: Double
    @State private var shown = false

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown ? 0 : 14)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.85).delay(delay)) {
                    shown = true
                }
            }
    }
}

extension View {
    func slideIn(delay: Double = 0) -> some View {
        modifier(SlideIn(delay: delay))
    }
}
