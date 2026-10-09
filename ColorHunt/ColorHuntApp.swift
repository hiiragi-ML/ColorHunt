import SwiftUI
import SwiftData

@main
struct ColorHuntApp: App{
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup{
            ContentView()
                .task {
                    try? await NotificationManager.reschedule()
                }
        }
        .modelContainer(for: HuntPhoto.self)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task {
                    try? await NotificationManager.reschedule()
                }
            }
        }
    }
}
