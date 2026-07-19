import SwiftUI

struct BBTextField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var isSecure = false

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(label)
                .font(.bbSubhead)
                .foregroundStyle(.secondary)

            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .font(.bbBody)
            .padding(.horizontal, 18)
            .padding(.vertical, 15)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: Radius.md))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.md)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
        }
    }
}
