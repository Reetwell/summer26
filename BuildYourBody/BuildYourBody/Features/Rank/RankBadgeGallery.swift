import SwiftUI

#if DEBUG
/// Design QA surface for the rank badge: every tier crossed with every division,
/// plus the two celebration beats and the small-size fallback.
///
/// Not reachable from the product UI. Launch it with:
///     xcrun simctl launch <udid> com.brian.BuildYourBody -BBRankGallery YES
struct RankBadgeGallery: View {
    @State private var demoTier: RankTier = .gold
    @State private var demoDivision = 1
    @State private var beat: RankCelebration?

    private let autoplay = UserDefaults.standard.bool(forKey: "BBRankGalleryAutoplay")

    var body: some View {
        Group {
            if autoplay {
                AutoplayStage()
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        grid
                        smallSizes
                        celebration
                    }
                    .padding(Spacing.md)
                }
            }
        }
        .background(Color.bbBackground)
    }

    // MARK: 5 tiers × 3 divisions

    private var grid: some View {
        VStack(alignment: .leading, spacing: 10) {
            heading("Five tiers, three divisions")
            HStack(spacing: 0) {
                Text("").frame(width: 62)
                ForEach(1...3, id: \.self) { d in
                    Text("division \(d)")
                        .font(.sans(10, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            ForEach(RankTier.allCases) { tier in
                HStack(spacing: 0) {
                    Text(tier.name)
                        .font(.sans(11, weight: .bold))
                        .frame(width: 62, alignment: .leading)
                    ForEach(1...3, id: \.self) { d in
                        RankBadge(tier: tier, division: d, size: 56)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }

    // MARK: legibility at the smallest sizes the badge is actually used at

    private var smallSizes: some View {
        VStack(alignment: .leading, spacing: 10) {
            heading("Small sizes — 52pt is the smallest in the app")
            HStack(alignment: .bottom, spacing: 20) {
                ForEach([CGFloat(52), 44, 34, 26], id: \.self) { s in
                    VStack(spacing: 6) {
                        RankBadge(tier: .gold, division: 2, size: s)
                        Text("\(Int(s))pt")
                            .font(.sans(9)).foregroundStyle(.secondary)
                    }
                }
            }
            Text("At 52pt and 44pt the pips are chevrons. Below 44pt they become dots, because a chevron's waist falls under a pixel and would smear into a blur.")
                .font(.sans(11))
                .foregroundStyle(.secondary)
        }
    }

    // MARK: the two beats

    private var celebration: some View {
        VStack(alignment: .leading, spacing: 10) {
            heading("The two beats")
            HStack(spacing: Spacing.lg) {
                RankBadge(tier: demoTier, division: demoDivision, size: 76, celebrate: beat)
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(demoTier.name), division \(demoDivision) of 3")
                        .font(.sans(12, weight: .semibold))
                    Button("Light a pip") { lightPip() }
                        .buttonStyle(.borderedProminent)
                    Button("Promote") { promote() }
                        .buttonStyle(.bordered)
                    Button("Reset") { demoTier = .bronze; demoDivision = 1; beat = nil }
                        .buttonStyle(.plain)
                        .font(.sans(11))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // A pip only ever goes up; at the top of a tier the next step is a promotion.
    private func lightPip() {
        guard demoDivision < Rank.divisionsPerTier else { promote(); return }
        demoDivision += 1
        beat = nil
        DispatchQueue.main.async { beat = .pipLit(demoDivision) }
    }

    private func promote() {
        guard let next = demoTier.next else { return }
        demoTier = next
        demoDivision = 1
        beat = nil
        DispatchQueue.main.async { beat = .promoted }
    }

    private func heading(_ s: String) -> some View {
        Text(s).font(.serifDisplay(19))
    }
}

/// Fires the two beats on a fixed timeline so a screenshot can be taken mid-flight
/// without anyone tapping. `-BBRankGalleryAutoplay YES`.
private struct AutoplayStage: View {
    @State private var tier: RankTier = .gold
    @State private var division = 2
    @State private var beat: RankCelebration?
    @State private var caption = "at rest"

    var body: some View {
        VStack(spacing: Spacing.lg) {
            RankBadge(tier: tier, division: division, size: 150, celebrate: beat)
            Text(caption).font(.sans(15, weight: .semibold))
            Text("\(tier.name), division \(division) of 3")
                .font(.sans(12)).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear(perform: run)
    }

    private func run() {
        // t+1.0s — the smaller beat: a third pip lights.
        after(1.0) { division = 3; caption = "pip lit"; beat = .pipLit(3) }
        // t+3.0s — the moment: new metal, numeral changes, pips reset to one.
        after(3.0) { tier = .platinum; division = 1; caption = "promoted"; beat = .promoted }
    }

    private func after(_ t: Double, _ work: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + t, execute: work)
    }
}
#endif
