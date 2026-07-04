import SwiftUI

extension Font {
    // System serif (New York) until DM Serif Display is bundled
    static func serifDisplay(_ size: CGFloat) -> Font {
        .system(size: size, weight: .regular, design: .serif)
    }

    static func sans(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight)
    }
}
