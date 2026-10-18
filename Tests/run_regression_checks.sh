#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT="$ROOT/SIL.xcodeproj"

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

echo "Running static regression checks..."

grep -q 'INFOPLIST_KEY_NSHealthShareUsageDescription' "$PROJECT/project.pbxproj" || fail "Missing NSHealthShareUsageDescription"
grep -q 'INFOPLIST_KEY_NSHealthUpdateUsageDescription' "$PROJECT/project.pbxproj" || fail "Missing NSHealthUpdateUsageDescription required by App Store HealthKit validation"
if grep -q 'INFOPLIST_KEY_NSHealthClinicalHealthRecordsShareUsageDescription' "$PROJECT/project.pbxproj"; then
  fail "Clinical health records usage description should not be present without clinical record access"
fi
grep -Fq 'requestAuthorization(toShare: [], read: readTypes)' "$ROOT/SIL/Services/HealthKitManager.swift" || fail "HealthKit authorization should remain read-only"
grep -q 'INFOPLIST_KEY_NSLocationWhenInUseUsageDescription = "' "$PROJECT/project.pbxproj" || fail "Missing NSLocationWhenInUseUsageDescription"
grep -q 'INFOPLIST_KEY_NSLocationAlwaysAndWhenInUseUsageDescription = "' "$PROJECT/project.pbxproj" || fail "Missing NSLocationAlwaysAndWhenInUseUsageDescription"
grep -q 'NSPrivacyAccessedAPICategoryUserDefaults' "$ROOT/SIL/PrivacyInfo.xcprivacy" || fail "App privacy manifest missing UserDefaults required-reason declaration"
grep -q 'NSPrivacyAccessedAPICategoryUserDefaults' "$ROOT/SILWidgets/PrivacyInfo.xcprivacy" || fail "Widget privacy manifest missing UserDefaults required-reason declaration"

APP_ICON_SUPPORT="$ROOT/SIL/Services/AppIconSupport.swift"
APP_ICON_SETTINGS="$ROOT/SIL/Design/AppearanceSupport.swift"
APP_ICON_NAMES=(
  AppIconPaper
  AppIconViolet
  AppIconEmber
)

grep -q 'AppIconStateResolver.resolve' "$APP_ICON_SETTINGS" || fail "App icon manager should resolve state from the actual system icon"
if grep -Fq 'currentOption = storedOption ?? .ink' "$APP_ICON_SETTINGS"; then
  fail "App icon manager should not display stale stored selections when the system icon is default"
fi
for icon_name in "${APP_ICON_NAMES[@]}"; do
  grep -Fq "$icon_name" "$PROJECT/project.pbxproj" || fail "Missing alternate app icon build setting for $icon_name"
  grep -Fq "\"$icon_name\"" "$APP_ICON_SUPPORT" || fail "Missing AppIconOption mapping for $icon_name"
  [[ -d "$ROOT/SIL/Assets.xcassets/$icon_name.appiconset" ]] || fail "Missing asset catalog appiconset for $icon_name"
done
grep -Fq 'TARGETED_DEVICE_FAMILY = "1,2";' "$PROJECT/project.pbxproj" || fail "App target should generate complete iPhone and iPad icon metadata"
if grep -RInF 'UserDefaults(suiteName:' "$ROOT/SIL" "$ROOT/SILWidgets" >/dev/null; then
  fail "App/widget app-group bridge should use files instead of CFPrefs-backed suite defaults"
fi
grep -Fq 'SILTabBar(selection:' "$ROOT/SIL/Views/MainTabView.swift" || fail "Main tab view should use the floating SIL tab bar"
for silTab in today goals focus you; do
  grep -Fq "case .$silTab:" "$ROOT/SIL/Views/MainTabView.swift" || fail "Main tab view missing the $silTab destination"
done
grep -Fq 'screenBottom: CGFloat = 128' "$ROOT/SIL/Design/SILTheme.swift" || fail "Screens must reserve bottom room for the floating tab bar"

REMOVED_ENTITLEMENT='com.apple.developer.family-''controls'
if grep -q "$REMOVED_ENTITLEMENT" "$ROOT/SIL/SIL.entitlements"; then
  fail "Family Controls entitlement should not be present"
fi
REMOVED_TRACKING_PATTERN='Family''Controls|Managed''Settings|Device''Activity|Family''Activity''Picker|Authorization''Center|Screen''TimeManager|SIL''Monitor|screen''TimeDataDidUpdate'
if grep -RInE "$REMOVED_TRACKING_PATTERN" "$ROOT/SIL" "$ROOT/README.md" "$PROJECT/project.pbxproj" >/dev/null; then
  fail "Removed tracking API remnants found"
fi

if grep -RInF '.preferredColorScheme(.dark)' "$ROOT/SIL" >/dev/null; then
  fail "Found hard-forced dark mode call(s)"
fi

if grep -RInF 'overrideUserInterfaceStyle' "$ROOT/SIL" >/dev/null; then
  fail "Found UIKit appearance override forcing color scheme"
fi

grep -q 'configureBackgroundLocationUpdates()' "$ROOT/SIL/Services/LocationManager.swift" || fail "Location manager should configure background updates safely"
grep -q 'hasLocationBackgroundMode' "$ROOT/SIL/Services/LocationManager.swift" || fail "Location manager missing background mode capability guard"
grep -q 'requestWhenInUseAuthorization()' "$ROOT/SIL/Services/LocationManager.swift" || fail "Location manager not using requestWhenInUseAuthorization"
grep -q 'requestAlwaysAuthorization()' "$ROOT/SIL/Services/LocationManager.swift" || fail "Location manager not escalating to Always authorization"

