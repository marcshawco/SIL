import Foundation

// MARK: - App Icon Support

/// SIL ships one mark in four finishes. The icon never changes shape — only
/// the ground it sits on — so the Home Screen stays recognisably SIL whichever
/// one is picked.
enum AppIconOption: String, CaseIterable, Identifiable {
    /// Ink — white mark on near-black. The primary icon; clears any override.
    case ink
    /// Paper — black mark on bone white.
    case paper
    /// Violet — white mark on the default accent.
    case violet
    /// Ember — black mark on the warm accent.
    case ember

    var id: String { rawValue }

    var iconName: String? {
        switch self {
        case .ink:    return nil
        case .paper:  return "AppIconPaper"
        case .violet: return "AppIconViolet"
        case .ember:  return "AppIconEmber"
        }
    }

    var displayName: String {
        switch self {
        case .ink:    return "Ink"
        case .paper:  return "Paper"
        case .violet: return "Violet"
        case .ember:  return "Ember"
        }
    }

    var subtitle: String {
        switch self {
        case .ink:    return "White on black · primary"
        case .paper:  return "Black on bone"
        case .violet: return "White on accent violet"
        case .ember:  return "Black on warm orange"
        }
    }

    var previewAssetName: String {
        switch self {
        case .ink:    return "AppIconInkPreview"
        case .paper:  return "AppIconPaperPreview"
        case .violet: return "AppIconVioletPreview"
        case .ember:  return "AppIconEmberPreview"
        }
    }

    /// Resolve the current alternate-icon name into an option. Every PRAXIS-era
    /// Prism and Phoenix name migrates to `.ink` so existing installs land on
    /// the current default instead of a dead asset.
    init?(iconName: String?) {
        switch iconName {
        case nil,
             "AppIconPrism", "AppIconPrismGold", "AppIconPrismCrimson",
             "AppIconPrismSolar", "AppIconPrismVerdant",
             "AppIconPhoenixIvory", "AppIconPhoenixIvoryV2",
             "AppIconPhoenixWhite", "AppIconPhoenixWhiteV2",
             "AppIconPhoenixDark",  "AppIconPhoenixDarkV2":
            self = .ink
        case "AppIconPaper":  self = .paper
        case "AppIconViolet": self = .violet
        case "AppIconEmber":  self = .ember
        default: return nil
        }
    }

    static let alternateIconNames: Set<String> = Set(allCases.compactMap(\.iconName))

    /// Names that no longer have catalog assets — force-migrated to nil so iOS
    /// doesn't try to resolve a dead alt-icon.
    static let legacyAlternateNames: Set<String> = [
        "AppIconPrism", "AppIconPrismGold", "AppIconPrismCrimson",
        "AppIconPrismSolar", "AppIconPrismVerdant",
        "AppIconPhoenixIvory", "AppIconPhoenixIvoryV2",
        "AppIconPhoenixWhite", "AppIconPhoenixWhiteV2",
        "AppIconPhoenixDark",  "AppIconPhoenixDarkV2",
    ]
}

struct AppIconResolvedState: Equatable {
    let currentOption: AppIconOption
    let storedOption: AppIconOption
    let hasLegacyIconOverride: Bool
    let shouldNormalizeIconName: Bool
}

enum AppIconStateResolver {
    static func resolve(
        currentIconName: String?,
        storedOption _: AppIconOption?
    ) -> AppIconResolvedState {
        guard let currentIconName else {
            return AppIconResolvedState(
                currentOption: .ink,
                storedOption: .ink,
                hasLegacyIconOverride: false,
                shouldNormalizeIconName: false
            )
        }

        if AppIconOption.legacyAlternateNames.contains(currentIconName) {
            return AppIconResolvedState(
                currentOption: .ink,
                storedOption: .ink,
                hasLegacyIconOverride: true,
                shouldNormalizeIconName: true
            )
        }

        if let currentOption = AppIconOption(iconName: currentIconName) {
            return AppIconResolvedState(
                currentOption: currentOption,
                storedOption: currentOption,
                hasLegacyIconOverride: false,
                shouldNormalizeIconName: false
            )
        }

        return AppIconResolvedState(
            currentOption: .ink,
            storedOption: .ink,
            hasLegacyIconOverride: true,
            shouldNormalizeIconName: true
        )
    }
}
