import SwiftUI

struct MainTabView: View {
    @State private var selection: Int

    init() {
        #if DEBUG
        // Test hook: SIMCTL_CHILD_BB_TAB=n preselects a tab
        _selection = State(initialValue: Int(ProcessInfo.processInfo.environment["BB_TAB"] ?? "0") ?? 0)
        #else
        _selection = State(initialValue: 0)
        #endif
    }

    var body: some View {
        #if os(macOS)
        MacRootView()
        #else
        iosTabs
        #endif
    }

    private var iosTabs: some View {
        TabView(selection: $selection) {
            Tab("Today", systemImage: "sun.max.fill", value: 0) {
                NavigationStack { TodayView() }
            }
            Tab("Meals", systemImage: "fork.knife", value: 1) {
                NavigationStack { MealsView() }
            }
            Tab("Training", systemImage: "dumbbell.fill", value: 2) {
                NavigationStack { TrainingView() }
            }
            Tab("Shopping", systemImage: "cart.fill", value: 3) {
                NavigationStack { ShoppingView() }
            }
            Tab("Account", systemImage: "person.fill", value: 4) {
                NavigationStack { AccountView() }
            }
        }
        #if os(macOS)
        .tabViewStyle(.sidebarAdaptable)
        #endif
        .tint(.green500)
    }
}
