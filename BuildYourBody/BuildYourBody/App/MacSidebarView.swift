import SwiftUI

#if os(macOS)
// Mac layout — content fills the window and scrolls BEHIND a floating
// Liquid Glass tab bar at the bottom (same idea as the iPhone tab bar).
struct MacRootView: View {
    @State private var selection: Int = {
        #if DEBUG
        return Int(ProcessInfo.processInfo.environment["BB_TAB"] ?? "0") ?? 0
        #else
        return 0
        #endif
    }()
    @Namespace private var dockNamespace

    private let items: [(icon: String, label: String)] = [
        ("sun.max.fill", "Today"),
        ("fork.knife", "Meals"),
        ("dumbbell.fill", "Training"),
        ("chart.line.uptrend.xyaxis", "Progress"),
        ("person.fill", "Account")
    ]

    var body: some View {
        // detail fills the whole window; the dock floats over its bottom so
        // content passes behind the glass and gets refracted.
        detail
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.bbBackground)
            .overlay(alignment: .bottom) {
                floatingDock
                    .padding(.bottom, 20)
            }
    }

    private var floatingDock: some View {
        GlassEffectContainer {
            HStack(spacing: 4) {
                ForEach(items.indices, id: \.self) { i in
                    dockButton(i)
                }
            }
            .padding(7)
            .glassEffect(.regular.interactive(), in: Capsule())
            .overlay(
                Capsule().strokeBorder(.white.opacity(0.35), lineWidth: 0.5)
            )
            .shadow(color: Color.green900.opacity(0.14), radius: 22, y: 10)
        }
    }

    private func dockButton(_ i: Int) -> some View {
        let selected = selection == i
        return Button {
            withAnimation(.spring(response: 0.42, dampingFraction: 0.72)) {
                selection = i
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: items[i].icon)
                    .font(.system(size: 15, weight: .semibold))
                    .symbolEffect(.bounce, value: selected)
                if selected {
                    Text(items[i].label)
                        .font(.sans(13, weight: .bold))
                        .fixedSize()
                        .transition(.opacity.combined(with: .move(edge: .leading)))
                }
            }
            .foregroundStyle(selected ? .white : .secondary)
            .padding(.horizontal, selected ? 20 : 15)
            .frame(height: 46)
            .background {
                if selected {
                    Capsule()
                        .fill(
                            LinearGradient(colors: [.green500, .green700],
                                           startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .shadow(color: Color.green700.opacity(0.4), radius: 8, y: 3)
                        .matchedGeometryEffect(id: "activePill", in: dockNamespace)
                }
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var detail: some View {
        switch selection {
        case 0: TodayView().id(0)
        case 1: MealsView().id(1)
        case 2: TrainingView().id(2)
        case 3: ProgressDashboardView().id(3)
        default: AccountView().id(4)
        }
    }
}
#endif
