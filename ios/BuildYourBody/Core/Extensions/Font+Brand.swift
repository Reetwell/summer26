import SwiftUI

extension Font {
    static func serifDisplay(_ size: CGFloat) -> Font {
        .custom("DMSerifDisplay-Regular", size: size)
    }

    static func sans(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom("DMSans-Regular", size: size).weight(weight)
    }
}
