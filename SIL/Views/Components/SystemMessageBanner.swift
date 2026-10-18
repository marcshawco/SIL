//
//  SystemMessageBanner.swift
//  SIL
//
//  [SYSTEM]: Communication relay initialized.
//  In-app notifications flow through this conduit.
//

import SwiftUI

// MARK: - System Message

/// A system notification displayed as an in-app banner
struct SystemMessage: Identifiable, Equatable {
    let id = UUID()
    let type: MessageType
    let title: String
    let message: String
    let duration: TimeInterval

    init(type: MessageType, title: String, message: String, duration: TimeInterval = 4.0) {
        self.type = type
        self.title = title
        self.message = message
        self.duration = duration
    }

    // MARK: - Message Types

    enum MessageType: String {
        case info = "Info"
        case success = "Success"
        case warning = "Warning"
        case critical = "Critical"
        case levelUp = "Level Up"
        case questComplete = "Habit Done"

        /// Only a genuine problem gets a colour. Everything else is ink.
        var color: Color {
            switch self {
            case .warning, .critical: return S.warn
            default:                  return S.ink
            }
        }

        var icon: String {
            switch self {
            case .info:          return "info.circle"
            case .success:       return "checkmark.circle"
            case .warning:       return "exclamationmark.circle"
            case .critical:      return "exclamationmark.triangle"
            case .levelUp:       return "arrow.up.circle"
            case .questComplete: return "checkmark.circle"
            }
        }
    }

    // MARK: - Static Helpers

    static func questCompleted(title: String, xp: Int, gold: Int) -> SystemMessage {
        let detail = gold > 0
            ? "\(title) · +\(xp) progress, +\(gold) CR"
            : "\(title) · +\(xp) progress"
        return SystemMessage(
            type: .questComplete,
            title: "Done",
            message: detail
        )
    }

    static func levelUp(level: Int, rank: String) -> SystemMessage {
        SystemMessage(
            type: .levelUp,
            title: "Level \(level)",
            message: "You've moved up. Same rhythm from here.",
            duration: 6.0
        )
    }

    static func warning(_ message: String) -> SystemMessage {
        SystemMessage(type: .warning, title: "Warning", message: message)
    }

    static func info(_ title: String, _ message: String) -> SystemMessage {
        SystemMessage(type: .info, title: title, message: message)
    }
}

// MARK: - System Message Banner View

/// A quiet banner for in-app notices. Drops in under the status bar, states
/// one thing, and leaves.
struct SystemMessageBanner: View {

    let message: SystemMessage
    let onDismiss: () -> Void

    @State private var opacity: Double = 0
    @State private var offsetY: CGFloat = -100
    @State private var dismissTask: Task<Void, Never>?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: message.type.icon)
                .font(.system(size: 20, weight: .regular))
                .foregroundStyle(message.type.color)

            VStack(alignment: .leading, spacing: 2) {
                Text(message.title)
                    .font(S.text(15, .semibold))
                    .foregroundStyle(S.ink)

                Text(message.message)
                    .font(S.text(13))
                    .foregroundStyle(S.ink2)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)

            Button {
                dismissBanner()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(S.ink3)
                    .padding(8)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background {
            let shape = RoundedRectangle(cornerRadius: 22, style: .continuous)
            shape
                .fill(S.bg2)
                .overlay(shape.strokeBorder(S.line, lineWidth: 1))
                .shadow(color: S.shadowColor.opacity(0.5), radius: 20, y: 8)
        }
        .padding(.horizontal, 14)
        .padding(.top, 8)
        .offset(y: offsetY)
        .opacity(opacity)
        .onAppear {
            // Animate in
            withAnimation(.easeOut(duration: 0.2)) {
                opacity = 1
                offsetY = 0
            }

            // Schedule auto-dismiss
            dismissTask = Task {
                try? await Task.sleep(nanoseconds: UInt64(message.duration * 1_000_000_000))
                if !Task.isCancelled {
                    await MainActor.run {
                        dismissBanner()
                    }
                }
            }
        }
        .onDisappear {
            dismissTask?.cancel()
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.height < -20 {
                        dismissBanner()
                    }
                }
        )
    }

    private func dismissBanner() {
        dismissTask?.cancel()
        withAnimation(.easeOut(duration: 0.25)) {
            opacity = 0
            offsetY = -100
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss()
        }
    }
}

// MARK: - View Extension

extension View {
    /// Displays system messages as banners
    func systemMessage(_ message: Binding<SystemMessage?>) -> some View {
        ZStack(alignment: .top) {
            self

            if let msg = message.wrappedValue {
                SystemMessageBanner(message: msg) {
                    message.wrappedValue = nil
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
}

// MARK: - System Message Helper

/// Helper class to post system messages from anywhere
class SystemMessageHelper {
    static func show(_ message: SystemMessage) {
        NotificationCenter.default.post(
            name: .showSystemMessage,
            object: message
        )
    }

    static func showQuestComplete(title: String, xp: Int, gold: Int) {
        show(.questCompleted(title: title, xp: xp, gold: gold))
    }

    static func showLevelUp(level: Int, rank: String) {
        show(.levelUp(level: level, rank: rank))
    }

    static func showWarning(_ message: String) {
        show(.warning(message))
    }

    static func showInfo(_ title: String, _ message: String) {
        show(.info(title, message))
    }
}

// MARK: - Preview

#Preview("Info Banner") {
    ZStack {
        S.bg.ignoresSafeArea()

        VStack {
            SystemMessageBanner(
                message: .info("Training Complete", "You have completed a 25-minute focus session. +50 XP")
            ) {}

            Spacer()
        }
    }
}

#Preview("Level Up Banner") {
    ZStack {
        S.bg.ignoresSafeArea()

        VStack {
            SystemMessageBanner(
                message: .levelUp(level: 25, rank: "C-Rank Hunter")
            ) {}

            Spacer()
        }
    }
}
