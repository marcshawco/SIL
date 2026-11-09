//
//  PermissionManagerView.swift
//  SIL
//
//  What SIL is allowed to read, and what that buys you.
//
//  This was "Neural Links": a brain icon, a `[SYSTEM]:` status line, and
//  three sections of connection telemetry. The permissions themselves have
//  not changed — the engine still calls them vital signs, world position and
//  system messages — but the screen now says Apple Health, Location and
//  Notifications, on SIL surfaces.
//

import SwiftUI

struct PermissionManagerView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    @ObservedObject private var permissionManager = PermissionManager.shared
    @ObservedObject private var healthKitManager = HealthKitManager.shared
    @ObservedObject private var locationManager = LocationManager.shared
    @ObservedObject private var notificationManager = NotificationManager.shared

    var body: some View {
        ZStack {
            S.bg2.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        Text("SIL only reads what you switch on here, and only to close habits on their own.")
                            .font(S.text(17))
                            .foregroundStyle(S.ink2)

                        connections
                        detail
                        systemSettings
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
                .scrollIndicators(.hidden)
                .refreshable { await refresh() }
            }
        }
        .silAppearance()
        .onAppear { Task { await refresh() } }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            Task { await refresh() }
        }
    }

    // MARK: Chrome

    private var header: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(S.line2)
                .frame(width: 40, height: 5)
                .padding(.top, 10)

            HStack {
                Text("Permissions")
                    .font(S.display(28, .semibold))
                    .tracking(S.displayTracking(28))
                    .foregroundStyle(S.ink)
                Spacer()
                SILRoundButton(systemImage: "xmark", size: 40) { dismiss() }
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 4)
        }
    }

    // MARK: Sections

    private var connections: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Sources").silEyebrow()

            SILListCard {
                ForEach(Array(NeuralLinkType.betaAvailableCases.enumerated()), id: \.element) { index, type in
                    SILListRow(
                        title: SILPermission.name(type),
                        detail: signalLine(for: type),
                        showsDivider: index > 0
                    ) {
                        statusChip(for: type)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { request(type) }
                }
            }

            Text("Tap one to connect it. Apple Health, once connected, opens the Health app so you can change what SIL sees.")
                .font(S.text(13))
                .foregroundStyle(S.ink2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var detail: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("What each one does").silEyebrow()

            VStack(spacing: 12) {
                ForEach(NeuralLinkType.betaAvailableCases) { type in
                    SILCard(radius: S.R.small + 2, padding: 18) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(SILPermission.name(type))
                                .font(S.text(17, .medium))
                                .foregroundStyle(S.ink)

                            ForEach(SILPermission.uses(type), id: \.self) { use in
                                HStack(alignment: .top, spacing: 10) {
                                    Circle()
                                        .fill(S.ink3)
                                        .frame(width: 4, height: 4)
                                        .padding(.top, 7)
                                    Text(use)
                                        .font(S.text(15))
                                        .foregroundStyle(S.ink2)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
    }

    private var systemSettings: some View {
        SILGhostButton(title: "Open iOS Settings", height: 52) {
            permissionManager.openSystemSettings()
        }
    }

    // MARK: Pieces

    private func statusChip(for type: NeuralLinkType) -> some View {
        let on = permissionManager.isEnabled(for: type)
        return Text(on ? "On" : permissionManager.status(for: type).rawValue)
            .font(S.mono(10))
            .tracking(0.6)
            .textCase(.uppercase)
            .foregroundStyle(on ? S.onInv : S.ink2)
            .padding(.horizontal, 12)
            .frame(height: 30)
            .background(Capsule().fill(on ? S.inv : S.card2))
    }

    /// The old screen gave each source three rows of telemetry. One line of
    /// plain language says the same thing.
    private func signalLine(for type: NeuralLinkType) -> String {
        guard permissionManager.isEnabled(for: type) else {
            return SILPermission.subtitle(type)
        }
        switch type {
        case .vitalSigns:
            return "Last read \(relative(healthKitManager.lastSyncDate))"
                + (healthKitManager.backgroundDeliveryEnabled ? " · updating in the background" : "")
        case .worldPosition:
            return "Last seen \(relative(locationManager.lastTrackingEventDate))"
                + (locationManager.isMonitoringActive ? " · watching now" : "")
        case .systemMessages:
            return "Last sent \(relative(notificationManager.lastQuestCompletionNotificationDate))"
        }
    }

    private func relative(_ date: Date?) -> String {
        guard let date else { return "never" }
        return date.formatted(.relative(presentation: .named))
    }

    // MARK: Actions

    private func request(_ type: NeuralLinkType) {
        Task {
            do {
                if type == .vitalSigns, permissionManager.isEnabled(for: .vitalSigns) {
                    permissionManager.openHealthApp()
                    return
                }

                switch type {
                case .vitalSigns:
                    try await permissionManager.requestHealthKit()
                    if permissionManager.isEnabled(for: .vitalSigns) {
                        permissionManager.openHealthApp()
                    }
                case .worldPosition:
                    if permissionManager.status(for: .worldPosition) == .denied {
                        permissionManager.openSystemSettings()
                        return
                    }
                    permissionManager.requestLocation()
                    try await Task.sleep(nanoseconds: 1_200_000_000)
                    permissionManager.checkLocationStatus()
                case .systemMessages:
                    try await permissionManager.requestNotifications()
                }

                let name = SILPermission.name(type)
                if permissionManager.isEnabled(for: type) {
                    SystemMessageHelper.showInfo("\(name) connected", "SIL can read it now.")
                } else {
                    SystemMessageHelper.showWarning("Turn \(name) on in iOS Settings.")
                }
            } catch {
                SystemMessageHelper.showWarning("Turn \(SILPermission.name(type)) on in iOS Settings.")
            }
        }
    }

    private func refresh() async {
        await permissionManager.checkAllPermissions()
    }
}

// MARK: - Naming

/// The user-facing words for the three permissions. The engine's own names
/// (`vitalSigns`, `worldPosition`, `systemMessages`) are kept in storage.
enum SILPermission {
    static func name(_ type: NeuralLinkType) -> String {
        switch type {
        case .vitalSigns:     return "Apple Health"
        case .worldPosition:  return "Location"
        case .systemMessages: return "Notifications"
        }
    }

    static func subtitle(_ type: NeuralLinkType) -> String {
        switch type {
        case .vitalSigns:     return "Steps, workouts, sleep"
        case .worldPosition:  return "Places you set on a habit"
        case .systemMessages: return "Reminders you asked for"
        }
    }

    static func uses(_ type: NeuralLinkType) -> [String] {
        switch type {
        case .vitalSigns:
            return [
                "Closes step, distance, calorie and water habits as the day goes.",
                "Reads sleep so rest counts toward energy.",
                "Counts workouts from the Watch, Fitness, or anything that syncs in."
            ]
        case .worldPosition:
            return [
                "Closes a habit once you've stayed somewhere long enough.",
                "Only checks the places you set on a habit yourself."
            ]
        case .systemMessages:
            return [
                "Sends the reminder you set on a habit.",
                "Tells you when a focus session ends."
            ]
        }
    }
}

#Preview {
    PermissionManagerView()
}
