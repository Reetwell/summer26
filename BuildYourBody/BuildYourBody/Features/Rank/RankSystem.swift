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
    // Two-stop ramp used by XP bars / tints elsewhere. Diamond is amethyst.
    var colors: [Color] {
        switch self {
        case .bronze:   [Color(hex: "#D69A5C"), Color(hex: "#8A5A2B")]
        case .silver:   [Color(hex: "#DEE4EA"), Color(hex: "#98A2AD")]
        case .gold:     [Color(hex: "#F5CB55"), Color(hex: "#C9922A")]
        case .platinum: [Color(hex: "#9AE7D6"), Color(hex: "#3FA894")]
        case .diamond:  [Color(hex: "#A98FD6"), Color(hex: "#523A85")]
        }
    }
    var accent: Color { colors[0] }
    var next: RankTier? { RankTier(rawValue: rawValue + 1) }

    // Full metal palette for the crafted banner badge (ported from the design mockup).
    var palette: TierPalette {
        switch self {
        case .bronze:   TierPalette(from: "#D69A5C", shn: "#EDBE8A", to: "#8A5A2B", deep: "#5E3A17", lite: "#F0C79A", ink: 0.45)
        case .silver:   TierPalette(from: "#DEE4EA", shn: "#F6F9FC", to: "#98A2AD", deep: "#4F5963", lite: "#FFFFFF", ink: 0.82)
        case .gold:     TierPalette(from: "#F5CB55", shn: "#FFE594", to: "#C9922A", deep: "#8F6212", lite: "#FFE9A8", ink: 0.50)
        case .platinum: TierPalette(from: "#9AE7D6", shn: "#C6F5EA", to: "#3FA894", deep: "#256B5E", lite: "#EAFFF9", ink: 0.60)
        case .diamond:  TierPalette(from: "#E7DBFF", shn: "#F5EFFF", to: "#A98FD6", deep: "#523A85", lite: "#F1E9FF", ink: 0.55)
        }
    }
    var numeral: String { ["I", "II", "III", "IV", "V"][rawValue] }   // tier order, not division
    var isFramed: Bool { rawValue >= RankTier.platinum.rawValue }     // laurel on top two
    var laurelFull: CGFloat { self == .diamond ? 1.0 : 0.66 }         // Diamond fuller wreath
}

// Resolved metal stops for one tier.
struct TierPalette {
    let from, shn, to, deep, lite: Color
    let ink: Double
    init(from: String, shn: String, to: String, deep: String, lite: String, ink: Double) {
        self.from = Color(hex: from); self.shn = Color(hex: shn); self.to = Color(hex: to)
        self.deep = Color(hex: deep); self.lite = Color(hex: lite); self.ink = ink
    }
}

// Brand effort-gem (the #00694c migration ramp; bright green survives as the top-facet glint).
enum GemColor {
    static let core  = Color(hex: "#00694c")
    static let deep  = Color(hex: "#003F2E")
    static let glint = Color(hex: "#1D9E75")
}

struct RankState {
    var tier: RankTier
    var xp: Int
    var xpForNext: Int
    var level: Int
    var progress: Double { min(Double(xp) / Double(xpForNext), 1) }

    static let sample = RankState(tier: .gold, xp: 2450, xpForNext: 3000, level: 12)
    // Fresh install — everyone starts at the bottom, 0 XP.
    static let fresh = RankState(tier: .bronze, xp: 0, xpForNext: 500, level: 1)
}

// MARK: - Banner badge (crafted swallowtail, Canvas-rendered)
//
// Ported 1:1 from the design mockup's 120×166 SVG. The banner hangs from a clasp
// that gains detail per tier (plain → beveled → capped → engraved → gem-finials);
// the top two tiers earn a laurel; Diamond is amethyst. Legible from splash size
// down to ~20pt.

private let BADGE_ASPECT: CGFloat = 166.0 / 120.0

struct RankBadge: View {
    let tier: RankTier
    var size: CGFloat = 64

