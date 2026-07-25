import SwiftUI

@main
struct BuildYourBodyApp: App {
    @State private var appState = AppState()

    init() {
        BrandFont.register()
        DemoData.seedIfActive()   // DEBUG screenshot data; no-op unless -BB_DEMO 1
    }

    var body: some Scene {
        WindowGroup {
            #if DEBUG
            // Design QA route, off unless explicitly launched with
            // `-BBRankGallery YES`. Never present in a release build.
            if UserDefaults.standard.bool(forKey: "BBRankGallery") {
                RankBadgeGallery()
            } else {
                RootView().environment(appState)
            }
            #else
            RootView()
                .environment(appState)
            #endif
        }
    }
}
