import SwiftUI

struct LeagueView: View {
    var isPresented: Binding<Bool>? = nil

    private let tier: RankTier = .bronze   // fresh install — everyone starts here

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.md) {
                // Hero
                VStack(spacing: Spacing.sm) {
                    RankBadge(tier: tier, size: 76)
                    Text("\(tier.name) League")
                        .font(.serifDisplay(30))
                        .foregroundStyle(.white)
                    leagueChip("Not started yet", icon: "clock")
                }
                .padding(.vertical, Spacing.lg)
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(colors: [Color.green700, Color.green900],
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: RoundedRectangle(cornerRadius: Radius.lg)
                )

                Text("Ranked by effort — sessions, streak days and goals hit. Not weight or strength, so it's fair for everyone.")
                    .font(.sans(12))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.sm)

                // Empty state — no league until you start training
                BBCard {
                    VStack(spacing: Spacing.md) {
                        Image(systemName: "trophy")
                            .font(.system(size: 34))
                            .foregroundStyle(Color.green500)
                            .frame(width: 72, height: 72)
                            .background(Color.green500.opacity(0.1), in: Circle())

                        VStack(spacing: 6) {
                            Text("Your first league starts soon")
                                .font(.serifDisplay(20))
                                .multilineTextAlignment(.center)
                            Text("Log your first session and you'll be matched with others training at the same pace. Climb the ranks by showing up — every week is a fresh start.")
                                .font(.sans(13))
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
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
