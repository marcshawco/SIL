//
//  SILHabitEditorSupport.swift
//  SIL
//
//  The pieces `SILHabitEditor` leans on: the Apple Health metric list and its
//  picker, and the Apple Maps address autocomplete behind the location field.
//  These came out of the old `QuestFormSheet` unchanged in behaviour — only
//  the picker's chrome is new.
//

import SwiftUI
import MapKit
import CoreLocation
import Combine

// MARK: - Apple Health metrics

/// The Apple Health metrics a habit can close itself against.
enum HealthKitQuestType: String, CaseIterable, Identifiable {
    case steps = "steps"
    case distance = "distance"
    case activeEnergy = "activeEnergy"
    case exerciseMinutes = "exerciseMinutes"
    case workoutCount = "workoutCount"
    case standHours = "standHours"
    case sleep = "sleep"
    case water = "water"
    case mindfulness = "mindfulness"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .steps: return "Steps"
        case .distance: return "Distance walked"
        case .activeEnergy: return "Active calories"
        case .exerciseMinutes: return "Exercise minutes"
        case .workoutCount: return "Workouts"
        case .standHours: return "Stand hours"
        case .sleep: return "Sleep"
        case .water: return "Water"
        case .mindfulness: return "Mindful minutes"
        }
    }

    var icon: String {
        switch self {
        case .steps: return "figure.walk"
        case .distance: return "figure.walk.motion"
        case .activeEnergy: return "flame"
        case .exerciseMinutes: return "timer"
        case .workoutCount: return "figure.run"
        case .standHours: return "figure.stand"
        case .sleep: return "bed.double"
        case .water: return "drop"
        case .mindfulness: return "brain.head.profile"
        }
    }

    var unit: String {
        switch self {
        case .steps: return "steps"
        case .distance: return "km"
        case .activeEnergy: return "kcal"
        case .exerciseMinutes: return "minutes"
        case .workoutCount: return "workouts"
        case .standHours: return "hours"
        case .sleep: return "hours"
        case .water: return "glasses"
        case .mindfulness: return "minutes"
        }
    }

    var identifier: String {
        switch self {
        case .steps: return "HKQuantityTypeIdentifierStepCount"
        case .distance: return "HKQuantityTypeIdentifierDistanceWalkingRunning"
        case .activeEnergy: return "HKQuantityTypeIdentifierActiveEnergyBurned"
        case .exerciseMinutes: return "HKQuantityTypeIdentifierAppleExerciseTime"
        case .workoutCount: return "HKWorkoutType"
        case .standHours: return "HKCategoryTypeIdentifierAppleStandHour"
        case .sleep: return "HKCategoryTypeIdentifierSleepAnalysis"
        case .water: return "HKQuantityTypeIdentifierDietaryWater"
        case .mindfulness: return "HKCategoryTypeIdentifierMindfulSession"
        }
    }

    /// Sensible target values for this metric, for the wheel.
    var targetOptions: [WheelValueOption] {
        func options(_ values: StrideThrough<Int>) -> [WheelValueOption] {
            values.map { WheelValueOption(value: Double($0), label: "\($0)") }
        }
        switch self {
        case .steps:                      return options(stride(from: 1000, through: 30000, by: 500))
        case .activeEnergy:               return options(stride(from: 50, through: 2000, by: 50))
        case .exerciseMinutes, .mindfulness: return options(stride(from: 5, through: 240, by: 5))
        case .distance, .sleep, .water:   return options(stride(from: 1, through: 20, by: 1))
        case .workoutCount:               return options(stride(from: 1, through: 14, by: 1))
        case .standHours:                 return options(stride(from: 1, through: 24, by: 1))
        }
    }
}

/// A plain list of metrics on SIL surfaces. The old version was a UIKit wheel
/// behind a confirm button; a list says what the options are without a spin.
struct SILHealthMetricSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selection: HealthKitQuestType

    var body: some View {
        ZStack {
            S.bg2.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                Text("Apple Health")
                    .font(S.display(26, .semibold))
                    .tracking(S.displayTracking(26))
                    .foregroundStyle(S.ink)
                Text("Which metric closes this habit on its own.")
                    .font(S.text(15))
                    .foregroundStyle(S.ink2)
                    .padding(.top, 4)

                ScrollView {
                    SILListCard {
                        ForEach(Array(HealthKitQuestType.allCases.enumerated()), id: \.element) { index, type in
                            SILListRow(
                                title: type.displayName,
                                detail: "Measured in \(type.unit)",
                                showsDivider: index > 0
                            ) {
                                if type == selection {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(S.ink)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selection = type
                                HapticManager.shared.selection()
                                dismiss()
                            }
                        }
                    }
                    .padding(.vertical, 16)
                }
                .scrollIndicators(.hidden)
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
        }
        .presentationDragIndicator(.visible)
        .silAppearance()
    }
}

