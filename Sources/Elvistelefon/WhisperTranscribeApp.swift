import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        NotificationCenter.default.post(name: .openSettings, object: nil)
        return true
    }
}

extension Notification.Name {
    static let openSettings = Notification.Name("OpenSettings")
}

@main
struct ElvistelefonApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var viewModel = AppViewModel()

    init() {
        // Ensure no dock icon (belt-and-suspenders with Info.plist LSUIElement)
        NSApplication.shared.setActivationPolicy(.accessory)
        // Migrate API key from old "WhisperTranscribe" directory
        KeychainService.migrateFromOldName()
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(viewModel: viewModel)
        } label: {
            Label("Elvistelefon", systemImage: viewModel.systemImage)
        }

        Window("Elvistelefon Settings", id: "settings") {
            SettingsView()
        }
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)
    }
}
