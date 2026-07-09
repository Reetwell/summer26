import SwiftUI

struct TodayView: View {
    private let todayStore = TodayStore.shared
    private let tsStore = TrainingStore.shared
    @State private var showJunkEntry = false
    @State private var junkText = ""
    @State private var showLeague = false
    private let rank = RankState.sample

    private var dateString: String {
        Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide))
    }

    var body: some View {
        #if os(macOS)
        macLayout
        #else
        iosLayout
        #endif
    }

    private var iosLayout: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.md) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text(dateString.uppercased())
                        .font(.sans(11, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .kerning(1.2)
                    HStack(alignment: .firstTextBaseline) {
                        Text("Today")
                            .font(.serifDisplay(34))
                        Spacer()
                        HStack(spacing: 5) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 13))
                            Text("6 day streak")
                                .font(.sans(13, weight: .semibold))
                        }
                        .foregroundStyle(Color.green500)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Color.green500.opacity(0.12), in: Capsule())
                    }
                }
                .slideIn()

                // Nutrition card — ring + macro bars
                BBCard {
                    VStack(spacing: Spacing.md) {
                        HStack {
                            Text("Nutrition")
                                .font(.sans(15, weight: .semibold))
                            Spacer()
                            Text("On track")
                                .font(.sans(12, weight: .semibold))
                                .foregroundStyle(Color.green500)
                        }

                        HStack(spacing: Spacing.lg) {
                            CalorieRingView(consumed: 1840, target: 2600)

                            VStack(spacing: Spacing.sm) {
                                MacroBarView(label: "Protein", value: 128, target: 160, color: .green500, delay: 0.35)
                                MacroBarView(label: "Carbs",   value: 210, target: 300, color: Color(hex: "#4A90D9"), delay: 0.45)
                                MacroBarView(label: "Fat",     value: 52,  target: 80,  color: Color(hex: "#E8A13A"), delay: 0.55)
                            }
                        }
                    }
                }
                .slideIn(delay: 0.06)

                // Rank + weekly league
                RankCard(rank: rank, compact: true) { showLeague = true }
                    .slideIn(delay: 0.09)

                // Readiness
                ReadinessBannerView()
                    .slideIn(delay: 0.12)

                // Today's training
                BBCard {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        HStack {
                            Text("Today's training")
                                .font(.sans(15, weight: .semibold))
                            Spacer()
                            Text("Push · Week 3")
                                .font(.sans(12))
                                .foregroundStyle(.secondary)
                        }

                        HStack(spacing: Spacing.md) {
                            Image(systemName: "dumbbell.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(Color.green500)
                                .frame(width: 44, height: 44)
                                .background(Color.green500.opacity(0.12), in: RoundedRectangle(cornerRadius: Radius.md))

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Push Day A")
                                    .font(.sans(16, weight: .semibold))
                                Text("6 exercises · ~55 min")
                                    .font(.sans(13))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }

                        BBButton(title: "Start workout") {}
                            .padding(.top, 4)
                    }
                }
                .slideIn(delay: 0.18)

                // Quick stats row — steps live from HealthKit, water from TodayStore
                HStack(spacing: Spacing.sm) {
                    #if os(iOS)
                    quickStat(icon: "figure.walk", value: stepsString, label: "steps")
                    #else
                    quickStat(icon: "figure.walk", value: "—", label: "steps")
                    #endif
                    quickStat(icon: "drop.fill", value: String(format: "%.1fL", todayStore.todayLog.water), label: "water")
                    quickStat(icon: "scalemass.fill", value: "74.2kg", label: "weight")
                }
                .slideIn(delay: 0.24)

                // Hydration logger
                BBCard {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        HStack {
                            Label("Water", systemImage: "drop.fill")
                                .font(.sans(15, weight: .semibold))
                                .foregroundStyle(Color(hex: "#4A90D9"))
                            Spacer()
                            Text(String(format: "%.1f / 3.0 L", todayStore.todayLog.water))
                                .font(.sans(13))
                                .foregroundStyle(.secondary)
                        }
                        HStack(spacing: Spacing.sm) {
                            ForEach([0.25, 0.5, 0.75, 1.0], id: \.self) { amt in
                                Button {
                                    todayStore.addWater(amt)
                                } label: {
                                    Text("+\(amt < 1 ? String(Int(amt * 1000)) + "ml" : "1L")")
                                        .font(.sans(13, weight: .semibold))
                                        .foregroundStyle(Color(hex: "#4A90D9"))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 9)
                                        .background(Color(hex: "#4A90D9").opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                                }
                                .buttonStyle(ScaleButtonStyle())
                            }
                        }
                    }
                }
                .slideIn(delay: 0.28)

                // Creatine + junk row
                HStack(spacing: Spacing.sm) {
                    // Creatine toggle
                    Button { todayStore.toggleCreatine() } label: {
                        BBCard(padding: Spacing.sm) {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Circle()
                                        .fill(todayStore.todayLog.creatine ? Color.green500 : Color.secondary.opacity(0.2))
                                        .frame(width: 10, height: 10)
                                    Spacer()
                                    if todayStore.todayLog.creatine {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 16))
                                            .foregroundStyle(Color.green500)
                                    }
                                }
                                Text("5g").font(.serifDisplay(18))
                                Text("creatine").font(.sans(11)).foregroundStyle(.secondary)
                            }
                        }
                    }
                    .buttonStyle(ScaleButtonStyle())

                    // Junk food log
                    BBCard(padding: Spacing.sm) {
                        VStack(alignment: .leading, spacing: 6) {
                            Image(systemName: "fork.knife")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "#E05C5C"))
                            Text("\(todayStore.todayLog.junk.count)").font(.serifDisplay(18))
                            HStack {
                                Text("junk").font(.sans(11)).foregroundStyle(.secondary)
                                Spacer()
                                Button {
                                    showJunkEntry = true
                                } label: {
                                    Image(systemName: "plus")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(Color(hex: "#E05C5C"))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .slideIn(delay: 0.30)
            }
            .padding(Spacing.md)
            .padding(.bottom, Spacing.xl)
            .readableWidth()
        }
        .background(Color.bbBackground)
        .hideNavigationBar()
        .sheet(isPresented: $showLeague) { LeagueView(isPresented: $showLeague) }
        .alert("Log junk food", isPresented: $showJunkEntry) {
            TextField("What did you eat?", text: $junkText)
            Button("Log") {
                if !junkText.trimmingCharacters(in: .whitespaces).isEmpty {
                    todayStore.logJunk(junkText)
                    junkText = ""
                }
            }
            Button("Cancel", role: .cancel) { junkText = "" }
        }
    }

    #if os(iOS)
    private var stepsString: String {
        if let steps = HealthKitService.shared.steps { return steps >= 1000 ? String(format: "%.1fk", Double(steps) / 1000) : "\(steps)" }
        return "—"
    }
    #endif

    private func quickStat(icon: String, value: String, label: String) -> some View {
        BBCard(padding: Spacing.sm) {
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.green500)
                Text(value)
                    .font(.serifDisplay(18))
                Text(label)
                    .font(.sans(11))
                    .foregroundStyle(.secondary)
            }
        }
    }

    #if os(macOS)
    // MARK: - macOS: split readiness hero + bento grid (Stitch design)

    private var greeting: String {
        let h = Calendar.current.component(.hour, from: .now)
        switch h { case 0..<12: return "Good morning, Reece."; case 12..<17: return "Good afternoon, Reece."; default: return "Good evening, Reece." }
    }

    private var macLayout: some View {
        HStack(spacing: 0) {
            readinessHero
                .frame(width: 380)
            bentoPane
        }
        .background(Color.bbBackground)
        .hideNavigationBar()
        .sheet(isPresented: $showLeague) { LeagueView(isPresented: $showLeague) }
    }

    private var readinessHero: some View {
        ZStack {
            MeshGradient(
                width: 3, height: 3,
                points: [
                    [0,0], [0.5,0], [1,0],
                    [0,0.5], [0.5,0.5], [1,0.5],
                    [0,1], [0.5,1], [1,1]
                ],
                colors: [
                    Color(hex: "#008560"), Color(hex: "#0F6E56"), Color(hex: "#276656"),
                    Color(hex: "#0F6E56"), Color(hex: "#00694c"), Color(hex: "#085041"),
                    Color(hex: "#00513a"), Color(hex: "#063f30"), Color(hex: "#00694c")
                ]
            )
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                Text("DAILY STATUS")
                    .font(.sans(12, weight: .bold))
                    .kerning(3)
                    .foregroundStyle(Color(hex: "#86f8c9").opacity(0.9))
                (Text(greeting + " ").foregroundStyle(.white)
                 + Text(readinessTagline).foregroundStyle(.white.opacity(0.65)))
                    .font(.serifDisplay(46))
                    .lineSpacing(2)
                    .padding(.top, Spacing.md)

                Spacer()

                ReadinessHeroContent()
            }
            .padding(40)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
    }

    private var readinessTagline: String {
        switch ReadinessStore.shared.todayScore {
        case let s? where s >= 80: return "Primed for progress."
        case let s? where s >= 60: return "Solid foundation today."
        case .some:                return "Recovery day."
        default:                   return "Check in to get started."
        }
    }

    private var bentoPane: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Rank + weekly league
                RankCard(rank: rank) { showLeague = true }

                // Nutrition (full width) — text + arc
                HStack(spacing: Spacing.lg) {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Text("NUTRITION").font(.sans(11, weight: .bold)).foregroundStyle(.secondary).kerning(1.4)
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text("1.8k").font(.serifDisplay(44)).foregroundStyle(Color.green700)
                            Text("/ 2,600 kcal").font(.sans(16)).foregroundStyle(.secondary)
                        }
                        HStack(spacing: Spacing.lg) {
                            macroCol("142g", "Protein")
                            macroCol("210g", "Carbs")
                            macroCol("54g", "Fat")
                        }
                    }
                    Spacer()
                    ZStack {
                        Circle().stroke(Color.green500.opacity(0.13), lineWidth: 12)
                        Circle().trim(from: 0, to: 0.7)
                            .stroke(AngularGradient(colors: [.green500, .green700], center: .center, startAngle: .degrees(-90), endAngle: .degrees(270)),
                                    style: StrokeStyle(lineWidth: 12, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        Text("70%").font(.serifDisplay(24)).foregroundStyle(Color.green700)
                    }
                    .frame(width: 130, height: 130)
                }
                .padding(28)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.bbSurface, in: RoundedRectangle(cornerRadius: 32))
                .shadow(color: Color.green900.opacity(0.06), radius: 20, y: 8)

                // Row: workout (left) + 2x2 stats (right)
                HStack(alignment: .top, spacing: 20) {
                    workoutCard
                        .frame(maxWidth: .infinity)
                    let g = [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]
                    LazyVGrid(columns: g, spacing: 16) {
                        statTile("figure.walk", "8,412", "Steps")
                        statTile("drop.fill", "2.4L", "Water")
                        statTile("scalemass.fill", "74.2", "kg")
                        statTile("bolt.fill", "6", "Days", highlight: true)
                    }
                    .frame(width: 300)
                }
            }
            .padding(40)
            .frame(maxWidth: 900, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
    }

    private func macroCol(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value).font(.sans(15, weight: .bold))
            Text(label.uppercased()).font(.sans(10)).foregroundStyle(.secondary).kerning(0.8)
        }
    }

    private var workoutCard: some View {
        ZStack {
            LinearGradient(colors: [Color.green700, Color(hex: "#06251C")], startPoint: .top, endPoint: .bottom)
            // faint dumbbell motif
            Image(systemName: "dumbbell.fill")
                .font(.system(size: 220))
                .foregroundStyle(.white.opacity(0.05))
                .rotationEffect(.degrees(-20))
                .offset(x: 40, y: 30)
            VStack(alignment: .leading) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("NEXT SESSION").font(.sans(11, weight: .bold)).kerning(1.4).foregroundStyle(Color(hex: "#86f8c9"))
                    Text("Upper Body Alpha").font(.serifDisplay(28)).foregroundStyle(.white)
                    Text("45 min · Strength").font(.sans(14)).foregroundStyle(.white.opacity(0.8))
                }
                Spacer()
                Button {} label: {
                    HStack(spacing: 8) {
                        Text("START").font(.sans(14, weight: .bold)).kerning(2)
                        Image(systemName: "play.fill").font(.system(size: 13))
                    }
                    .foregroundStyle(Color.green900)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(.white, in: Capsule())
                }
                .buttonStyle(ScaleButtonStyle())
            }
            .padding(28)
        }
        .frame(height: 340)
        .clipShape(RoundedRectangle(cornerRadius: 32))
    }

    private func statTile(_ icon: String, _ value: String, _ label: String, highlight: Bool = false) -> some View {
        VStack(alignment: .leading) {
            Image(systemName: icon).font(.system(size: 18)).foregroundStyle(Color.green500)
            Spacer()
            Text(value).font(.serifDisplay(30)).foregroundStyle(highlight ? Color.green700 : .primary)
            Text(label.uppercased()).font(.sans(10)).foregroundStyle(.secondary).kerning(1.2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 162)
        .padding(20)
        .background(highlight ? Color.green500.opacity(0.07) : Color.bbSurface, in: RoundedRectangle(cornerRadius: 28))
        .shadow(color: Color.green900.opacity(0.05), radius: 14, y: 6)
    }
    #endif
}
