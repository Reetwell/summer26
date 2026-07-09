import SwiftUI
import Charts

struct ProgressDashboardView: View {
    @State private var period = 1   // 0 week, 1 month, 2 year
    @State private var selectedTimeline = 0

    private let periods = ["Week", "Month", "Year"]
    private let timeline: [(String, String)] = [
        ("This Month", "Oct 2023"),
        ("Last Month", "Sep 2023"),
        ("Q3 2023", "Jul – Sep"),
        ("Year to Date", "2023")
    ]

    struct Lift: Identifiable {
        let id = UUID(); let name: String; let kg: String; let delta: String; let bars: [CGFloat]
    }
    private let lifts: [Lift] = [
        .init(name: "Bench Press", kg: "85", delta: "+5kg", bars: [0.3, 0.45, 0.5, 0.7, 1.0]),
        .init(name: "Squat", kg: "120", delta: "+10kg", bars: [0.4, 0.5, 0.6, 0.75, 1.0]),
        .init(name: "Deadlift", kg: "145", delta: "+15kg", bars: [0.35, 0.5, 0.65, 0.8, 1.0]),
        .init(name: "Overhead Press", kg: "62", delta: "0kg", bars: [0.5, 0.55, 0.6, 0.7, 0.72])
    ]

    struct WeightPoint: Identifiable { let id = UUID(); let day: Int; let kg: Double }
    private let weightSeries: [WeightPoint] = [
        .init(day: 1, kg: 79.6), .init(day: 4, kg: 79.5), .init(day: 8, kg: 79.55),
        .init(day: 12, kg: 79.2), .init(day: 16, kg: 79.0), .init(day: 20, kg: 78.9),
        .init(day: 24, kg: 78.5), .init(day: 28, kg: 78.2), .init(day: 30, kg: 78.2)
    ]

    var body: some View {
        #if os(macOS)
        macLayout
        #else
        iosLayout
        #endif
    }

    // MARK: - macOS

