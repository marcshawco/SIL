//
//  SILWidgets.swift
//  SILWidgets
//

import SwiftUI
import WidgetKit
import AppIntents
import UIKit

/// The SIL palette, mirrored for the widget target.
///
/// Widgets are a separate binary and cannot see `SILTheme.swift`, so the token
/// values are repeated here. Keep them in step with `S` — the hexes are the
/// same ones the app uses. The old names are kept so the widget views below
/// did not all have to be rewritten at once; everything that used to carry a
/// hue now resolves to ink.
///
/// Widgets stay monochrome. The accent lives in app `UserDefaults`, which the
/// widget cannot read, and a Home Screen tile reads better in ink anyway.
private enum WidgetTheme {
    private static func hex(_ value: UInt32) -> UIColor {
        UIColor(
            red: CGFloat((value >> 16) & 0xFF) / 255,
            green: CGFloat((value >> 8) & 0xFF) / 255,
            blue: CGFloat(value & 0xFF) / 255,
            alpha: 1
        )
    }

    private static func adaptive(light: UInt32, dark: UInt32) -> Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark ? hex(dark) : hex(light)
        })
    }

    private static func mono(light: Double, dark: Double) -> Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(white: 1, alpha: dark)
                : UIColor(white: 0, alpha: light)
        })
    }

    // Surfaces
    static let backgroundPrimary   = adaptive(light: 0xEDEDEB, dark: 0x0A0A0C)
    static let backgroundSecondary = adaptive(light: 0xF8F8F7, dark: 0x16161A)
    static let backgroundTertiary  = adaptive(light: 0xE1E1DF, dark: 0x222227)

    // Ink
    static let textPrimary   = adaptive(light: 0x0E0E10, dark: 0xF4F4F5)
    static let textSecondary = adaptive(light: 0x52525A, dark: 0xA6A6AE)
    static let textTertiary  = adaptive(light: 0x66666E, dark: 0x84848D)

    static let line = mono(light: 0.06, dark: 0.07)
    static let track = mono(light: 0.13, dark: 0.14)

    // Former accents — all ink now, except the one loss state.
    static let primaryBlue   = textPrimary
    static let primaryPurple = textPrimary
    static let accentCyan    = textPrimary
    static let successGreen  = textPrimary
    static let gold          = textPrimary
    static let warningOrange = textSecondary
    static let criticalRed   = adaptive(light: 0xB3401F, dark: 0xE2714E)

    // Progress fills are flat ink on a hairline track, not two-stop ramps.
    static let xpGradient = LinearGradient(
        colors: [textPrimary, textPrimary],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let hpGradient = LinearGradient(
        colors: [textPrimary, textPrimary],
        startPoint: .leading,
        endPoint: .trailing
    )

    // MARK: Type
    //
    // The widget bundles Schibsted Grotesk (Regular/Medium/SemiBold) and
    // Martian Mono Regular — the subset these tiles use. Lock Screen
    // accessories keep the system face, which is what Apple renders them with.

    private static func face(_ name: String, _ size: CGFloat, _ fallback: Font) -> Font {
        UIFont(name: name, size: size) == nil ? fallback : .custom(name, size: size)
    }

    static func text(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        let name: String
        switch weight {
        case .semibold, .bold, .heavy, .black: name = "SchibstedGrotesk-SemiBold"
        case .medium:                          name = "SchibstedGrotesk-Medium"
        default:                               name = "SchibstedGrotesk-Regular"
        }
        return face(name, size, .system(size: size, weight: weight))
    }

    static func mono(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        face("MartianMono-Regular", size, .system(size: size, weight: weight, design: .monospaced))
    }

    static func cardBackground(accent: Color = textPrimary) -> some View {
        LinearGradient(
            colors: [backgroundSecondary, backgroundPrimary],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

private enum WidgetLanguageSupport {
    static let appGroupID = "group.com.gamelife.shared"
    static let preferredLanguageFileName = "preferredLanguageCode.txt"

    static var locale: Locale {
        Locale(identifier: resolvedLanguageCode)
    }

    private static var resolvedLanguageCode: String {
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else {
            return Locale.autoupdatingCurrent.language.languageCode?.identifier ?? "en"
        }

        let preferenceURL = containerURL.appendingPathComponent(preferredLanguageFileName)
        let code = (try? String(contentsOf: preferenceURL, encoding: .utf8))?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !code.isEmpty, code != "system" else {
            return Locale.autoupdatingCurrent.language.languageCode?.identifier ?? "en"
        }
        let normalized = code.split(whereSeparator: { $0 == "-" || $0 == "_" }).first.map(String.init) ?? code
        return normalized.isEmpty ? "en" : normalized
    }
}

struct SILWidgetEntry: TimelineEntry {
    let date: Date
    let payload: WidgetSnapshotPayload
}

struct SILBossWidgetEntry: TimelineEntry {
    let date: Date
    let payload: WidgetSnapshotPayload
    let selectedBoss: WidgetBossSummary?
}

struct SILTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> SILWidgetEntry {
        SILWidgetEntry(date: Date(), payload: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (SILWidgetEntry) -> Void) {
        completion(SILWidgetEntry(date: Date(), payload: WidgetSnapshotLoader.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SILWidgetEntry>) -> Void) {
        let entry = SILWidgetEntry(date: Date(), payload: WidgetSnapshotLoader.load())
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date().addingTimeInterval(900)
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }
}

struct WidgetBossEntity: AppEntity, Identifiable {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Boss")
    static var defaultQuery = WidgetBossEntityQuery()

    let id: String
    let title: String
    let subtitle: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: LocalizedStringResource(stringLiteral: title),
            subtitle: LocalizedStringResource(stringLiteral: subtitle)
        )
    }
}

struct WidgetBossEntityQuery: EntityQuery {
    func entities(for identifiers: [WidgetBossEntity.ID]) async throws -> [WidgetBossEntity] {
        let all = currentEntities()
        let requested = Set(identifiers)
        return all.filter { requested.contains($0.id) }
    }

    func suggestedEntities() async throws -> [WidgetBossEntity] {
        currentEntities()
    }

    private func currentEntities() -> [WidgetBossEntity] {
        WidgetSnapshotLoader.load().bosses.map { boss in
            WidgetBossEntity(
                id: boss.id.uuidString,
                title: boss.title,
                subtitle: boss.subtitle
            )
        }
    }
}

struct BossWidgetConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Boss Widget"
    static var description = IntentDescription("Choose which boss this widget should track.")

    @Parameter(title: "Boss")
    var boss: WidgetBossEntity?
}

struct SILBossTimelineProvider: AppIntentTimelineProvider {
    typealias Entry = SILBossWidgetEntry
    typealias Intent = BossWidgetConfigurationIntent

    func placeholder(in context: Context) -> SILBossWidgetEntry {
        let payload = WidgetSnapshotPayload.placeholder
        return SILBossWidgetEntry(
            date: Date(),
            payload: payload,
            selectedBoss: payload.primaryBoss
        )
    }

    func snapshot(for configuration: BossWidgetConfigurationIntent, in context: Context) async -> SILBossWidgetEntry {
        let payload = WidgetSnapshotLoader.load()
        return SILBossWidgetEntry(
            date: Date(),
            payload: payload,
            selectedBoss: selectedBoss(from: payload, configuration: configuration)
        )
    }

    func timeline(for configuration: BossWidgetConfigurationIntent, in context: Context) async -> Timeline<SILBossWidgetEntry> {
        let payload = WidgetSnapshotLoader.load()
        let entry = SILBossWidgetEntry(
            date: Date(),
            payload: payload,
            selectedBoss: selectedBoss(from: payload, configuration: configuration)
        )
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date().addingTimeInterval(900)
        return Timeline(entries: [entry], policy: .after(nextRefresh))
    }

    private func selectedBoss(from payload: WidgetSnapshotPayload, configuration: BossWidgetConfigurationIntent) -> WidgetBossSummary? {
        guard let selectedID = configuration.boss?.id else {
            return payload.primaryBoss
        }
        return payload.bosses.first(where: { $0.id.uuidString == selectedID }) ?? payload.primaryBoss
    }
}

struct StatusWidgetView: View {
    let entry: SILWidgetEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            switch family {
            case .accessoryRectangular:
                accessoryBody
            case .accessoryCircular:
                circularAccessoryBody
            case .accessoryInline:
                inlineAccessoryBody
            default:
                defaultBody
            }
        }
        .environment(\.locale, WidgetLanguageSupport.locale)
        .widgetURL(URL(string: "sil://status"))
    }

    private var defaultBody: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.payload.playerName)
                        .font(WidgetTheme.text(17, .semibold))
                        .lineLimit(1)
                    Text("Level \(entry.payload.level)")
                        .font(WidgetTheme.text(12))
                        .foregroundStyle(WidgetTheme.textSecondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(entry.payload.streak)d")
                        .font(WidgetTheme.mono(11))
                        .foregroundStyle(WidgetTheme.textSecondary)
                    Text("\(entry.payload.gold) CR")
                        .font(WidgetTheme.mono(11))
                        .foregroundStyle(WidgetTheme.textSecondary)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                metricRow(title: "Momentum", value: "\(entry.payload.currentHP)")
                ProgressView(value: Double(entry.payload.currentHP), total: Double(max(1, entry.payload.maxHP)))
                    // Ink while the meter is healthy; the one warn colour only
                    // once it is genuinely running down.
                    .tint(momentumShare < 0.25 ? WidgetTheme.criticalRed : WidgetTheme.textPrimary)
            }

            VStack(alignment: .leading, spacing: 4) {
                metricRow(title: "Progress", value: "\(Int((entry.payload.xpProgress * 100).rounded()))%")
                ProgressView(value: entry.payload.xpProgress)
                    .tint(WidgetTheme.textPrimary)
            }

            Spacer(minLength: 0)

            Text("\(entry.payload.completedToday) of \(entry.payload.totalToday) habits done")
                .font(WidgetTheme.text(11))
                .foregroundStyle(WidgetTheme.textSecondary)
        }
        .foregroundStyle(WidgetTheme.textPrimary)
        .containerBackground(for: .widget) {
            WidgetTheme.cardBackground(accent: WidgetTheme.primaryBlue)
        }
    }

    private var accessoryBody: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Level \(entry.payload.level)")
                .font(WidgetTheme.text(12))
                .bold()
            Text("Momentum \(entry.payload.currentHP)")
                .font(WidgetTheme.text(11))
            Text("\(entry.payload.completedToday)/\(entry.payload.totalToday) done")
                .font(WidgetTheme.text(11))
                .foregroundStyle(WidgetTheme.textSecondary)
        }
        .foregroundStyle(WidgetTheme.textPrimary)
    }

    private var momentumShare: Double {
        Double(entry.payload.currentHP) / Double(max(1, entry.payload.maxHP))
    }

    private func metricRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(WidgetTheme.text(11))
                .foregroundStyle(WidgetTheme.textSecondary)
            Spacer()
            Text(value)
                .font(WidgetTheme.text(11))
                .bold()
        }
    }

    /// Lock screen circular: quest completion ring for today.
    private var circularAccessoryBody: some View {
        Gauge(value: Double(entry.payload.completedToday), in: 0...Double(max(1, entry.payload.totalToday))) {
            Text("Lvl \(entry.payload.level)")
                .font(.system(size: 9, weight: .semibold))
        } currentValueLabel: {
            Text("\(entry.payload.completedToday)/\(entry.payload.totalToday)")
                .font(.system(size: 12, weight: .bold))
        }
        .gaugeStyle(.accessoryCircular)
        .foregroundStyle(WidgetTheme.textPrimary)
    }

    /// Lock screen inline: one-line streak and quest summary.
    private var inlineAccessoryBody: some View {
        Text("\(entry.payload.completedToday)/\(entry.payload.totalToday) habits · \(entry.payload.streak)d streak")
    }
}

