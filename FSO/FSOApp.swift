import SwiftUI

@main
struct FSOApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .tint(AppTheme.textPrimary)
                .preferredColorScheme(.dark)
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 1000, height: 700)
    }
}
