import SwiftUI

struct BBButton: View {
    let title: String
    var style: Style = .primary
    let action: () -> Void

    enum Style { case primary, secondary, ghost }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.bbHeadline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(background)
                .foregroundStyle(foreground)
                .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.md)
                        .stroke(borderColor, lineWidth: style == .secondary ? 1 : 0)
                )
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private var background: Color {
        switch style {
        case .primary:   return .bbAccent
        case .secondary: return .clear
        case .ghost:     return .clear
        }
    }

    private var foreground: Color {
        switch style {
        case .primary:   return .white
        case .secondary: return .bbAccent
        case .ghost:     return .bbAccent
        }
    }

    private var borderColor: Color {
        style == .secondary ? .bbAccent.opacity(0.4) : .clear
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
