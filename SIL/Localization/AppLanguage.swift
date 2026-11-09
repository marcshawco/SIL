//
//  AppLanguage.swift
//  SIL
//
//  The in-app language picker, and the locale everything else resolves
//  through. `SILApp` publishes `selected.locale` into the environment; code
//  that formats outside a view body reads `AppLanguage.currentLocale`.
//

import Foundation
import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case english = "en"
    case german = "de"
    case russian = "ru"
    case french = "fr"
    case italian = "it"
    case spanish = "es"

    var id: String { rawValue }

    var localeIdentifier: String? {
        switch self {
        case .system:
            return nil
        case .english, .german, .russian, .french, .italian, .spanish:
            return rawValue
        }
    }

    var displayName: String {
        switch self {
        case .system:
            return "System Default"
        case .english:
            return "English"
        case .german:
            return "Deutsch"
        case .russian:
            return "Русский"
        case .french:
            return "Français"
        case .italian:
            return "Italiano"
        case .spanish:
            return "Español"
        }
    }

    /// The key `SILApp` and the settings screen both bind to.
    static let storageKey = "preferredLanguageCode"

    /// The language the user picked, or `.system`.
    static var selected: AppLanguage {
        let raw = UserDefaults.standard.string(forKey: storageKey) ?? AppLanguage.system.rawValue
        return AppLanguage(rawValue: raw) ?? .system
    }

    /// The locale the app is running in. Formatters built outside a view body
    /// must use this rather than `Locale.current`, which only knows the
    /// device's language and so ignores the in-app picker.
    static var currentLocale: Locale { selected.locale }

    var locale: Locale {
        if let localeIdentifier {
            return Locale(identifier: localeIdentifier)
        }
        return Locale(identifier: Locale.autoupdatingCurrent.language.languageCode?.identifier ?? "en")
    }
}

func localizedAppString(_ key: String) -> String {
    NSLocalizedString(key, comment: "")
}

extension GameTab {
    var localizedTitle: String {
        localizedAppString(title)
    }
}
