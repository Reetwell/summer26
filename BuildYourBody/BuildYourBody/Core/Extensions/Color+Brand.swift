import SwiftUI

extension Color {
    static let green500 = Color(hex: "#1D9E75")
    static let green700 = Color(hex: "#0F6E56")
    static let green900 = Color(hex: "#085041")
    static let green50  = Color(hex: "#E8F7F2")
    static let cream    = Color(hex: "#F9F6F0")

    // Cream in light mode, near-black in dark — matches the web app
    static let bbBackground = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.055, green: 0.055, blue: 0.055, alpha: 1)
            : UIColor(red: 0.976, green: 0.965, blue: 0.941, alpha: 1)
    })

    // Card surface: white in light, elevated dark gray in dark
    static let bbSurface = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.11, green: 0.11, blue: 0.115, alpha: 1)
            : UIColor.white
    })

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
