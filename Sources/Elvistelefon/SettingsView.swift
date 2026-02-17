import KeyboardShortcuts
import SwiftUI

// MARK: - Card Helpers

private struct SettingsCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            content
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.background)
                .shadow(color: .black.opacity(0.06), radius: 1, y: 1)
                .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
        )
    }
}

private struct SettingsCardHeader: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(color.gradient)
                .frame(width: 28, height: 28)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                )
            Text(title)
                .font(.headline)
        }
    }
}

// MARK: - Elvis Icon View

private struct ElvisIconView: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.yellow, Color.orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 64, height: 64)
                .shadow(color: .orange.opacity(0.4), radius: 12, y: 4)

            Image(systemName: "waveform")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.white)
        }
    }
}

// MARK: - Recording Mode Option

private struct RecordingModeOption: View {
    let icon: String
    let title: String
    let description: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(isSelected ? .red : .secondary)
                    .frame(width: 20)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.primary)
                    Text(description)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18))
                    .foregroundStyle(isSelected ? Color.red : Color.secondary.opacity(0.3))
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected ? Color.red.opacity(0.06) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(isSelected ? Color.red.opacity(0.3) : Color.clear, lineWidth: 1)
                    )
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Tonality Mode Option

private struct TonalityModeOption: View {
    let mode: TonalityMode
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: mode.icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(isSelected ? mode.accentColor : .secondary)
                    .frame(width: 20)

                VStack(alignment: .leading, spacing: 2) {
                    Text(mode.displayName)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.primary)
                    Text(mode.description)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18))
                    .foregroundStyle(isSelected ? mode.accentColor : Color.secondary.opacity(0.3))
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected ? mode.accentColor.opacity(0.06) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(isSelected ? mode.accentColor.opacity(0.3) : Color.clear, lineWidth: 1)
                    )
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @State private var apiKey: String = ""
    @State private var hasKey: Bool = KeychainService.hasAPIKey
    @State private var showSaveConfirmation: Bool = false
    @State private var errorMessage: String?
    @State private var iconTapCount: Int = 0
    @State private var showEasterEgg: Bool = false
    @AppStorage("recordingMode") private var recordingMode: String = RecordingMode.pushToTalk.rawValue
    @AppStorage("tonalityMode") private var tonalityMode: String = TonalityMode.normal.rawValue

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 20) {
                Spacer().frame(height: 8)
                // Elvis Branded Header
                VStack(spacing: 6) {
                    ElvisIconView()
                        .onTapGesture {
                            iconTapCount += 1
                            if iconTapCount >= 7 {
                                iconTapCount = 0
                                showEasterEgg = true
                            }
                        }
                        .popover(isPresented: $showEasterEgg) {
                            VStack(spacing: 8) {
                                Text("\u{1F57A}")
                                    .font(.system(size: 32))
                                Text("A little less conversation, a little more action please.")
                                    .font(.system(size: 12))
                                    .italic()
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 12)
                            }
                            .padding(16)
                        }

                    Text("Elvistelefon")
                        .font(.title2.bold())
                    Text("Thank you, thank you very much.")
                        .font(.subheadline)
                        .italic()
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, 4)

                // API Key Card
                SettingsCard {
                    SettingsCardHeader(icon: "key.fill", title: "OpenAI API Key", color: .orange)

                    if hasKey {
                        HStack {
                            Label("API key saved", systemImage: "checkmark.shield.fill")
                                .foregroundStyle(.green)
                                .font(.system(size: 12))
                            Spacer()
                            Button("Remove", role: .destructive) {
                                removeKey()
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }

                    SecureField("sk-...", text: $apiKey)
                        .textFieldStyle(.roundedBorder)
                        .controlSize(.large)
                        .font(.system(.body, design: .monospaced))

                    HStack {
                        Button("Save API Key") {
                            saveKey()
                        }
                        .disabled(apiKey.isEmpty)
                        .buttonStyle(.borderedProminent)
                        .tint(.orange)
                        .controlSize(.regular)

                        if showSaveConfirmation {
                            Label("Saved", systemImage: "checkmark.circle")
                                .foregroundStyle(.green)
                                .font(.caption)
                                .transition(.opacity.combined(with: .scale))
                        }

                        if let errorMessage {
                            Label(errorMessage, systemImage: "exclamationmark.triangle")
                                .foregroundStyle(.red)
                                .font(.caption)
                                .transition(.opacity.combined(with: .scale))
                        }
                    }
                    .animation(.easeInOut(duration: 0.2), value: showSaveConfirmation)
                    .animation(.easeInOut(duration: 0.2), value: errorMessage)
                }

                // Recording Mode Card
                SettingsCard {
                    SettingsCardHeader(icon: "mic.fill", title: "Recording Mode", color: .red)

                    VStack(spacing: 8) {
                        RecordingModeOption(
                            icon: "hand.tap.fill",
                            title: "Push to Talk",
                            description: "Hold shortcut to record, release to stop",
                            isSelected: recordingMode == RecordingMode.pushToTalk.rawValue
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                recordingMode = RecordingMode.pushToTalk.rawValue
                            }
                        }

                        RecordingModeOption(
                            icon: "repeat",
                            title: "Toggle",
                            description: "Press once to start, press again to stop",
                            isSelected: recordingMode == RecordingMode.toggle.rawValue
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                recordingMode = RecordingMode.toggle.rawValue
                            }
                        }
                    }
                }

                // Tonality Mode Card
                SettingsCard {
                    SettingsCardHeader(icon: "theatermasks.fill", title: "Tonality Mode", color: .purple)

                    VStack(spacing: 8) {
                        ForEach(TonalityMode.allCases) { mode in
                            TonalityModeOption(
                                mode: mode,
                                isSelected: tonalityMode == mode.rawValue
                            ) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    tonalityMode = mode.rawValue
                                }
                            }
                        }
                    }
                }

                // Shortcut Card
                SettingsCard {
                    SettingsCardHeader(icon: "keyboard.fill", title: "Keyboard Shortcut", color: .blue)

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(recordingMode == RecordingMode.toggle.rawValue ? "Toggle Recording" : "Push to Talk")
                                .font(.system(size: 13, weight: .medium))
                            Text("Set a global keyboard shortcut to control recording")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }

                        Spacer(minLength: 16)

                        KeyboardShortcuts.Recorder(for: .toggleRecording)
                    }
                }
            }
            .padding(28)
            .frame(width: 500)
        }
        .frame(maxHeight: 780)
        .background(.regularMaterial)
        .ignoresSafeArea()
    }

    private func saveKey() {
        do {
            try KeychainService.saveAPIKey(apiKey)
            apiKey = ""
            hasKey = true
            showSaveConfirmation = true
            errorMessage = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showSaveConfirmation = false
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func removeKey() {
        do {
            try KeychainService.deleteAPIKey()
            hasKey = false
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