// MARK: - Address autocomplete

struct AddressSuggestion: Identifiable, Equatable {
    let id: String
    let primaryText: String
    let secondaryText: String?

    var fullText: String {
        let secondary = secondaryText?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return secondary.isEmpty ? primaryText : "\(primaryText), \(secondary)"
    }
}

@MainActor
final class AddressAutocompleteProvider: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published private(set) var suggestions: [AddressSuggestion] = []
    @Published private(set) var isSearching = false

    private let completer = MKLocalSearchCompleter()
    private var lastQuery = ""

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = .address
    }

    func updateQuery(_ rawQuery: String) {
        let query = rawQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard query != lastQuery else { return }
        lastQuery = query

        if query.count < 3 {
            clear()
            return
        }

        isSearching = true
        completer.queryFragment = query
    }

    func clear() {
        isSearching = false
        suggestions = []
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        isSearching = false
        suggestions = completer.results.prefix(5).map { result in
            let title = result.title.trimmingCharacters(in: .whitespacesAndNewlines)
            let subtitle = result.subtitle.trimmingCharacters(in: .whitespacesAndNewlines)
            return AddressSuggestion(
                id: "\(title)|\(subtitle)",
                primaryText: title.isEmpty ? "Unknown place" : title,
                secondaryText: subtitle.isEmpty ? nil : subtitle
            )
        }
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        isSearching = false
        suggestions = []
        #if DEBUG
        print("Apple Maps autocomplete failed: \(error.localizedDescription)")
        #endif
    }
}

// MARK: - Address resolution

/// Turning typed text into a coordinate. MapKit search first, the geocoder as
/// a fallback where map results are sparse.
enum SILAddressResolver {
    static func resolve(_ address: String) async -> LocationCoordinate? {
        if let viaSearch = await search(address) { return viaSearch }
        return await geocode(address)
    }

    private static func search(_ address: String) async -> LocationCoordinate? {
        await withCheckedContinuation { continuation in
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = address
            request.resultTypes = .address

            MKLocalSearch(request: request).start { response, _ in
                guard
                    let item = response?.mapItems.first,
                    CLLocationCoordinate2DIsValid(item.placemark.coordinate)
                else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: coordinate(
                    from: item.placemark.coordinate,
                    name: name(from: item.placemark, fallback: address)
                ))
            }
        }
    }

    private static func geocode(_ address: String) async -> LocationCoordinate? {
        await withCheckedContinuation { continuation in
            CLGeocoder().geocodeAddressString(address) { placemarks, _ in
                guard
                    let placemark = placemarks?.first,
                    let found = placemark.location?.coordinate
                else {
                    continuation.resume(returning: nil)
                    return
                }
                let resolved = name(from: placemark, fallback: address)
                continuation.resume(returning: coordinate(
                    from: found,
                    name: resolved.isEmpty ? address : resolved
                ))
            }
        }
    }

    /// ~0.5 miles. The editor overwrites this with the chosen radius on save.
    private static let defaultRadius: Double = 804.67

    private static func coordinate(from raw: CLLocationCoordinate2D, name: String) -> LocationCoordinate {
        // Rounded to five decimals so reopening a habit does not jitter
        // between two equivalent fixes for the same address.
        func trimmed(_ value: Double) -> Double { (value * 100_000).rounded() / 100_000 }
        return LocationCoordinate(
            latitude: trimmed(raw.latitude),
            longitude: trimmed(raw.longitude),
            radius: defaultRadius,
            locationName: name
        )
    }

    private static func name(from placemark: CLPlacemark, fallback: String) -> String {
        let street = [placemark.subThoroughfare, placemark.thoroughfare]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        let area = [placemark.locality, placemark.administrativeArea, placemark.postalCode]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: ", ")

        let full = [street, area].filter { !$0.isEmpty }.joined(separator: ", ")
        if !full.isEmpty { return full }
        if let title = placemark.name?.trimmingCharacters(in: .whitespacesAndNewlines), !title.isEmpty {
            return title
        }
        return fallback
    }
}
