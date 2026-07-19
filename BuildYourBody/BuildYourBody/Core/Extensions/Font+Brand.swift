import SwiftUI
import CoreText

/// Brand fonts. Files live in `Resources/Fonts/` and are bundled automatically by the
/// Xcode file-system-synchronized group. Because the app uses a generated Info.plist
/// (no physical plist for a `UIAppFonts` array), we register bundled fonts at launch
/// with Core Text instead — call `BrandFont.register()` from the App's `init`.
enum BrandFont {
    /// Filenames (without extension) of every bundled `.ttf` to register.
    /// `DMSans` is a variable font (weight + optical-size axes) — one file covers
    /// every weight via `Font.custom("DM Sans", …).weight(…)`.
    private static let bundled = [
        "DMSerifDisplay-Regular",
        "DMSans",
    ]

    static func register() {
        for name in bundled {
            guard let url = Bundle.main.url(forResource: name, withExtension: "ttf") else {
                #if DEBUG
                print("⚠️ BrandFont: \(name).ttf not found in bundle")
                #endif
                continue
            }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
        #if DEBUG && canImport(UIKit)
        // Confirm the brand families registered under the names Font.custom expects.
        for family in ["DM Serif Display", "DM Sans"] {
            if UIFont.familyNames.contains(family) {
                print("✅ BrandFont: '\(family)' registered")
            } else {
                print("⚠️ BrandFont: '\(family)' NOT found. DM* families: \(UIFont.familyNames.filter { $0.contains("DM") })")
            }
        }
        #endif
    }
}

extension Font {
    /// Display serif for headings + numerals. Uses bundled DM Serif Display; SwiftUI
    /// falls back to the system serif automatically if the family isn't registered.
    static func serifDisplay(_ size: CGFloat) -> Font {
        .custom("DM Serif Display", size: size)
    }

    /// Body sans — bundled DM Sans (variable). SwiftUI maps `.weight` onto the font's
    /// weight axis; it falls back to the system sans automatically if unregistered.
    static func sans(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom("DM Sans", size: size).weight(weight)
    }
}

// MARK: - Semantic type scale
//
// `serifDisplay` / `sans` above are the primitives (explicit size). These named roles
// are the shared vocabulary — reach for a role first (`.font(.bbTitle)`) and drop to a
// primitive only when a one-off size is genuinely needed. Serif carries headings +
// numerals (the brand's display voice); sans carries everything readable.
extension Font {
    // Serif display (DM Serif Display) — headings & big numerals
    static let bbDisplayXL  = serifDisplay(64)   // hero numerals (ring totals)
    static let bbDisplay    = serifDisplay(44)   // feature numerals
    static let bbLargeTitle = serifDisplay(34)   // screen titles ("Today")
    static let bbTitle      = serifDisplay(28)   // section / sheet titles
    static let bbTitle2     = serifDisplay(22)   // card headline numerals
    static let bbTitle3     = serifDisplay(18)   // small serif accents

    // Sans (DM Sans) — labels & body
    static let bbHeadline   = sans(16, weight: .semibold) // card titles, buttons
    static let bbBody       = sans(15)                     // default body
    static let bbCallout    = sans(14)                     // secondary body
    static let bbSubhead    = sans(13, weight: .semibold) // field / group labels
    static let bbCaption    = sans(12)                     // captions, metadata
    static let bbCaption2   = sans(11)                     // smallest legible text
    static let bbEyebrow    = sans(12, weight: .bold)     // tracked kickers (pair with .kerning)
}
