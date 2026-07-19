import SwiftUI

@main
struct BuildYourBodyApp: App {
    @State private var appState = AppState()

    init() {
        BrandFont.register()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
        }
    }
}