grep -q 'SILOnboardingView' "$ROOT/SIL/SILApp.swift" || fail "Onboarding flow missing from the root view"
grep -Fq 'loadDailyQuests() ?? []' "$ROOT/SIL/Services/GameEngine.swift" || fail "GameEngine should not seed default quests"
grep -q 'case \.location: return "Location"' "$ROOT/SIL/Views/Quests/QuestFormSheet.swift" || fail "Quest form missing Address tracking segment"
grep -q 'customScheduleCard' "$ROOT/SIL/Views/Quests/QuestFormSheet.swift" || fail "Quest form missing unified schedule section"
grep -q 'Toggle(isOn: $reminderEnabled)' "$ROOT/SIL/Views/Quests/QuestFormSheet.swift" || fail "Quest form missing reminder toggle"
grep -q 'case workoutCount = \"workoutCount\"' "$ROOT/SIL/Views/Quests/QuestFormSheet.swift" || fail "Quest form missing workout-count HealthKit option"
grep -q 'healthKitDataDidUpdate' "$ROOT/SIL/Services/HealthKitManager.swift" || fail "HealthKit update notification missing"
grep -q 'healthKitDataDidUpdate' "$ROOT/SIL/Services/GameEngine.swift" || fail "GameEngine should react to HealthKit updates"
grep -q 'minimumVisitMinutes: configuredMinimumStay' "$ROOT/SIL/Services/LocationManager.swift" || fail "Location quest dwell-time configuration missing"
grep -q 'failForAppExit' "$ROOT/SIL/Services/TrainingManager.swift" || fail "Training manager missing app-exit fail handler"
grep -q 'newPhase == .background && training.isActive' "$ROOT/SIL/Views/SIL/SILFocusView.swift" || fail "Focus view missing background fail trigger"
grep -q 'maxHP' "$ROOT/SIL/Models/PlayerModels.swift" || fail "Player HP model missing"
grep -q 'awardXP(xp)' "$ROOT/SIL/Services/TrainingManager.swift" || fail "Training rewards should route through GameEngine.awardXP"

if grep -RInF 'Text("[QUESTS]")' "$ROOT/SIL/Views" >/dev/null; then
  fail "Found old [QUESTS] badge"
fi

if grep -RInF 'Text("[TRAINING]")' "$ROOT/SIL/Views" >/dev/null; then
  fail "Found old [TRAINING] badge"
fi

if grep -RInF 'Text("[BOSSES]")' "$ROOT/SIL/Views" >/dev/null; then
  fail "Found old [BOSSES] badge"
fi

echo "Running model logic tests..."
swiftc -o /tmp/gamelife_model_logic_tests \
  "$ROOT/Tests/test_theme_stub.swift" \
  "$ROOT/Tests/test_data_manager_stubs.swift" \
  "$ROOT/SIL/Models/PlayerModels.swift" \
  "$ROOT/SIL/Models/QuestModels.swift" \
  "$ROOT/SIL/Models/ActivityLogModels.swift" \
  "$ROOT/SIL/Services/DataManagers.swift" \
  "$ROOT/Tests/model_logic_tests.swift"
/tmp/gamelife_model_logic_tests

echo "Running app icon support tests..."
swiftc -o /tmp/gamelife_app_icon_support_tests \
  "$ROOT/SIL/Services/AppIconSupport.swift" \
  "$ROOT/Tests/app_icon_support_tests.swift"
/tmp/gamelife_app_icon_support_tests

echo "Running project build..."
SYMROOT="/tmp/gamelife_regression_symroot"
OBJROOT="/tmp/gamelife_regression_objroot"
rm -rf "$SYMROOT" "$OBJROOT"
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild \
  -project "$PROJECT" \
  -target SIL \
  -configuration Debug \
  CODE_SIGNING_ALLOWED=NO \
  SYMROOT="$SYMROOT" \
  OBJROOT="$OBJROOT" \
  build >/tmp/gamelife_regression_build.log 2>&1 || {
  tail -n 120 /tmp/gamelife_regression_build.log
  fail "xcodebuild failed"
}

APP_INFO_PLIST="$SYMROOT/Debug-iphoneos/SIL.app/Info.plist"
[[ -d "$SYMROOT/Debug-iphoneos/SIL.app/Watch/SILWatch.app" ]] || fail "Built app missing embedded watch app"
for icon_name in "${APP_ICON_NAMES[@]}"; do
  /usr/libexec/PlistBuddy -c "Print :CFBundleIcons:CFBundleAlternateIcons:$icon_name:CFBundleIconName" "$APP_INFO_PLIST" | grep -Fxq "$icon_name" || fail "Built Info.plist missing iPhone alternate icon $icon_name"
  /usr/libexec/PlistBuddy -c "Print :CFBundleIcons~ipad:CFBundleAlternateIcons:$icon_name:CFBundleIconName" "$APP_INFO_PLIST" | grep -Fxq "$icon_name" || fail "Built Info.plist missing iPad alternate icon $icon_name"
done

echo "All regression checks passed."
