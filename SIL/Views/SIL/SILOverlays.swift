//
//  SILOverlays.swift
//  SIL
//
//  The three moments the app interrupts you: a habit closed, a level reached,
//  and momentum running out.
//
//  All three used to be celebrations or punishments with particle effects and
//  rank sigils. Here they are statements of fact. The completion card lands
//  from the bottom and can be undone; the level screen is a full page of
//  typography; the recalibration card explains what it cost and lets you
//  start again.
//

import SwiftUI

// MARK: - Completion

/// What a finished habit was worth. Rises from the bottom over a scrim and
/// dismisses on tap, with Undo available while the engine still allows it.
struct SILCompletionOverlay: View {
    let title: String
    let headline: String
    let progress: Int
    let credits: Int
    let attribute: SILAttribute
    let attributeGain: Int
    let goalNote: String?
    let note: String
    var canUndo: Bool
    var onUndo: () -> Void
    var onContinue: () -> Void

    @State private var shown = false

    var body: some View {
        ZStack(alignment: .bottom) {
            S.scrim
                .ignoresSafeArea()
                .opacity(shown ? 1 : 0)
                .onTapGesture(perform: onContinue)

            VStack(spacing: 18) {
                ZStack {
                    Circle().fill(S.inv)
                    Image(systemName: "checkmark")
                        .font(.system(size: 38, weight: .medium))
                        .foregroundStyle(S.onInv)
                }
                .frame(width: 92, height: 92)

                VStack(spacing: 6) {
                    Text(headline)
                        .font(S.display(36, .semibold))
                        .tracking(S.displayTracking(36))
                        .foregroundStyle(S.ink)
                    Text(title)
                        .font(S.text(17))
                        .foregroundStyle(S.ink2)
                        .multilineTextAlignment(.center)
                }

                SILStatStrip(
                    cells: [
                        .init(SILWord.progress, SILFormat.points(progress)),
                        .init(SILWord.credits, SILFormat.points(credits)),
                        .init(attribute.name, SILFormat.points(attributeGain), accented: true)
                    ],
                    valueFirst: true
                )

                if let goalNote {
                    Text("→ \(goalNote)")
                        .font(S.mono(9.5))
                        .tracking(0.4)
                        .textCase(.uppercase)
                        .foregroundStyle(S.accentInk)
                }

                Text(note)
                    .font(S.text(15))
                    .foregroundStyle(S.ink2)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 10) {
                    if canUndo {
                        SILGhostButton(title: "Undo", height: 54, action: onUndo)
                    }
                    SILPrimaryButton(title: "Continue", action: onContinue)
                        .frame(height: 54)
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 30)
            .padding(.bottom, 18)
            .background(
                RoundedRectangle(cornerRadius: S.R.overlay, style: .continuous)
                    .fill(S.bg2)
                    .overlay(
                        RoundedRectangle(cornerRadius: S.R.overlay, style: .continuous)
                            .strokeBorder(S.line, lineWidth: 1)
                    )
                    .shadow(color: S.shadowColor, radius: S.shadowRadius, y: S.shadowY)
            )
            .padding(.horizontal, 12)
            .padding(.bottom, 22)
            .offset(y: shown ? 0 : 40)
            .opacity(shown ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.36, dampingFraction: 0.86)) { shown = true }
        }
    }
}

// MARK: - Level up

/// A full page rather than a modal. Old level on the left, new level large on
/// the right, then what it changed. No rank badge, no fanfare.
struct SILLevelUpOverlay: View {
    let data: LevelUpData
    let totalHabits: Int
    var onContinue: () -> Void

    @State private var shown = false

    var body: some View {
        ZStack {
            S.bg.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("SIL · Level")
                        .font(S.mono(10))
                        .tracking(0.6)
                        .textCase(.uppercase)
                        .foregroundStyle(S.ink)
                    Spacer()
                    Text(Date(), format: .dateTime.hour().minute())
                        .font(S.mono(10))
                        .tracking(0.6)
                        .foregroundStyle(S.ink3)
                }

                Spacer()

                VStack(alignment: .leading, spacing: 22) {
                    HStack(alignment: .bottom, spacing: 16) {
                        Text("\(data.previousLevel)")
                            .font(S.display(84, .regular))
                            .tracking(S.displayTracking(84))
                            .foregroundStyle(S.ink3)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 28, weight: .light))
                            .foregroundStyle(S.ink3)
                            .padding(.bottom, 14)
                        Text("\(data.newLevel)")
                            .font(S.display(150, .medium))
                            .tracking(S.displayTracking(150))
                            .foregroundStyle(S.ink)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("You've moved up.")
                            .font(S.display(36, .semibold))
                            .tracking(S.displayTracking(36))
                            .foregroundStyle(S.ink)
                        Text("\(SILFormat.number(totalHabits)) habits got you here. Same rhythm from here.")
                            .font(S.text(17))
                            .foregroundStyle(S.ink2)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    VStack(spacing: 0) {
                        ForEach(unlocks, id: \.key) { unlock in
                            HStack(alignment: .firstTextBaseline, spacing: 14) {
                                Text(unlock.key)
                                    .silEyebrow()
                                    .frame(width: 78, alignment: .leading)
                                Text(unlock.value)
                                    .font(S.text(16))
                                    .foregroundStyle(S.ink)
                                Spacer(minLength: 0)
                            }
                            .padding(.vertical, 13)
                            .overlay(alignment: .top) {
                                Rectangle().fill(S.line).frame(height: 1)
                            }
                        }
                    }
                }
                .scaleEffect(shown ? 1 : 0.96, anchor: .leading)

