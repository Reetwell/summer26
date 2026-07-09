import SwiftUI

// MARK: - Model (sample data — real XP/matchmaking lives in backend/app.js later)

enum RankTier: Int, CaseIterable, Identifiable {
    case bronze, silver, gold, platinum, diamond
    var id: Int { rawValue }

    var name: String {
        switch self {
        case .bronze: "Bronze"; case .silver: "Silver"; case .gold: "Gold"
        case .platinum: "Platinum"; case .diamond: "Diamond"
        }
    }
    var colors: [Color] {
        switch self {
        case .bronze:   [Color(hex: "#D69A5C"), Color(hex: "#8A5A2B")]
        case .silver:   [Color(hex: "#DEE4EA"), Color(hex: "#98A2AD")]
        case .gold:     [Color(hex: "#F5CB55"), Color(hex: "#C9922A")]
        case .platinum: [Color(hex: "#9AE7D6"), Color(hex: "#3FA894")]
        case .diamond:  [Color(hex: "#9AD4FF"), Color(hex: "#4A90D9")]
        }
    }
    var accent: Color { colors[0] }
    var next: RankTier? { RankTier(rawValue: rawValue + 1) }
}

struct RankState {
    var tier: RankTier
    var xp: Int
    var xpForNext: Int
    var level: Int
    var progress: Double { min(Double(xp) / Double(xpForNext), 1) }

    static let sample = RankState(tier: .gold, xp: 2450, xpForNext: 3000, level: 12)
}

// MARK: - Hexagon badge

struct Hexagon: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        let pts = [
            CGPoint(x: w * 0.5, y: 0),
            CGPoint(x: w, y: h * 0.26),
            CGPoint(x: w, y: h * 0.74),
            CGPoint(x: w * 0.5, y: h),
            CGPoint(x: 0, y: h * 0.74),
            CGPoint(x: 0, y: h * 0.26)
        ]
        var p = Path()
        p.move(to: pts[0])
        pts.dropFirst().forEach { p.addLine(to: $0) }
        p.closeSubpath()
        return p
    }
}

struct RankBadge: View {
    let tier: RankTier
    var size: CGFloat = 64

    var body: some View {
        Hexagon()
            .fill(LinearGradient(colors: tier.colors, startPoint: .top, endPoint: .bottom))
            .overlay(Hexagon().stroke(.white.opacity(0.55), lineWidth: max(size * 0.03, 1)))
            .overlay(
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: size * 0.3, weight: .bold))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
            )
            .frame(width: size, height: size * 1.08)
            .shadow(color: tier.accent.opacity(0.45), radius: size * 0.14, y: 3)
    }
}

// MARK: - Rank card (profile / dashboard)

struct RankCard: View {
    let rank: RankState
    var compact: Bool = false
    var onTapLeague: () -> Void = {}

    var body: some View {
        Button(action: onTapLeague) {
            HStack(spacing: Spacing.md) {
                RankBadge(tier: rank.tier, size: compact ? 52 : 64)

                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 8) {
                        Text(rank.tier.name)
                            .font(.serifDisplay(compact ? 20 : 24))
                        Text("LEVEL \(rank.level)")
                            .font(.sans(10, weight: .bold))
                            .kerning(1)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(Color.secondary.opacity(0.1), in: Capsule())
                    }
                    // XP progress
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(rank.tier.accent.opacity(0.16))
                            Capsule()
                                .fill(LinearGradient(colors: rank.tier.colors, startPoint: .leading, endPoint: .trailing))
                                .frame(width: geo.size.width * rank.progress)
                        }
                    }
                    .frame(height: 7)
                    Text(nextLine)
                        .font(.sans(11))
                        .foregroundStyle(.secondary)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(Spacing.md)
            .background(Color.bbSurface, in: RoundedRectangle(cornerRadius: Radius.lg))
            .shadow(color: .black.opacity(0.05), radius: 12, y: 4)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private var nextLine: String {
        if let next = rank.tier.next {
            return "\(rank.xp) / \(rank.xpForNext) XP to \(next.name)"
        }
        return "\(rank.xp) XP · top tier"
    }
}
