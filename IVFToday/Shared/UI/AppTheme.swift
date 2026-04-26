import SwiftUI

enum AppTheme {
    struct Palette {
        let background: Color
        let sectionBackground: Color
        let primary: Color
        let secondaryAccent: Color
        let success: Color
        let caution: Color
        let critical: Color
        let info: Color
        let mutedText: Color
    }

    enum Preset: String, CaseIterable, Identifiable {
        case roseBlush
        case sageRecovery
        case dawnApricot
        case mistBlue

        var id: String { rawValue }

        var title: String {
            switch self {
            case .roseBlush:
                return "Gentle rose with calming sage"
            case .sageRecovery:
                return "Low-stimulation green for recovery"
            case .dawnApricot:
                return "Warm apricot for a softer mood"
            case .mistBlue:
                return "Quiet blue for a clean, steady tone"
            }
        }

        var subtitle: String {
            switch self {
            case .roseBlush:
                return "Rose Blush"
            case .sageRecovery:
                return "Sage Recovery"
            case .dawnApricot:
                return "Dawn Apricot"
            case .mistBlue:
                return "Mist Blue"
            }
        }

        var palette: Palette {
            switch self {
            case .roseBlush:
                return Palette(
                    background: Color(red: 0.99, green: 0.96, blue: 0.97),
                    sectionBackground: Color(red: 1.00, green: 0.98, blue: 0.98),
                    primary: Color(red: 0.78, green: 0.42, blue: 0.55),
                    secondaryAccent: Color(red: 0.50, green: 0.69, blue: 0.64),
                    success: Color(red: 0.44, green: 0.64, blue: 0.54),
                    caution: Color(red: 0.79, green: 0.60, blue: 0.48),
                    critical: Color(red: 0.72, green: 0.37, blue: 0.43),
                    info: Color(red: 0.51, green: 0.63, blue: 0.71),
                    mutedText: Color(red: 0.43, green: 0.40, blue: 0.46)
                )
            case .sageRecovery:
                return Palette(
                    background: Color(red: 0.96, green: 0.97, blue: 0.96),
                    sectionBackground: Color(red: 0.98, green: 0.99, blue: 0.98),
                    primary: Color(red: 0.44, green: 0.58, blue: 0.53),
                    secondaryAccent: Color(red: 0.78, green: 0.55, blue: 0.48),
                    success: Color(red: 0.35, green: 0.56, blue: 0.45),
                    caution: Color(red: 0.76, green: 0.62, blue: 0.42),
                    critical: Color(red: 0.73, green: 0.36, blue: 0.39),
                    info: Color(red: 0.42, green: 0.60, blue: 0.59),
                    mutedText: Color(red: 0.38, green: 0.45, blue: 0.42)
                )
            case .dawnApricot:
                return Palette(
                    background: Color(red: 1.00, green: 0.96, blue: 0.95),
                    sectionBackground: Color(red: 1.00, green: 0.99, blue: 0.98),
                    primary: Color(red: 0.79, green: 0.49, blue: 0.40),
                    secondaryAccent: Color(red: 0.66, green: 0.63, blue: 0.48),
                    success: Color(red: 0.46, green: 0.60, blue: 0.47),
                    caution: Color(red: 0.81, green: 0.59, blue: 0.36),
                    critical: Color(red: 0.75, green: 0.34, blue: 0.36),
                    info: Color(red: 0.60, green: 0.66, blue: 0.77),
                    mutedText: Color(red: 0.47, green: 0.40, blue: 0.37)
                )
            case .mistBlue:
                return Palette(
                    background: Color(red: 0.96, green: 0.97, blue: 0.99),
                    sectionBackground: Color(red: 0.99, green: 0.99, blue: 1.00),
                    primary: Color(red: 0.43, green: 0.57, blue: 0.66),
                    secondaryAccent: Color(red: 0.72, green: 0.54, blue: 0.60),
                    success: Color(red: 0.40, green: 0.60, blue: 0.50),
                    caution: Color(red: 0.78, green: 0.63, blue: 0.41),
                    critical: Color(red: 0.71, green: 0.36, blue: 0.41),
                    info: Color(red: 0.40, green: 0.57, blue: 0.73),
                    mutedText: Color(red: 0.39, green: 0.44, blue: 0.49)
                )
            }
        }
    }

    static let defaultPreset: Preset = .dawnApricot
    static var fallbackPalette: Palette { defaultPreset.palette }

    static let background = fallbackPalette.background
    static let sectionBackground = fallbackPalette.sectionBackground
    static let primary = fallbackPalette.primary
    static let secondaryAccent = fallbackPalette.secondaryAccent
    static let success = fallbackPalette.success
    static let caution = fallbackPalette.caution
    static let critical = fallbackPalette.critical
    static let info = fallbackPalette.info
    static let mutedText = fallbackPalette.mutedText
}

@MainActor
@Observable
final class ThemeController {
    private let defaults: UserDefaults
    private let presetKey = "app_theme_preset"

    var selectedPreset: AppTheme.Preset {
        didSet {
            defaults.set(selectedPreset.rawValue, forKey: presetKey)
        }
    }

    var palette: AppTheme.Palette {
        selectedPreset.palette
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let savedRawValue = defaults.string(forKey: presetKey),
           let savedPreset = AppTheme.Preset(rawValue: savedRawValue) {
            selectedPreset = savedPreset
        } else {
            selectedPreset = AppTheme.defaultPreset
        }
    }
}