                Spacer()

                SILPrimaryButton(title: "Continue", action: onContinue)
            }
            .padding(.horizontal, 24)
            .padding(.top, 70)
            .padding(.bottom, 40)
            .opacity(shown ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.9)) { shown = true }
        }
    }

    private var unlocks: [(key: String, value: String)] {
        // SIL has no rank badges, so a rank-up reads as a wider ceiling
        // rather than a new title.
        var rows: [(String, String)] = [
            ("Level", "\(data.newLevel)"),
            ("Momentum", data.rankUp ? "Ceiling raised" : "Unchanged")
        ]
        if !data.statsUnlocked.isEmpty {
            let names = Set(data.statsUnlocked.map { SILAttribute.containing($0).name })
            rows.append(("Attributes", names.sorted().joined(separator: ", ")))
        }
        return rows
    }
}

// MARK: - Recalibration

/// Momentum ran out. States what it cost and offers one way forward.
struct SILRecalibrationOverlay: View {
    let summary: DeathPenaltySummary
    let momentum: Int
    let level: Int
    let credits: Int
    var onDismiss: () -> Void

    @State private var shown = false

    var body: some View {
        ZStack(alignment: .bottom) {
            S.scrim
                .ignoresSafeArea()
                .opacity(shown ? 1 : 0)
                .onTapGesture(perform: onDismiss)

            VStack(alignment: .leading, spacing: 18) {
                Text("\(SILWord.recalibration) · \(summary.missedQuestCount) missed")
                    .font(S.mono(10))
                    .tracking(0.6)
                    .textCase(.uppercase)
                    .foregroundStyle(S.accentInk)

                Text("Momentum ran out. That's allowed.")
                    .font(S.display(32, .semibold))
                    .tracking(S.displayTracking(32))
                    .foregroundStyle(S.ink)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Missed habits drained the meter. SIL resets it rather than wiping your history. Start again today.")
                    .font(S.text(15))
                    .foregroundStyle(S.ink2)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(spacing: 0) {
                    row(SILWord.momentum, "\(momentum)")
                    row("Level", "\(level)")
                    row(SILWord.credits, summary.goldLost > 0
                        ? "\(SILFormat.number(credits)) · \(SILFormat.number(summary.goldLost)) given up"
                        : SILFormat.number(credits))
                    row("Attributes", summary.statLosses.isEmpty
                        ? "Unchanged"
                        : "Eased back \(summary.statLossPercent)%")
                }

                Text("Change what a recalibration costs in Settings → Momentum.")
                    .font(S.text(13))
                    .foregroundStyle(S.ink3)

                SILPrimaryButton(title: "Start again today", action: onDismiss)
                    .frame(height: 54)
            }
            .padding(.horizontal, 22)
            .padding(.top, 28)
            .padding(.bottom, 18)
            .background(
                RoundedRectangle(cornerRadius: S.R.overlay, style: .continuous)
                    .fill(S.bg2)
                    .overlay(
                        RoundedRectangle(cornerRadius: S.R.overlay, style: .continuous)
                            .strokeBorder(S.line, lineWidth: 1)
                    )
                    .shadow(color: S.shadowColor, radius: S.shadowRadius, y: S.shadowY)
            )
            .padding(.horizontal, 12)
            .padding(.bottom, 22)
            .offset(y: shown ? 0 : 40)
            .opacity(shown ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.36, dampingFraction: 0.86)) { shown = true }
        }
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 14) {
            Text(label)
                .silEyebrow()
                .frame(width: 96, alignment: .leading)
            Text(value)
                .font(S.text(16))
                .foregroundStyle(S.ink)
            Spacer(minLength: 0)
        }
        .padding(.vertical, 12)
        .overlay(alignment: .top) {
            Rectangle().fill(S.line).frame(height: 1)
        }
    }
}