struct NextUpWidgetView: View {
    let entry: SILWidgetEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Next up")
                        .font(WidgetTheme.text(17, .semibold))
                    Text("\(entry.payload.remainingRequired) required left")
                        .font(WidgetTheme.text(12))
                        .foregroundStyle(WidgetTheme.textSecondary)
                }
                Spacer()
                Text("\(entry.payload.completedToday)/\(max(1, entry.payload.totalToday))")
                    .font(WidgetTheme.mono(20, .medium))
            }

            ForEach(displayedQuests) { quest in
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(quest.title)
                            .font(WidgetTheme.text(15, .semibold))
                            .lineLimit(1)
                        if quest.isOptional {
                            Text("Optional")
                                .font(WidgetTheme.text(11, .semibold))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .foregroundStyle(WidgetTheme.accentCyan)
                                .background(WidgetTheme.accentCyan.opacity(0.14))
                                .clipShape(Capsule())
                        }
                    }
                    Text(quest.subtitle)
                        .font(WidgetTheme.text(11))
                        .foregroundStyle(WidgetTheme.textSecondary)
                        .lineLimit(1)
                    ProgressView(value: quest.progressValue)
                        .tint(quest.isOptional ? WidgetTheme.successGreen : WidgetTheme.primaryBlue)
                    HStack {
                        Text(quest.progressText)
                        Spacer()
                        Text(relativeExpiry(for: quest.expiresAt))
                    }
                    .font(WidgetTheme.text(11))
                    .foregroundStyle(WidgetTheme.textSecondary)
                }
            }

            if displayedQuests.isEmpty {
                Spacer()
                Text("Nothing left today. Rest is part of it.")
                    .font(WidgetTheme.text(12))
                    .foregroundStyle(WidgetTheme.textSecondary)
            }
        }
        .foregroundStyle(WidgetTheme.textPrimary)
        .containerBackground(for: .widget) {
            WidgetTheme.cardBackground(accent: WidgetTheme.accentCyan)
        }
        .environment(\.locale, WidgetLanguageSupport.locale)
        .widgetURL(nextUpURL)
    }

    private var displayedQuests: [WidgetQuestSummaryItem] {
        switch family {
        case .systemLarge:
            return Array(entry.payload.nextUp.prefix(3))
        default:
            return Array(entry.payload.nextUp.prefix(2))
        }
    }

    private func relativeExpiry(for date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return "Due \(formatter.localizedString(for: date, relativeTo: Date()))"
    }

    private var nextUpURL: URL? {
        if let quest = displayedQuests.first {
            return URL(string: "sil://quests?questID=\(quest.id.uuidString)")
        }
        return URL(string: "sil://quests")
    }
}