    #if os(macOS)
    private var macLayout: some View {
        HStack(spacing: 0) {
            timelineRail
            ScrollView {
                VStack(spacing: 20) {
                    weightHero
                    strengthRow
                    HStack(alignment: .top, spacing: 20) {
                        weightChartCard.frame(maxWidth: .infinity)
                        VStack(spacing: 20) {
                            consistencyCard
                            prCard
                        }
                        .frame(width: 320)
                    }
                    photosRow
                }
                .padding(40)
                .padding(.bottom, 96)
                .frame(maxWidth: 1080, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
        }
        .background(Color.bbBackground)
        .hideNavigationBar()
    }

    private var timelineRail: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("TIMELINE")
                .font(.sans(11, weight: .bold))
                .foregroundStyle(.secondary)
                .kerning(1.4)
                .padding(.bottom, Spacing.lg)

            ForEach(timeline.indices, id: \.self) { i in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { selectedTimeline = i }
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        VStack(spacing: 0) {
                            Circle()
                                .stroke(selectedTimeline == i ? Color.green500 : Color.secondary.opacity(0.35), lineWidth: 2)
                                .background(Circle().fill(selectedTimeline == i ? Color.green500 : .clear))
                                .frame(width: 13, height: 13)
                            if i < timeline.count - 1 {
                                Rectangle().fill(Color.secondary.opacity(0.2)).frame(width: 1.5, height: 42)
                            }
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(timeline[i].0)
                                .font(.sans(14, weight: .bold))
                                .foregroundStyle(selectedTimeline == i ? Color.green700 : .primary)
                            Text(timeline[i].1)
                                .font(.sans(12))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, -2)
                        Spacer()
                    }
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .padding(.top, 44)
        .padding(.horizontal, Spacing.lg)
        .frame(width: 210, alignment: .leading)
    }
    #endif

    // MARK: - iOS

    #if os(iOS)
    private var iosLayout: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("Progress")
                    .font(.serifDisplay(34))
                    .slideIn()
                weightHero.slideIn(delay: 0.05)
                sectionLabel("STRENGTH").slideIn(delay: 0.1)
                LazyVGrid(columns: [GridItem(.flexible(), spacing: Spacing.sm), GridItem(.flexible(), spacing: Spacing.sm)], spacing: Spacing.sm) {
                    ForEach(lifts) { liftCard($0) }
                }
                .slideIn(delay: 0.12)
                weightChartCard.slideIn(delay: 0.16)
                consistencyCard.slideIn(delay: 0.2)
                prCard.slideIn(delay: 0.24)
                sectionLabel("PROGRESS PHOTOS").slideIn(delay: 0.28)
                photosRow.slideIn(delay: 0.3)
            }
            .padding(Spacing.md)
            .padding(.bottom, Spacing.xl)
            .readableWidth()
        }
        .background(Color.bbBackground)
        .hideNavigationBar()
    }

    private func sectionLabel(_ t: String) -> some View {
        Text(t).font(.sans(11, weight: .semibold)).foregroundStyle(.secondary).kerning(1.2).padding(.top, 4)
    }
    #endif

    // MARK: - shared cards

    private var weightHero: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                Text("WEIGHT TREND")
                    .font(.sans(11, weight: .bold))
                    .foregroundStyle(.white.opacity(0.7))
                    .kerning(1.4)
                Spacer()
                // period toggle
                HStack(spacing: 0) {
                    ForEach(periods.indices, id: \.self) { i in
                        Text(periods[i])
                            .font(.sans(12, weight: .semibold))
                            .lineLimit(1)
                            .fixedSize()
                            .foregroundStyle(period == i ? Color.green900 : .white.opacity(0.85))
                            .padding(.horizontal, 13).padding(.vertical, 7)
                            .background {
                                if period == i { Capsule().fill(.white) }
                            }
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { period = i }
                            }
                    }
                }
                .padding(3)
                .background(.white.opacity(0.15), in: Capsule())
            }
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("−1.4").font(.serifDisplay(64)).foregroundStyle(.white)
                Text("kg").font(.serifDisplay(34)).foregroundStyle(.white.opacity(0.85))
            }
            .padding(.top, 6)
            Text("this \(periods[period].lowercased())")
                .font(.sans(14))
                .foregroundStyle(.white.opacity(0.8))
        }
        .padding(28)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(colors: [Color.green700, Color.green900],
                           startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 28)
        )
    }

    #if os(macOS)
    private var strengthRow: some View {
        HStack(spacing: 20) {
            ForEach(lifts) { liftCard($0) }
        }
    }
    #endif

    private func liftCard(_ l: Lift) -> some View {
        BBCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(l.name).font(.sans(13, weight: .semibold)).lineLimit(1)
                    Spacer()
                    Text(l.delta)
                        .font(.sans(10, weight: .bold))
                        .foregroundStyle(l.delta == "0kg" ? .secondary : Color.green700)
                        .padding(.horizontal, 7).padding(.vertical, 3)
                        .background((l.delta == "0kg" ? Color.secondary : Color.green500).opacity(0.12), in: Capsule())
                }
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text(l.kg).font(.serifDisplay(30))
                    Text("kg").font(.sans(13)).foregroundStyle(.secondary)
                }
                HStack(alignment: .bottom, spacing: 4) {
                    ForEach(l.bars.indices, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(i == l.bars.count - 1 ? Color.green700 : Color.green500.opacity(0.15))
                            .frame(height: 26 * l.bars[i])
                            .frame(maxWidth: .infinity, alignment: .bottom)
                    }
                }
                .frame(height: 26, alignment: .bottom)
            }
        }
    }

    private var weightChartCard: some View {
        BBCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Body Weight").font(.sans(17, weight: .semibold))
                        Text("Last 30 Days").font(.sans(12)).foregroundStyle(.secondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 0) {
                        HStack(alignment: .firstTextBaseline, spacing: 3) {
                            Text("78.2").font(.serifDisplay(26)).foregroundStyle(Color.green700)
                            Text("kg").font(.sans(12)).foregroundStyle(.secondary)
                        }
                        Text("CURRENT").font(.sans(9, weight: .bold)).foregroundStyle(.secondary).kerning(1)
                    }
                }
                Chart(weightSeries) { pt in
                    AreaMark(x: .value("Day", pt.day), y: .value("kg", pt.kg))
                        .foregroundStyle(LinearGradient(colors: [Color.green500.opacity(0.18), .clear], startPoint: .top, endPoint: .bottom))
                        .interpolationMethod(.catmullRom)
                    LineMark(x: .value("Day", pt.day), y: .value("kg", pt.kg))
                        .foregroundStyle(Color.green700)
                        .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                        .interpolationMethod(.catmullRom)
                }
                .chartYScale(domain: 77.8...80.2)
                .chartYAxis {
                    AxisMarks(values: [78, 79, 80]) { v in
                        AxisValueLabel { if let d = v.as(Double.self) { Text(String(format: "%.0f", d)).font(.sans(10)).foregroundStyle(.secondary) } }
                        AxisGridLine().foregroundStyle(Color.secondary.opacity(0.12))
                    }
                }
                .chartXAxis {
                    AxisMarks(values: [1, 15, 30]) { v in
                        AxisValueLabel {
                            if let d = v.as(Int.self) {
                                Text(d == 1 ? "Oct 1" : d == 15 ? "Oct 15" : "Today").font(.sans(10)).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .frame(height: 190)
            }
        }
    }

    private var consistencyCard: some View {
        BBCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.green700)
                        .frame(width: 32, height: 32)
                        .background(Color.green500.opacity(0.12), in: RoundedRectangle(cornerRadius: 9))
                    Text("Consistency").font(.sans(17, weight: .semibold))
                }
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("24").font(.serifDisplay(32))
                        Text("TOTAL WORKOUTS").font(.sans(9, weight: .bold)).foregroundStyle(.secondary).kerning(0.8)
                    }
                    Spacer()
                    VStack(alignment: .leading, spacing: 2) {
                        Text("6").font(.serifDisplay(32)).foregroundStyle(Color.green700)
                        Text("DAY STREAK").font(.sans(9, weight: .bold)).foregroundStyle(.secondary).kerning(0.8)
                    }
                    Spacer()
                }
                Text("SESSIONS / WEEK").font(.sans(9, weight: .bold)).foregroundStyle(.secondary).kerning(0.8)
                HStack(spacing: 8) {
                    ForEach(0..<4, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 8)
                            .fill(i == 3 ? Color.green700 : Color.green500.opacity(0.12))
                            .frame(height: 34)
                    }
                }
            }
        }
    }

    private var prCard: some View {
        BBCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "trophy.fill").font(.system(size: 14)).foregroundStyle(Color(hex: "#E8A13A"))
                    Text("Personal Records").font(.sans(16, weight: .semibold))
                }
                Text("Next target: Squat 125 kg — you're close.")
                    .font(.sans(13)).foregroundStyle(.secondary)
            }
        }
    }

    private var photosRow: some View {
        HStack(spacing: 16) {
            // Add photo tile
            VStack(spacing: 8) {
                Image(systemName: "camera").font(.system(size: 22)).foregroundStyle(.secondary)
                Text("Add Photo").font(.sans(12)).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 200)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(Color.secondary.opacity(0.3), style: StrokeStyle(lineWidth: 1.5, dash: [6]))
            )
            photoPlaceholder
            photoPlaceholder
        }
    }

    private var photoPlaceholder: some View {
        ZStack {
            Color.secondary.opacity(0.1)
            Image(systemName: "figure.stand").font(.system(size: 40)).foregroundStyle(.secondary.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}
