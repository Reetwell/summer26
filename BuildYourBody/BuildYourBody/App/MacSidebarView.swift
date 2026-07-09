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
        ("cart.fill", "Shopping"),
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
            HStack(spacing: 2) {
                ForEach(items.indices, id: \.self) { i in
                    dockButton(i)
                }
            }
            .padding(5)
            .glassEffect(.regular.interactive(), in: Capsule())
        }
    }

    private func dockButton(_ i: Int) -> some View {
        let selected = selection == i
        return Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                selection = i
            }
        } label: {
            HStack(spacing: 7) {
                Image(systemName: items[i].icon)
                    .font(.system(size: 15, weight: .medium))
                if selected {
                    Text(items[i].label)
                        .font(.sans(13, weight: .semibold))
                        .fixedSize()
                }
            }
            .foregroundStyle(selected ? .white : .secondary)
            .padding(.horizontal, selected ? 16 : 12)
            .frame(height: 44)
            .background {
                if selected {
                    Capsule()
                        .fill(Color.green500)
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
        case 3: ShoppingView().id(3)
        default: AccountView().id(4)
        }
    }
}
#endif
