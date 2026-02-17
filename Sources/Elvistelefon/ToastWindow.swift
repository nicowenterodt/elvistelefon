import AppKit
import SwiftUI

// MARK: - Toast SwiftUI View

struct ToastView: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
            Text(text)
                .font(.system(size: 13, weight: .medium))
                .lineLimit(1)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(color.opacity(0.85))
                .shadow(color: .black.opacity(0.25), radius: 8, y: 4)
        )
    }
}

// MARK: - Sound Wave View

struct SoundWaveView: View {
    var audioLevel: Float
    private let barCount = 5
    private let phaseMultipliers: [Double] = [1.0, 1.6, 1.2, 1.8, 1.1]

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<barCount, id: \.self) { index in
                SoundWaveBar(audioLevel: audioLevel, phaseMultiplier: phaseMultipliers[index])
            }
        }
    }
}

private struct SoundWaveBar: View {
    var audioLevel: Float
    var phaseMultiplier: Double

    @State private var animating = false

    private var height: CGFloat {
        let base: CGFloat = 4
        let maxHeight: CGFloat = 18
        let level = CGFloat(audioLevel) * phaseMultiplier
        return min(base + level * (maxHeight - base), maxHeight)
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 1.5)
            .fill(
                LinearGradient(
                    colors: [Color.yellow, Color.white],
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
            .frame(width: 3, height: height)
            .animation(.easeInOut(duration: 0.15), value: audioLevel)
    }
}

// MARK: - Recording Toast View

struct RecordingToastView: View {
    @ObservedObject var viewModel: AppViewModel

    var body: some View {
        HStack(spacing: 8) {
            SoundWaveView(audioLevel: viewModel.audioLevel)
            Text("Recording…")
                .font(.system(size: 13, weight: .medium))
                .lineLimit(1)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [Color.red, Color.orange],
                        startPoint: .leading,
                        endPoint: .trailing
                    ).opacity(0.85)
                )
                .shadow(color: .black.opacity(0.25), radius: 8, y: 4)
        )
    }
}

// MARK: - Transcribing Toast View

struct TranscribingToastView: View {
    private static let phrases = [
        "Channeling the King…",
        "A little less conversation…",
        "All shook up…",
        "Taking care of business…",
        "In the groove…",
        "Uh-huh-huh…",
        "Rocking the transcription…",
    ]

    @State private var currentIndex = Int.random(in: 0..<phrases.count)
    private let timer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "ellipsis.circle")
                .font(.system(size: 14, weight: .semibold))
            Text(Self.phrases[currentIndex])
                .font(.system(size: 13, weight: .medium))
                .lineLimit(1)
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.3), value: currentIndex)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(Color.orange.opacity(0.85))
                .shadow(color: .black.opacity(0.25), radius: 8, y: 4)
        )
        .onReceive(timer) { _ in
            var next = Int.random(in: 0..<Self.phrases.count)
            while next == currentIndex {
                next = Int.random(in: 0..<Self.phrases.count)
            }
            currentIndex = next
        }
    }
}

// MARK: - Transforming Toast View

struct TransformingToastView: View {
    let mode: TonalityMode

    @State private var currentIndex: Int

    private let timer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()

    init(mode: TonalityMode) {
        self.mode = mode
        _currentIndex = State(initialValue: Int.random(in: 0..<mode.transformingPhrases.count))
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: mode.icon)
                .font(.system(size: 14, weight: .semibold))
            Text(mode.transformingPhrases[currentIndex])
                .font(.system(size: 13, weight: .medium))
                .lineLimit(1)
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.3), value: currentIndex)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(mode.accentColor.opacity(0.85))
                .shadow(color: .black.opacity(0.25), radius: 8, y: 4)
        )
        .onReceive(timer) { _ in
            let phrases = mode.transformingPhrases
            var next = Int.random(in: 0..<phrases.count)
            while next == currentIndex {
                next = Int.random(in: 0..<phrases.count)
            }
            currentIndex = next
        }
    }
}

// MARK: - Toast Window

@MainActor
final class ToastWindow {
    static let shared = ToastWindow()

    private var panel: NSPanel?
    private var dismissWorkItem: DispatchWorkItem?

    private init() {}

    func show(icon: String, text: String, color: Color, autoDismissAfter: TimeInterval? = nil) {
        dismissWorkItem?.cancel()
        dismiss()

        let toastView = ToastView(icon: icon, text: text, color: color)
        let hostingView = NSHostingView(rootView: toastView)
        hostingView.setFrameSize(hostingView.fittingSize)

        let panel = makePanel(contentView: hostingView)
        positionPanel(panel, size: hostingView.fittingSize)

        panel.orderFrontRegardless()
        self.panel = panel

        if let duration = autoDismissAfter {
            let item = DispatchWorkItem { [weak self] in
                self?.dismiss()
            }
            dismissWorkItem = item
            DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: item)
        }
    }

    func showTranscribing() {
        dismissWorkItem?.cancel()
        dismiss()

        let transcribingView = TranscribingToastView()
        let hostingView = NSHostingView(rootView: transcribingView)
        hostingView.setFrameSize(hostingView.fittingSize)

        let panel = makePanel(contentView: hostingView)
        positionPanel(panel, size: hostingView.fittingSize)

        panel.orderFrontRegardless()
        self.panel = panel
    }

    func showRecording(viewModel: AppViewModel) {
        dismissWorkItem?.cancel()
        dismiss()

        let recordingView = RecordingToastView(viewModel: viewModel)
        let hostingView = NSHostingView(rootView: recordingView)
        hostingView.setFrameSize(hostingView.fittingSize)

        let panel = makePanel(contentView: hostingView)
        positionPanel(panel, size: hostingView.fittingSize)

        panel.orderFrontRegardless()
        self.panel = panel
    }

    func showTransforming(mode: TonalityMode) {
        dismissWorkItem?.cancel()
        dismiss()

        let transformingView = TransformingToastView(mode: mode)
        let hostingView = NSHostingView(rootView: transformingView)
        hostingView.setFrameSize(hostingView.fittingSize)

        let panel = makePanel(contentView: hostingView)
        positionPanel(panel, size: hostingView.fittingSize)

        panel.orderFrontRegardless()
        self.panel = panel
    }

    func dismiss() {
        dismissWorkItem?.cancel()
        dismissWorkItem = nil
        panel?.orderOut(nil)
        panel = nil
    }

    private func makePanel(contentView: NSView) -> NSPanel {
        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: contentView.fittingSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary]
        panel.isMovableByWindowBackground = false
        panel.contentView = contentView
        return panel
    }

    private func positionPanel(_ panel: NSPanel, size: NSSize) {
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.midX - size.width / 2
            let y = screenFrame.maxY - size.height - 20
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }
    }
}