    var body: some View {
        Canvas { ctx, cs in drawRankBadge(&ctx, cs, tier: tier) }
            .frame(width: size, height: size * BADGE_ASPECT)
            .shadow(color: tier.accent.opacity(0.40), radius: size * 0.12, y: 3)
            .accessibilityLabel("\(tier.name) rank")
    }
}

// The whole badge, drawn back-to-front in the 120×166 design space.
private func drawRankBadge(_ ctx: inout GraphicsContext, _ cs: CGSize, tier: RankTier) {
    let W = cs.width, H = cs.height, s = W / 120
    let pal = tier.palette

    // --- coordinate + primitive helpers (design units → canvas points) ---
    func mp(_ x: CGFloat, _ y: CGFloat, _ dy: CGFloat) -> CGPoint {
        CGPoint(x: x / 120 * W, y: (y + dy) / 166 * H)
    }
    func poly(_ pts: [(CGFloat, CGFloat)], _ dy: CGFloat) -> Path {
        var p = Path()
        for (i, q) in pts.enumerated() {
            let c = mp(q.0, q.1, dy)
            if i == 0 { p.move(to: c) } else { p.addLine(to: c) }
        }
        p.closeSubpath(); return p
    }
    func rr(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ r: CGFloat, _ dy: CGFloat) -> Path {
        Path(roundedRect: CGRect(x: x / 120 * W, y: (y + dy) / 166 * H, width: w / 120 * W, height: h / 166 * H),
             cornerRadius: r * s)
    }
    func line(_ x0: CGFloat, _ y0: CGFloat, _ x1: CGFloat, _ y1: CGFloat, _ dy: CGFloat) -> Path {
        var p = Path(); p.move(to: mp(x0, y0, dy)); p.addLine(to: mp(x1, y1, dy)); return p
    }
    func circ(_ cx: CGFloat, _ cy: CGFloat, _ rad: CGFloat, _ dy: CGFloat) -> Path {
        let c = mp(cx, cy, dy), r = rad * s
        return Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2))
    }
    func vg(_ colors: [Color], _ x: CGFloat, _ y0: CGFloat, _ y1: CGFloat, _ dy: CGFloat) -> GraphicsContext.Shading {
        .linearGradient(Gradient(colors: colors), startPoint: mp(x, y0, dy), endPoint: mp(x, y1, dy))
    }
    func col(_ c: Color, _ o: Double) -> GraphicsContext.Shading { .color(c.opacity(o)) }
    func black(_ o: Double) -> GraphicsContext.Shading { .color(.black.opacity(o)) }
    func white(_ o: Double) -> GraphicsContext.Shading { .color(.white.opacity(o)) }

    // ============ 1. Laurel (behind, top two tiers) ============
    if tier.isFramed {
        let full = tier.laurelFull
        let N = Int((7 * full).rounded()) + 3
        let leafShade: GraphicsContext.Shading = vg([pal.shn, pal.to], 0, 60, 150, 0)
        func branch(_ mirror: Bool) {
            let P0 = (CGFloat(42), CGFloat(150)), P1 = (CGFloat(8), CGFloat(124)), P2 = (CGFloat(18), 150 - 96 * full)
            func mx(_ x: CGFloat) -> CGFloat { mirror ? 120 - x : x }
            // stem
            var stem = Path()
            stem.move(to: mp(mx(P0.0), P0.1, 0))
            stem.addQuadCurve(to: mp(mx(P2.0), P2.1, 0), control: mp(mx(P1.0), P1.1, 0))
            ctx.stroke(stem, with: col(pal.deep, 0.42), lineWidth: 1.3 * s)
            // leaves along the arc
            for i in 1...N {
                let u = CGFloat(i) / (CGFloat(N) + 0.4), v = 1 - u
                let x = v * v * P0.0 + 2 * v * u * P1.0 + u * u * P2.0
                let y = v * v * P0.1 + 2 * v * u * P1.1 + u * u * P2.1
                let dx = 2 * v * (P1.0 - P0.0) + 2 * u * (P2.0 - P1.0)
                let dy = 2 * v * (P1.1 - P0.1) + 2 * u * (P2.1 - P1.1)
                let aL = atan2(dy, dx) + .pi / 2 + 20 * .pi / 180
                let ang = mirror ? -aL : aL
                let len = 12.5 * (1 - 0.4 * u) * s, wid = 4.4 * (1 - 0.26 * u) * s
                var leafP = Path()
                leafP.move(to: .zero)
                leafP.addQuadCurve(to: CGPoint(x: 0, y: -len), control: CGPoint(x: wid, y: -len * 0.55))
                leafP.addQuadCurve(to: .zero, control: CGPoint(x: -wid, y: -len * 0.55))
                leafP.closeSubpath()
                var vein = Path()
                vein.move(to: CGPoint(x: 0, y: -len * 0.14)); vein.addLine(to: CGPoint(x: 0, y: -len * 0.88))
                let tf = CGAffineTransform(translationX: mp(mx(x), y, 0).x, y: mp(mx(x), y, 0).y).rotated(by: ang)
                ctx.fill(leafP.applying(tf), with: leafShade)
                ctx.stroke(leafP.applying(tf), with: col(pal.deep, 0.32), lineWidth: 0.5 * s)
                ctx.stroke(vein.applying(tf), with: col(pal.deep, 0.30), lineWidth: 0.5 * s)
            }
        }
        branch(false); branch(true)
        // base tie
        for (cx, cy, r) in [(CGFloat(60), CGFloat(149.5), CGFloat(2.5)), (55.6, 151.4, 1.8), (64.4, 151.4, 1.8)] {
            ctx.fill(circ(cx, cy, r, 0), with: leafShade)
            ctx.stroke(circ(cx, cy, r, 0), with: col(pal.deep, 0.35), lineWidth: 0.5 * s)
        }
    }

    // ============ 2. Hangers (bar → banner) ============
    for hx in [CGFloat(38), 77.4] {
        ctx.fill(rr(hx, 13, 4.6, 15, 1.6, 0), with: vg([pal.to, pal.deep], hx, 13, 28, 0))
        ctx.stroke(rr(hx, 13, 4.6, 15, 1.6, 0), with: col(pal.deep, 0.5), lineWidth: 0.6 * s)
    }

    // ============ 3. Banner (group is +16 in y) ============
    let dy: CGFloat = 16
    // rim + bevels
    ctx.fill(poly([(24,10),(96,10),(96,140),(60,114),(24,140)], dy), with: vg([pal.to, pal.deep], 60, 10, 140, dy))
    ctx.stroke(poly([(24,10),(96,10),(96,140),(60,114),(24,140)], dy), with: col(pal.deep, 1), lineWidth: 2 * s)
    ctx.fill(poly([(24,10),(96,10),(90,16),(30,16)], dy), with: col(pal.lite, 0.5))
    ctx.fill(poly([(24,10),(30,16),(30,131),(24,140)], dy), with: white(0.22))
    ctx.fill(poly([(96,10),(96,140),(90,131),(90,16)], dy), with: black(0.24))
    ctx.fill(poly([(24,140),(30,131),(60,105),(60,114)], dy), with: black(0.10))
    ctx.fill(poly([(96,140),(90,131),(60,105),(60,114)], dy), with: black(0.30))
    // face
    let facePts: [(CGFloat, CGFloat)] = [(30,16),(90,16),(90,131),(60,105),(30,131)]
    let faceShade: GraphicsContext.Shading = .linearGradient(
        Gradient(stops: [.init(color: pal.from, location: 0), .init(color: pal.shn, location: 0.42), .init(color: pal.to, location: 1)]),
        startPoint: mp(60, 16, dy), endPoint: mp(60, 131, dy))
    ctx.fill(poly(facePts, dy), with: faceShade)
    ctx.fill(poly([(30,16),(60,16),(60,105),(30,131)], dy), with: white(0.05))
    ctx.fill(poly([(60,16),(90,16),(90,131),(60,105)], dy), with: black(0.06))
    // directional sheen (clipped to the face)
    do {
        var c2 = ctx; c2.clip(to: poly(facePts, dy))
        c2.fill(poly([(30,16),(55,16),(41,131),(30,131)], dy), with: white(0.07))
        c2.fill(poly([(90,16),(79,16),(87,131),(90,131)], dy), with: black(0.05))
        // Diamond iridescence
        if tier == .diamond {
            let irid: GraphicsContext.Shading = .linearGradient(
                Gradient(stops: [.init(color: Color(hex: "#C9A0FF").opacity(0.42), location: 0),
                                 .init(color: .white.opacity(0), location: 0.5),
                                 .init(color: Color(hex: "#FF9ED8").opacity(0.36), location: 1)]),
                startPoint: mp(30, 16, dy), endPoint: mp(90, 131, dy))
            c2.fill(poly(facePts, dy), with: irid)
        }
    }
    // hem fold + highlight + specular
    ctx.fill(rr(30, 16, 60, 20, 0, dy), with: vg([pal.to, pal.deep], 60, 16, 36, dy))
    ctx.stroke(line(30, 17.2, 90, 17.2, dy), with: col(pal.lite, 0.55), lineWidth: 1.6 * s)
    ctx.fill(rr(30, 36, 60, 8, 0, dy), with: .linearGradient(
        Gradient(stops: [.init(color: .black.opacity(0.22), location: 0), .init(color: .black.opacity(0), location: 1)]),
        startPoint: mp(60, 36, dy), endPoint: mp(60, 44, dy)))
    // engraved keyline (dark + light)
    ctx.stroke(poly([(34,41),(86,41),(86,126),(60,99.5),(34,126)], dy), with: black(0.16), lineWidth: 1 * s)
    ctx.stroke(poly([(34,42.2),(86,42.2),(86,127.2),(60,100.7),(34,127.2)], dy), with: white(0.14), lineWidth: 1 * s)
    // per-tier streak
    if tier != .bronze {
        let streakO: Double = [.silver: 0.10, .gold: 0.13, .platinum: 0.15, .diamond: 0.18][tier] ?? 0
        ctx.fill(poly([(32,56),(54,46),(90,66),(68,76)], dy), with: white(streakO))
    }
    // per-tier extra
    switch tier {
    case .silver:
        ctx.stroke(line(34, 58, 86, 58, dy), with: white(0.13), lineWidth: 1.3 * s)
        ctx.stroke(line(34, 90, 86, 90, dy), with: white(0.09), lineWidth: 1.1 * s)
    case .gold, .diamond:
        ctx.stroke(poly([(34,41),(86,41),(86,126),(60,99.5),(34,126)], dy), with: col(pal.lite, 0.5), lineWidth: 1.5 * s)
    case .platinum:
        ctx.stroke(poly([(34,41),(86,41),(86,126),(60,99.5),(34,126)], dy), with: col(pal.lite, 0.45), lineWidth: 1.5 * s)
        ctx.stroke(line(37, 52, 42, 49.4, dy), with: col(pal.lite, 0.55), lineWidth: 1.3 * s)
        ctx.stroke(line(83, 50, 78, 47.4, dy), with: col(pal.lite, 0.55), lineWidth: 1.3 * s)
    default: break
    }
    // recessed numeral cartouche
    ctx.fill(rr(39, 49, 42, 43, 6, dy), with: black(0.06))
    ctx.stroke(line(42, 50.3, 78, 50.3, dy), with: black(0.10), lineWidth: 1.3 * s)
    ctx.stroke(rr(39, 49, 42, 43, 6, dy), with: black(0.14), lineWidth: 1 * s)
    ctx.stroke(rr(40, 50, 40, 41, 5, dy), with: col(pal.lite, 0.26), lineWidth: 1 * s)
    // numeral (engraved: dark shadow + light face)
    ctx.draw(Text(tier.numeral).font(.serifDisplay(44 * s)).foregroundColor(pal.deep.opacity(pal.ink)),
             at: mp(60, 71.2, dy), anchor: .center)
    ctx.draw(Text(tier.numeral).font(.serifDisplay(44 * s)).foregroundColor(Color(hex: "#F4F4F0")),
             at: mp(60, 70.4, dy), anchor: .center)
    // effort gem
    ctx.fill(poly([(60,96.6),(63.9,100.8),(60,105.0),(56.1,100.8)], dy), with: black(0.28))
    ctx.fill(poly([(60,95.7),(63.9,99.9),(60,104.1),(56.1,99.9)], dy), with: .color(GemColor.core))
    ctx.stroke(poly([(60,95.7),(63.9,99.9),(60,104.1),(56.1,99.9)], dy), with: .color(GemColor.deep), lineWidth: 0.8 * s)
    ctx.fill(poly([(60,95.7),(63.9,99.9),(56.1,99.9)], dy), with: .color(GemColor.glint))
    ctx.fill(circ(58.9, 98.4, 0.8, dy), with: white(0.85))

    // ============ 4. Clasp (escalates with tier) ============
    let L = tier.rawValue
    if L >= 2 {   // decorative end-caps
        for cx in [CGFloat(15), 93] {
            ctx.fill(rr(cx, 1.5, 12, 16, 3, 0), with: vg([pal.to, pal.deep], cx + 6, 1.5, 17.5, 0))
            ctx.stroke(rr(cx, 1.5, 12, 16, 3, 0), with: col(pal.deep, 1), lineWidth: 1.3 * s)
            ctx.fill(rr(cx + 1.5, 2.8, 9, 2.4, 1.2, 0), with: col(pal.lite, 0.5))
        }
    }
    ctx.fill(rr(22, 3, 76, 13, 3.5, 0), with: vg([pal.to, pal.deep], 60, 3, 16, 0))
    ctx.stroke(rr(22, 3, 76, 13, 3.5, 0), with: col(pal.deep, 1), lineWidth: 1.5 * s)
    ctx.fill(rr(24.5, 4.6, 71, 3, 1.5, 0), with: col(pal.lite, 0.5))
    ctx.fill(rr(24.5, 12.6, 71, 2.2, 1.1, 0), with: black(0.22))
    if L >= 1 {   // faceted / chamfered ends
        ctx.fill(poly([(22,3),(30,3),(26,9.5),(30,16),(22,16)], 0), with: black(0.12))
        ctx.fill(poly([(98,3),(90,3),(94,9.5),(90,16),(98,16)], 0), with: black(0.12))
        ctx.fill(poly([(22,3),(30,3),(26,9.5)], 0), with: col(pal.lite, 0.3))
        ctx.fill(poly([(98,3),(90,3),(94,9.5)], 0), with: col(pal.lite, 0.3))
    }
    if L >= 3 {   // engraved centre + ticks
        ctx.stroke(line(34, 9.5, 86, 9.5, 0), with: col(pal.deep, 0.4), lineWidth: 0.8 * s)
        ctx.stroke(line(34, 10.4, 86, 10.4, 0), with: col(pal.lite, 0.35), lineWidth: 0.6 * s)
        for tx in [CGFloat(52), 60, 68] { ctx.stroke(line(tx, 6, tx, 13, 0), with: col(pal.deep, 0.3), lineWidth: 0.7 * s) }
    }
    for cx in [CGFloat(34), 86] {   // studs
        ctx.fill(circ(cx, 9.7, 2.7, 0), with: black(0.25))
        ctx.fill(circ(cx, 9, 2.7, 0), with: .color(pal.deep))
        ctx.fill(circ(cx - 0.7, 8.3, 1.4, 0), with: col(pal.lite, 0.9))
    }
    if L >= 4 {   // gem-inlaid finials
        for cx in [CGFloat(21), 99] {
            ctx.fill(poly([(cx,6),(cx+3,9),(cx,12),(cx-3,9)], 0), with: .color(GemColor.core))
            ctx.stroke(poly([(cx,6),(cx+3,9),(cx,12),(cx-3,9)], 0), with: .color(GemColor.deep), lineWidth: 0.6 * s)
            ctx.fill(poly([(cx,6),(cx+3,9),(cx-3,9)], 0), with: .color(GemColor.glint))
        }
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