struct BossWidgetView: View {
    let entry: SILBossWidgetEntry

    private var displayedBoss: WidgetBossSummary? {
        entry.selectedBoss ?? entry.payload.primaryBoss
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let boss = displayedBoss {
                HStack(alignment: .top, spacing: 8) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(boss.title)
                            .font(WidgetTheme.text(17, .semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.82)
                        Text(boss.subtitle)
                            .font(WidgetTheme.text(12))
                            .foregroundStyle(WidgetTheme.textSecondary)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 8)

                    Text("\(Int(boss.progressValue * 100))%")
                        .font(WidgetTheme.mono(20, .medium))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(WidgetTheme.backgroundTertiary)
                        RoundedRectangle(cornerRadius: 8)
                            .fill(WidgetTheme.hpGradient)
                            .frame(width: max(14, geometry.size.width * boss.progressValue))
                    }
                }
                .frame(height: 10)

                HStack {
                    statPill(title: "HP Left", value: "\(boss.remainingHP)")
                    statPill(title: "Max HP", value: "\(boss.maxHP)")
                }

                if let quest = entry.payload.nextUp.first {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("Best next move")
                            .font(WidgetTheme.text(11))
                            .foregroundStyle(WidgetTheme.textSecondary)
                            .lineLimit(1)
                        Text(quest.title)
                            .font(WidgetTheme.text(12, .semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Goal")
                        .font(WidgetTheme.text(17, .semibold))
                    Text("No goals yet")
                        .font(WidgetTheme.text(15, .semibold))
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    Text("Add a goal to watch it move here.")
                        .font(WidgetTheme.text(12))
                        .foregroundStyle(WidgetTheme.textSecondary)
                        .lineLimit(2)
                }
            }
        }
        .foregroundStyle(WidgetTheme.textPrimary)
        .containerBackground(for: .widget) {
            WidgetTheme.cardBackground(accent: WidgetTheme.criticalRed)
        }
        .environment(\.locale, WidgetLanguageSupport.locale)
        .widgetURL(bossURL)
    }

    private func statPill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(WidgetTheme.text(11))
                .foregroundStyle(WidgetTheme.textSecondary)
            Text(value)
                .font(WidgetTheme.text(12, .semibold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(WidgetTheme.backgroundTertiary.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var bossURL: URL? {
        guard let boss = displayedBoss else {
            return URL(string: "sil://bosses")
        }
        return URL(string: "sil://bosses?bossID=\(boss.id.uuidString)")
    }
}

struct SILStatusWidget: Widget {
    let kind = "SILStatusWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SILTimelineProvider()) { entry in
            StatusWidgetView(entry: entry)
        }
        .configurationDisplayName("Momentum")
        .description("Level, momentum, streak, credits and what is left today.")
        .supportedFamilies([.systemSmall, .accessoryRectangular, .accessoryCircular, .accessoryInline])
    }
}

struct SILNextUpWidget: Widget {
    let kind = "SILNextUpWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SILTimelineProvider()) { entry in
            NextUpWidgetView(entry: entry)
        }
        .configurationDisplayName("Next Up")
        .description("The habits worth doing next, by urgency and by what they move.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

struct SILBossWidget: Widget {
    let kind = "SILBossWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: BossWidgetConfigurationIntent.self, provider: SILBossTimelineProvider()) { entry in
            BossWidgetView(entry: entry)
        }
        .configurationDisplayName("Goal progress")
        .description("Follow one goal, or let SIL pick the one that needs you most.")
        .supportedFamilies([.systemMedium])
    }
}

@main
struct SILWidgetsBundle: WidgetBundle {
    var body: some Widget {
        SILStatusWidget()
        SILNextUpWidget()
        SILBossWidget()
    }
}
