import SwiftUI

@main
struct SILWatchApp: App {
    @StateObject private var sessionStore = WatchSessionStore()

    var body: some Scene {
        WindowGroup {
            WatchHomeView()
                .environmentObject(sessionStore)
        }
    }
}
