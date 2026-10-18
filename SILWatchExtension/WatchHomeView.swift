import SwiftUI

//  The watch face of SIL. Monochrome like everything else — on a small, often
//  glanced-at screen, hue carries no meaning the shape doesn't already give.
//  `.cyan`, `.yellow`, `.red` and `.green` all become primary or secondary.

struct WatchHomeView: View {
    @EnvironmentObject private var sessionStore: WatchSessionStore

    var body: some View {
        NavigationStack {
            Group {
                if let snapshot = sessionStore.snapshot {
                    List {
                        Section {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(snapshot.playerName)
                                        .font(.headline)
                                    Spacer()
                                    Text("Lvl \(snapshot.level)")
                                        .font(.subheadline.monospacedDigit())
                                        .foregroundStyle(.primary)
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    ProgressView(
                                        value: Double(snapshot.currentXP),
                                        total: Double(max(snapshot.xpRequiredForNextLevel, 1))
                                    )
                                    .tint(.primary)

                                    Text("\(snapshot.currentXP)/\(snapshot.xpRequiredForNextLevel) progress")
                                        .font(.caption2.monospacedDigit())
                                        .foregroundStyle(.secondary)
                                }

                                HStack(spacing: 10) {
                                    Label("\(snapshot.gold) CR", systemImage: "circle.dotted")
                                        .font(.caption2.monospacedDigit())
                                        .foregroundStyle(.secondary)
                                    Label("\(snapshot.currentHP)", systemImage: "chart.line.uptrend.xyaxis")
                                        .font(.caption2.monospacedDigit())
                                        .foregroundStyle(.secondary)
                                }

                                Text("\(snapshot.completedToday) of \(snapshot.totalQuests) habits done today")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Section("Habits") {
                            ForEach(snapshot.quests) { quest in
                                WatchHabitRow(
                                    quest: quest,
                                    isPending: sessionStore.pendingCompletionQuestIDs.contains(quest.id),
                                    onComplete: {
                                        sessionStore.completeQuest(quest)
                                    }
                                )
                            }
                        }
                    }
                    .listStyle(.carousel)
                } else {
                    VStack(spacing: 8) {
                        ProgressView()
                            .tint(.primary)
                        Text("Waiting for sync")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("SIL")
            .toolbar {
                ToolbarItem {
                    Button {
                        sessionStore.refreshSnapshot()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Text(statusLine)
                    .font(.caption2)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.bottom, 2)
            }
            .task {
                sessionStore.refreshSnapshot()
            }
        }
    }

    private var statusLine: String {
        if let lastSync = sessionStore.lastSyncDate {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .short
            let relative = formatter.localizedString(for: lastSync, relativeTo: Date())
            return "\(sessionStore.statusMessage) Last sync \(relative)."
        }

        return sessionStore.statusMessage
    }
}

private struct WatchHabitRow: View {
    let quest: WatchQuestSnapshotItem
    let isPending: Bool
    let onComplete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(quest.title)
                    .font(.body.weight(.semibold))
                    .strikethrough(quest.isCompleted)
                    .lineLimit(2)

                Spacer(minLength: 8)

                completionControl
            }

            if !quest.subtitle.isEmpty {
                Text(quest.subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            if quest.targetValue > 0 {
                ProgressView(value: quest.progressFraction)
                    .tint(quest.isCompleted ? .secondary : .primary)
                Text(quest.progressText)
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 8) {
                Label("\(quest.xpReward)", systemImage: "plus")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
                Label("\(quest.goldReward) CR", systemImage: "circle.dotted")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
                Text(quest.trackingType.capitalized)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var completionControl: some View {
        if quest.isCompleted {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.primary)
        } else if isPending {
            ProgressView()
                .tint(.primary)
                .scaleEffect(0.75)
        } else {
            Button {
                onComplete()
            } label: {
                Image(systemName: "circle")
                    .foregroundStyle(.primary)
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview {
    WatchHomeView()
        .environmentObject(WatchSessionStore())
}
