//
//  AppearanceSupport.swift
//  SIL
//
//  The two pieces of the retired SettingsView that SIL still needs: the
//  light/dark preference the app root reads, and the alternate-icon manager
//  behind the icon grid in `SILSettingsView`.
//

import Combine
import SwiftUI
import UIKit

// MARK: - Appearance preference

enum AppearancePreference: String, Hashable, CaseIterable {
    case system, light, dark

    /// The key both the app root and Settings read. Keeping the name here
    /// stops the two drifting apart again.
    static let storageKey = "appearancePreference"

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }

    /// Fold the pre-SIL pair of booleans into the single preference, once.
    /// Installs that predate this have `useSystemAppearance` /
    /// `preferDarkMode` set and no `appearancePreference`.
    static func migrateLegacyKeysIfNeeded() {
        let defaults = UserDefaults.standard
        guard defaults.string(forKey: storageKey) == nil else { return }

        let resolved: AppearancePreference
        if defaults.object(forKey: "useSystemAppearance") == nil {
            resolved = .system
        } else if defaults.bool(forKey: "useSystemAppearance") {
            resolved = .system
        } else {
            resolved = defaults.bool(forKey: "preferDarkMode") ? .dark : .light
        }
        defaults.set(resolved.rawValue, forKey: storageKey)
    }
}

// MARK: - Stat Row

// MARK: - Alternate app icons

final class AppIconManager: ObservableObject {
    static let shared = AppIconManager()
    private static let storedOptionKey = "selectedAppIconOption"
    private static let maxIconChangeAttempts = 3
    private static let iconChangeRetryDelay: TimeInterval = 0.8
    private static let iconChangeSettleDelay: TimeInterval = 1.6

    @Published private(set) var currentOption: AppIconOption = .ink
    @Published private(set) var isSupported: Bool = UIApplication.shared.supportsAlternateIcons
    @Published private(set) var hasLegacyIconOverride = false
    @Published private(set) var hasPendingIconChange = false
    @Published private(set) var pendingIconDisplayName: String?
    private var pendingOption: AppIconOption?
    private var pendingRequestID = UUID()
    private var cancellables = Set<AnyCancellable>()
    private var storedOption: AppIconOption? {
        get {
            guard let rawValue = UserDefaults.standard.string(forKey: Self.storedOptionKey) else {
                return nil
            }
            return AppIconOption(rawValue: rawValue)
        }
        set {
            if let newValue {
                UserDefaults.standard.set(newValue.rawValue, forKey: Self.storedOptionKey)
            } else {
                UserDefaults.standard.removeObject(forKey: Self.storedOptionKey)
            }
        }
    }

