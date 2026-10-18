import Foundation

@inline(__always)
private func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    if !condition() {
        fputs("FAIL: \(message)\n", stderr)
        exit(1)
    }
}

@main
struct AppIconSupportTestsMain {
    static func main() {
        testAlternateIconNames()
        testCurrentSystemIconWinsOverStoredSelection()
        testLegacyAndUnknownNamesNormalizeToSignal()
        print("All app icon support tests passed")
    }

    private static func testAlternateIconNames() {
        let expectedNames: Set<String> = [
            "AppIconPaper",
            "AppIconViolet",
            "AppIconEmber",
        ]

        expect(AppIconOption.alternateIconNames == expectedNames, "Alternate icon names should match the asset catalog")
        expect(AppIconOption.ink.iconName == nil, "Ink should be the primary icon, not an alternate icon name")
        expect(AppIconOption(iconName: "AppIconPaper") == .paper, "Paper alternate should resolve from its icon name")
        expect(AppIconOption(iconName: "AppIconViolet") == .violet, "Violet alternate should resolve from its icon name")
        expect(AppIconOption(iconName: "AppIconEmber") == .ember, "Ember alternate should resolve from its icon name")
    }

    private static func testCurrentSystemIconWinsOverStoredSelection() {
        let defaultState = AppIconStateResolver.resolve(
            currentIconName: nil,
            storedOption: .gold
        )
        expect(defaultState.currentOption == .ink, "Default system icon should display Ink even if a stale alternate was saved")
        expect(defaultState.storedOption == .ink, "Default system icon should clear stale alternate persistence")
        expect(defaultState.hasLegacyIconOverride == false, "Default system icon should not be treated as a legacy override")

        let alternateState = AppIconStateResolver.resolve(
            currentIconName: "AppIconPrismSolar",
            storedOption: .ink
        )
        expect(alternateState.currentOption == .solar, "Actual system alternate should display even if stored selection differs")
        expect(alternateState.storedOption == .solar, "Actual system alternate should refresh stored selection")
    }

    private static func testLegacyAndUnknownNamesNormalizeToSignal() {
        let legacyState = AppIconStateResolver.resolve(
            currentIconName: "AppIconPhoenixDarkV2",
            storedOption: .verdant
        )
        expect(legacyState.currentOption == .ink, "Legacy app icon names should resolve to Signal")
        expect(legacyState.storedOption == .ink, "Legacy app icon names should clear alternate persistence")
        expect(legacyState.hasLegacyIconOverride, "Legacy app icon names should be flagged for normalization")
        expect(legacyState.shouldNormalizeIconName, "Legacy app icon names should be reset to the primary icon")

        let unknownState = AppIconStateResolver.resolve(
            currentIconName: "MissingAlternateIcon",
            storedOption: .crimson
        )
        expect(unknownState.currentOption == .ink, "Unknown app icon names should fall back to Signal")
        expect(unknownState.storedOption == .ink, "Unknown app icon names should clear alternate persistence")
        expect(unknownState.hasLegacyIconOverride, "Unknown app icon names should be flagged for normalization")
        expect(unknownState.shouldNormalizeIconName, "Unknown app icon names should be reset to the primary icon")
    }
}
