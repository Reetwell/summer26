import SwiftUI

extension Color {
    static let green500 = Color(hex: "#1D9E75")
    static let green700 = Color(hex: "#0F6E56")
    static let green900 = Color(hex: "#085041")
    static let green50  = Color(hex: "#E8F7F2")
    static let cream    = Color(hex: "#F9F6F0")
    static let bbBackground = Color(hex: "#F9F6F0")

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8)  & 0xFF) / 255
        let b = Double(int & 0xFF)          / 255
        self.init(red: r, green: g, blue: b)
    }
}