    private init() {
        normalizeLegacyIconIfNeeded()
        refreshCurrentIcon()
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.refreshCurrentIcon()
            }
            .store(in: &cancellables)
    }

    func refreshCurrentIcon() {
        isSupported = UIApplication.shared.supportsAlternateIcons
        guard isSupported else {
            currentOption = .ink
            hasLegacyIconOverride = false
            hasPendingIconChange = false
            pendingIconDisplayName = nil
            pendingOption = nil
            storedOption = nil
            return
        }

        let resolvedState = resolvedSystemState()

        if hasPendingIconChange, let pendingOption {
            if resolvedState.currentOption == pendingOption {
                applyResolvedSystemState(resolvedState)
                clearPendingIconChange()
            } else {
                currentOption = pendingOption
                hasLegacyIconOverride = resolvedState.hasLegacyIconOverride
            }
            return
        }

        applyResolvedSystemState(resolvedState)
    }

    func setIcon(_ option: AppIconOption) {
        isSupported = UIApplication.shared.supportsAlternateIcons
        guard isSupported else {
            SystemMessageHelper.showWarning("Alternate app icons are not supported on this device.")
            return
        }

        let targetIconName = option.iconName
        let resolvedState = resolvedSystemState()
        guard !hasPendingIconChange else { return }
        guard resolvedState.currentOption != option else {
            applyResolvedSystemState(resolvedState)
            return
        }

        let requestID = UUID()
        pendingRequestID = requestID
        pendingOption = option
        currentOption = option
        hasPendingIconChange = true
        pendingIconDisplayName = option.displayName

        performIconChange(
            requestID: requestID,
            targetIconName: targetIconName
        )
    }

    /// Reset the alternate icon to the bundle default if it currently
    /// points at a name that has been removed from the catalog (legacy
    /// Phoenix variants, or the redundant pre-rename "AppIconPrism").
    /// Silent — no toast — so users don't see warnings when iOS recovers.
    private func normalizeLegacyIconIfNeeded() {
        guard UIApplication.shared.supportsAlternateIcons else { return }
        guard let currentName = UIApplication.shared.alternateIconName else { return }
        let resolvedState = AppIconStateResolver.resolve(
            currentIconName: currentName,
            storedOption: storedOption
        )
        guard resolvedState.shouldNormalizeIconName else { return }

        storedOption = .ink
        UIApplication.shared.setAlternateIconName(nil) { [weak self] _ in
            DispatchQueue.main.async {
                self?.refreshCurrentIcon()
            }
        }
    }

    private func performIconChange(
        requestID: UUID,
        targetIconName: String?,
        attempt: Int = 1
    ) {
        guard requestID == pendingRequestID else { return }

        UIApplication.shared.setAlternateIconName(targetIconName) { [weak self] error in
            DispatchQueue.main.async {
                if let error {
                    self?.handleIconChangeError(
                        error,
                        requestID: requestID,
                        targetIconName: targetIconName,
                        attempt: attempt
                    )
                } else {
                    self?.finishIconChange(
                        requestID: requestID,
                        targetIconName: targetIconName,
                        attempt: attempt
                    )
                }
            }
        }
    }

    private func handleIconChangeError(
        _ error: Error,
        requestID: UUID,
        targetIconName: String?,
        attempt: Int
    ) {
        guard requestID == pendingRequestID else { return }

        if isResourceTemporarilyUnavailable(error) {
            applyResolvedSystemState(resolvedSystemState())
            clearPendingIconChange()
            SystemMessageHelper.showWarning("iOS is still applying the last icon change. Please try again.")
            return
        }

        if attempt < Self.maxIconChangeAttempts {
            retryIconChange(
                requestID: requestID,
                targetIconName: targetIconName,
                attempt: attempt + 1
            )
            return
        }

        NSLog("SIL app icon change failed after \(attempt) attempts: \(error.localizedDescription)")
        applyResolvedSystemState(resolvedSystemState())
        clearPendingIconChange()
        SystemMessageHelper.showWarning("App icon could not be changed. Please try again.")
    }

    private func finishIconChange(
        requestID: UUID,
        targetIconName: String?,
        attempt: Int
    ) {
        guard requestID == pendingRequestID else { return }

        let resolvedState = resolvedSystemState()
        if UIApplication.shared.alternateIconName == targetIconName {
            applyResolvedSystemState(resolvedState)
            clearPendingIconChangeAfterSettle(requestID: requestID)
            return
        }

        if attempt < Self.maxIconChangeAttempts {
            retryIconChange(
                requestID: requestID,
                targetIconName: targetIconName,
                attempt: attempt + 1
            )
            return
        }

        applyResolvedSystemState(resolvedState)
        clearPendingIconChange()
        SystemMessageHelper.showWarning("App icon could not be changed. Please try again.")
    }

    private func retryIconChange(
        requestID: UUID,
        targetIconName: String?,
        attempt: Int
    ) {
        guard requestID == pendingRequestID else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + Self.iconChangeRetryDelay) { [weak self] in
            self?.performIconChange(
                requestID: requestID,
                targetIconName: targetIconName,
                attempt: attempt
            )
        }
    }

    private func resolvedSystemState() -> AppIconResolvedState {
        AppIconStateResolver.resolve(
            currentIconName: UIApplication.shared.alternateIconName,
            storedOption: storedOption
        )
    }

    private func applyResolvedSystemState(_ state: AppIconResolvedState) {
        currentOption = state.currentOption
        storedOption = state.storedOption
        hasLegacyIconOverride = state.hasLegacyIconOverride
    }

    private func clearPendingIconChange() {
        hasPendingIconChange = false
        pendingIconDisplayName = nil
        pendingOption = nil
    }

    private func clearPendingIconChangeAfterSettle(requestID: UUID) {
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.iconChangeSettleDelay) { [weak self] in
            guard let self, requestID == self.pendingRequestID else { return }
            self.clearPendingIconChange()
        }
    }

    private func isResourceTemporarilyUnavailable(_ error: Error) -> Bool {
        let nsError = error as NSError
        return nsError.domain == NSPOSIXErrorDomain && nsError.code == 35
            || error.localizedDescription.localizedCaseInsensitiveContains("Resource temporarily unavailable")
    }

}
