import SwiftUI

struct TodayView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Placeholder — full dashboard coming in Phase 3
                ContentUnavailableView(
                    "Dashboard",
                    systemImage: "sun.max.fill",
                    description: Text("Your today view is being built.")
                )
            }
            .padding(Spacing.md)
        }
        .navigationTitle("Today")
        .navigationBarTitleDisplayMode(.large)
    }
}
