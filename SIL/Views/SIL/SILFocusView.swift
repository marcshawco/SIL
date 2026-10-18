//
//  SILFocusView.swift
//  SIL
//
//  The Focus tab — what used to be Training.
//
//  Idle, the screen is a 300pt dial of tick marks with the duration in the
//  middle; you set the length, pick what it builds, name it, and start.
//  Running, the same dial empties anticlockwise while the clock counts down.
//  There is no dungeon, no raid, no failure state dressed up as a monster —
//  ending early just keeps partial credit.
//

import SwiftUI

struct SILFocusView: View {
    @EnvironmentObject private var gameEngine: GameEngine
    @ObservedObject private var training = TrainingManager.shared

    @Environment(\.scenePhase) private var phase
    @AppStorage("sil.focus.minutes") private var minutes: Int = 25
    @AppStorage("sil.focus.attribute") private var attributeRaw: String = SILAttribute.mind.rawValue
    @State private var label: String = ""

    private let presets = [15, 25, 45, 60, 90]

    private var attribute: SILAttribute {
        SILAttribute(rawValue: attributeRaw) ?? .mind
    }

    var body: some View {
        SILScreen(spacing: 18) {
            if training.isActive {
                runningContent
            } else {
                idleContent
            }
        }
        .onChange(of: phase) { _, newPhase in
            // Leaving the app mid-session abandons it. Pausing first is the
            // way out that keeps what you earned.
            if newPhase == .background && training.isActive && !training.isPaused {
                training.failForAppExit()
            }
        }
    }

    // MARK: - Idle

    @ViewBuilder private var idleContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Deep work · one thing at a time").silEyebrow()
            Text(SILWord.focus).silTitle()
        }
        .padding(.top, 6)

        Text("One thing, properly. Phone face down.")
            .font(S.text(17))
            .foregroundStyle(S.ink2)

        SILFocusDial(progress: 1) {
            VStack(spacing: 6) {
                Text("\(minutes)").silNumeral(104)
                Text("minutes")
                    .font(S.text(15))
                    .foregroundStyle(S.ink2)
            }
        }
        .frame(width: 300, height: 300)
        .frame(maxWidth: .infinity)

        HStack(spacing: 6) {
            SILRoundButton(systemImage: "minus", size: 44) {
                minutes = max(5, minutes - 5)
            }
            Spacer(minLength: 0)
            ForEach(presets, id: \.self) { preset in
                Button {
                    minutes = preset
                } label: {
                    Text("\(preset)")
                        .font(S.text(15, .medium))
                        .foregroundStyle(minutes == preset ? S.onInv : S.ink2)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(minutes == preset ? S.inv : S.card2))
                }
                .buttonStyle(.plain)
                Spacer(minLength: 0)
            }
            SILRoundButton(systemImage: "plus", size: 44) {
                minutes = min(180, minutes + 5)
            }
        }

        HStack(spacing: 6) {
            ForEach(SILAttribute.allCases) { option in
                SILAttributeChip(attribute: option, selected: option == attribute) {
                    attributeRaw = option.rawValue
                }
            }
        }

        TextField("What are you working on?", text: $label)
            .font(S.text(16))
            .foregroundStyle(S.ink)
            .padding(.horizontal, 20)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(S.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(S.line, lineWidth: 1)
                    )
            )

        Text(rewardLine)
            .silEyebrow()
            .frame(maxWidth: .infinity, alignment: .center)

        SILPrimaryButton(title: "Start focus", accented: true) {
            start()
        }
    }

    private var rewardLine: String {
        let xp = max(10, (minutes / 15) * 10)
        let credits = max(5, (minutes / 15) * 5)
        return "\(SILFormat.points(xp)) \(SILWord.progress) · \(SILFormat.points(credits)) \(SILWord.creditsShort) · \(attribute.name)"
    }

    private func start() {
        training.focusStat = attribute.primaryStat
        let title = label.trimmingCharacters(in: .whitespacesAndNewlines)
        training.startSession(minutes: minutes, title: title.isEmpty ? "Focus" : title)
    }

    // MARK: - Running

    @ViewBuilder private var runningContent: some View {
        HStack {
            HStack(spacing: 10) {
                Circle()
                    .fill(training.isPaused ? S.ink3 : S.accent)
                    .frame(width: 7, height: 7)
                Text("\(training.isPaused ? "Held" : "Running") · \(attribute.name)")
                    .font(S.mono(10))
                    .tracking(0.6)
                    .textCase(.uppercase)
                    .foregroundStyle(S.ink)
            }
            Spacer()
            SILGhostButton(title: "End early", height: 44) {
                training.complete()
            }
        }
        .padding(.top, 4)

        VStack(alignment: .leading, spacing: 6) {
            Text(training.sessionTitle)
                .font(S.display(30, .semibold))
                .tracking(S.displayTracking(30))
                .foregroundStyle(S.ink)
            Text("\(SILFormat.percent(training.progress)) through · \(training.formattedElapsedTime) elapsed")
                .font(S.text(15))
                .foregroundStyle(S.ink2)
        }

        SILFocusDial(progress: 1 - training.progress, dimmed: training.isPaused) {
            VStack(spacing: 8) {
                Text(training.formattedTimeRemaining).silNumeral(72)
                Text("Remaining").silEyebrow()
            }
        }
        .frame(width: 300, height: 300)
        .frame(maxWidth: .infinity)

        HStack(spacing: 12) {
            earnedCard(SILWord.progress, SILFormat.points(earnedProgress))
            earnedCard("\(SILWord.credits) so far", SILFormat.points(earnedCredits))
        }

        HStack(spacing: 14) {
            Button {
                training.isPaused ? training.resume() : training.pause()
            } label: {
                Image(systemName: training.isPaused ? "play.fill" : "pause.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(S.onInv)
                    .frame(width: 52, height: 52)
                    .background(Circle().fill(S.inv))
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(training.isPaused ? "Held" : "Running")
                    .font(S.text(17, .medium))
                    .foregroundStyle(S.ink)
                Text("Ending early keeps partial credit")
                    .font(S.text(13))
                    .foregroundStyle(S.ink2)
            }
            Spacer(minLength: 0)
        }
        .padding(.leading, 16)
        .padding([.trailing, .vertical], 12)
        .background(
            RoundedRectangle(cornerRadius: S.R.card, style: .continuous).fill(S.card2)
        )
    }

    private var earnedProgress: Int {
        Int(Double(training.xpReward) * training.progress)
    }

    private var earnedCredits: Int {
        Int(Double(training.goldReward) * training.progress)
    }

    private func earnedCard(_ label: String, _ value: String) -> some View {
        SILCard(radius: 24, padding: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text(label).silEyebrow()
                Text(value).silNumeral(32)
            }
        }
    }
}

