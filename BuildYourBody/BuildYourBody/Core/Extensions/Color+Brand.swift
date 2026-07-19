import SwiftUI

extension Color {
    // Brand green ramp — migrated to #00694c (matches web styles.css + rank effort-gem).
    // The older brighter #1D9E75 survives only as the rank gem's top-facet glint.
    static let green500 = Color(hex: "#00694c")
    static let green700 = Color(hex: "#00543D")
    static let green900 = Color(hex: "#003F2E")
    static let green50  = Color(hex: "#E0EDEA")
    static let cream    = Color(hex: "#F9F6F0")

    // MARK: Semantic accents
    // Prefer these role names over the raw `green*` ramp at call sites, so intent is
    // legible and a future palette change lands in one place. `bbBackground`/`bbSurface`
    // (below) cover the adaptive light/dark surfaces.
    static let bbAccent     = green500   // primary interactive / brand
    static let bbAccentDeep = green900   // pressed / gradient end / text on tint
    static let bbTint       = green50    // subtle brand fills, chips, tracks

    // Cream in light mode, near-black in dark — matches the web app
    #if os(iOS)
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
    #else
    static let bbBackground = Color(nsColor: NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(red: 0.055, green: 0.055, blue: 0.055, alpha: 1)
            : NSColor(red: 0.976, green: 0.965, blue: 0.941, alpha: 1)
    })

    static let bbSurface = Color(nsColor: NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(red: 0.11, green: 0.11, blue: 0.115, alpha: 1)
            : NSColor.white
    })
    #endif

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
