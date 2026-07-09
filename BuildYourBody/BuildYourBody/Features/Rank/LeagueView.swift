import SwiftUI

struct LeaguePlayer: Identifiable {
    let id = UUID()
    let name: String
    let points: Int
    let isYou: Bool
}

struct LeagueView: View {
    var isPresented: Binding<Bool>? = nil

    private let tier: RankTier = .gold
    private let daysLeft = 2
    private let promoteCount = 5
    private let relegateCount = 5

    // Sample matchmade group (anonymous — effort-based points, not body/strength)
    private let players: [LeaguePlayer] = [
        .init(name: "IronWolf", points: 940, isYou: false),
        .init(name: "Mia_lifts", points: 880, isYou: false),
        .init(name: "quietbeast", points: 820, isYou: false),
        .init(name: "Reece", points: 780, isYou: true),
        .init(name: "no_days_off", points: 760, isYou: false),
        .init(name: "sunrise6am", points: 720, isYou: false),
        .init(name: "leg_day_lily", points: 690, isYou: false),
        .init(name: "T_bar_tom", points: 640, isYou: false),
        .init(name: "protein.pete", points: 600, isYou: false),
        .init(name: "gymrat22", points: 560, isYou: false),
        .init(name: "slow_gains", points: 500, isYou: false),
        .init(name: "kayo", points: 420, isYou: false),
        .init(name: "restday_ray", points: 300, isYou: false),
        .init(name: "maybe_tomorrow", points: 180, isYou: false),
        .init(name: "newphone_whodis", points: 90, isYou: false)
    ]

    private var ranked: [LeaguePlayer] { players.sorted { $0.points > $1.points } }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.md) {
                // Hero
                VStack(spacing: Spacing.sm) {
                    RankBadge(tier: tier, size: 76)
                    Text("\(tier.name) League")
                        .font(.serifDisplay(30))
                        .foregroundStyle(.white)
                    HStack(spacing: 8) {
                        leagueChip("Top \(promoteCount) promote", icon: "arrow.up")
                        leagueChip("\(daysLeft) days left", icon: "clock")
                    }
                }
                .padding(.vertical, Spacing.lg)
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(colors: [Color.green700, Color.green900],
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: RoundedRectangle(cornerRadius: Radius.lg)
                )

                Text("Ranked by effort this week — sessions, streak days and goals hit. Not weight or strength, so it's fair for everyone.")
                    .font(.sans(12))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.sm)

                // Standings
                BBCard(padding: Spacing.xs) {
                    VStack(spacing: 0) {
                        ForEach(Array(ranked.enumerated()), id: \.element.id) { i, p in
                            playerRow(position: i + 1, player: p)
                            if i < ranked.count - 1 {
                                Divider().padding(.leading, 54)
                            }
                            // Promotion / relegation divider lines
                            if i + 1 == promoteCount {
                                zoneLabel("PROMOTION ZONE ▲", color: Color.green500)
                            } else if i + 1 == ranked.count - relegateCount {
                                zoneLabel("RELEGATION ZONE ▼", color: Color(hex: "#E8564A"))
                            }
                        }
                    }
                }
            }
            .padding(Spacing.md)
            .padding(.bottom, Spacing.xl)
            .readableWidth(560)
        }
        .background(Color.bbBackground)
        .overlay(alignment: .topTrailing) {
            if let isPresented {
                Button { isPresented.wrappedValue = false } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.secondary)
                        .padding(11)
                        .background(.regularMaterial, in: Circle())
                }
                .buttonStyle(.plain)
                .padding(Spacing.md)
            }
        }
        #if os(macOS)
        .frame(minWidth: 520, minHeight: 680)
        #endif
    }

    private func playerRow(position: Int, player: LeaguePlayer) -> some View {
        HStack(spacing: Spacing.md) {
            Text("\(position)")
                .font(.sans(14, weight: .bold))
                .foregroundStyle(position <= promoteCount ? Color.green500 : .secondary)
                .frame(width: 26, alignment: .center)
            Text(String(player.name.prefix(2)).uppercased())
                .font(.sans(12, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(player.isYou ? AnyShapeStyle(LinearGradient(colors: [.green500, .green900], startPoint: .topLeading, endPoint: .bottomTrailing)) : AnyShapeStyle(Color.secondary.opacity(0.5)), in: Circle())
            Text(player.isYou ? "You" : player.name)
                .font(.sans(15, weight: player.isYou ? .bold : .regular))
                .foregroundStyle(player.isYou ? Color.green700 : .primary)
            Spacer()
            Text("\(player.points)")
                .font(.sans(15, weight: .semibold))
            Text("XP").font(.sans(11)).foregroundStyle(.secondary)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, 10)
        .background(player.isYou ? Color.green500.opacity(0.08) : .clear)
    }

    private func zoneLabel(_ text: String, color: Color) -> some View {
        HStack {
            Rectangle().fill(color.opacity(0.3)).frame(height: 1)
            Text(text).font(.sans(9, weight: .bold)).kerning(1).foregroundStyle(color)
            Rectangle().fill(color.opacity(0.3)).frame(height: 1)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, 6)
    }

    private func leagueChip(_ text: String, icon: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon).font(.system(size: 11))
            Text(text).font(.sans(12, weight: .semibold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 12).padding(.vertical, 7)
        .background(.white.opacity(0.16), in: Capsule())
    }
}