// MARK: - Dial

/// 60 tick marks around a circle. Ticks inside the progress arc are at full
/// strength, the rest fade back — a clock face, not a progress ring.
struct SILFocusDial<Center: View>: View {
    var progress: Double
    var dimmed: Bool = false
    var tickCount: Int = 60
    @ViewBuilder var center: () -> Center

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let mid = CGPoint(x: side / 2, y: side / 2)
            let outer = side / 2 - 4
            let lit = Int((Double(tickCount) * max(0, min(1, progress))).rounded())

            ZStack {
                Canvas { context, _ in
                    for index in 0..<tickCount {
                        let major = index % 5 == 0
                        let angle = Angle.degrees(Double(index) / Double(tickCount) * 360 - 90)
                        let inner = outer - (major ? 18 : 11)
                        let start = CGPoint(
                            x: mid.x + cos(angle.radians) * inner,
                            y: mid.y + sin(angle.radians) * inner
                        )
                        let end = CGPoint(
                            x: mid.x + cos(angle.radians) * outer,
                            y: mid.y + sin(angle.radians) * outer
                        )
                        var path = Path()
                        path.move(to: start)
                        path.addLine(to: end)

                        let on = index < lit
                        context.stroke(
                            path,
                            with: .color(S.ink.opacity(on ? (major ? 1 : 0.72) : 0.16)),
                            style: StrokeStyle(lineWidth: major ? 2.4 : 1.4, lineCap: .round)
                        )
                    }
                }
                .frame(width: side, height: side)

                center()
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .opacity(dimmed ? 0.45 : 1)
            .animation(.easeOut(duration: 0.4), value: lit)
            .animation(.easeOut(duration: 0.25), value: dimmed)
        }
    }
}
