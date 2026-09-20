import AppKit
import SwiftUI

struct AppVibrancyBackground: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .sidebar
        view.blendingMode = .behindWindow
        view.state = .active
        view.isEmphasized = true
        view.autoresizingMask = [.width, .height]
        return view
    }

    func updateNSView(_ view: NSVisualEffectView, context: Context) {
        view.material = .sidebar
        view.blendingMode = .behindWindow
        view.state = .active
    }
}

struct AppGlassBackground: View {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        if reduceTransparency {
            Color(nsColor: .windowBackgroundColor)
        } else {
            AppVibrancyBackground()
        }
    }
}

struct FullWidthRowSeparator: View {
    var body: some View {
        Rectangle()
            .fill(Color(nsColor: .separatorColor).opacity(0.55))
            .frame(height: 1)
            .frame(maxWidth: .infinity)
    }
}

extension View {
    func clearInitialFocusOnAppear() -> some View {
        onAppear {
            DispatchQueue.main.async {
                NSApp.keyWindow?.makeFirstResponder(nil)
            }
        }
    }

    @ViewBuilder
    func nativeScrollEdgeChrome() -> some View {
        if #available(macOS 26.0, iOS 26.0, *) {
            self
                .toolbarBackground(.visible, for: .automatic)
                .scrollEdgeEffectStyle(.soft, for: .top)
        } else {
            self
        }
    }
}

struct IconActionButton: View {
    let systemImage: String
    let help: String
    var size: CGFloat = 28
    var iconSize: CGFloat = 13
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: iconSize, weight: .medium))
                .foregroundStyle(isHovered ? Color.primary : Color.secondary)
                .frame(width: size, height: size)
                .background {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(
                            isHovered
                                ? Color.primary.opacity(0.1)
                                : Color.primary.opacity(0.05)
                        )
                }
        }
        .buttonStyle(.plain)
        .focusable(false)
        .onHover { isHovered = $0 }
        .help(help)
    }
}
