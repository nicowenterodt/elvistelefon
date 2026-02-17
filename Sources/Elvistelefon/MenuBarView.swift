import Combine
import KeyboardShortcuts
import SwiftUI

struct MenuBarView: View {
    @ObservedObject var viewModel: AppViewModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Status
            HStack {
                Image(systemName: viewModel.systemImage)
                    .foregroundColor(statusColor)
                Text(viewModel.statusText)
                    .lineLimit(2)
            }
            .padding(.horizontal, 8)
            .padding(.top, 4)

            Divider()

            // Record button
            Button(action: { viewModel.toggleRecording() }) {
                Label(
                    viewModel.state == .recording ? "Stop Recording" : "Start Recording",
                    systemImage: viewModel.state == .recording ? "stop.circle" : "mic.circle"
                )
            }
            .keyboardShortcut("r", modifiers: [.command, .shift])
            .disabled(viewModel.state == .transcribing)

            Divider()

            // Settings
            Button(action: openSettings) {
                Label("Settings…", systemImage: "gear")
            }
            .keyboardShortcut(",", modifiers: [.command])

            Divider()

            Button("Quit") {
                ToastWindow.shared.show(
                    icon: "figure.walk",
                    text: "Elvis has left the building!",
                    color: .purple
                )
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    NSApplication.shared.terminate(nil)
                }
            }
            .keyboardShortcut("q")
        }
        .padding(.vertical, 4)
        .frame(width: 260)
        .onReceive(NotificationCenter.default.publisher(for: .openSettings)) { _ in
            openSettings()
        }
    }

    private var statusColor: Color {
        switch viewModel.state {
        case .idle: return .secondary
        case .recording: return .red
        case .transcribing: return .orange
        case .done: return .green
        case .error: return .red
        }
    }

    private func openSettings() {
        openWindow(id: "settings")
        NSApp.activate(ignoringOtherApps: true)
    }
}
