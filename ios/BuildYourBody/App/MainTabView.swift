import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            Tab("Today", systemImage: "sun.max.fill") {
                NavigationStack { TodayView() }
            }
            Tab("Meals", systemImage: "fork.knife") {
                NavigationStack { PlaceholderView(title: "Meals") }
            }
            Tab("Training", systemImage: "dumbbell.fill") {
                NavigationStack { PlaceholderView(title: "Training") }
            }
            Tab("Shopping", systemImage: "cart.fill") {
                NavigationStack { PlaceholderView(title: "Shopping") }
            }
            Tab("Account", systemImage: "person.fill") {
                NavigationStack { PlaceholderView(title: "Account") }
            }
        }
        .tint(.green500)
    }
}

struct PlaceholderView: View {
    let title: String
    var body: some View {
        ContentUnavailableView(title, systemImage: "hammer.fill", description: Text("Coming soon"))
            .navigationTitle(title)
    }
}
