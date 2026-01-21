import Foundation
import SwiftUI

// MARK: - Appearance Mode Enum
enum AppearanceMode: String, CaseIterable, Identifiable {
    case light = "light"
    case dark = "dark"
    case system = "system"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .light: return "Light"
        case .dark: return "Dark"
        case .system: return "System"
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }
}

// MARK: - Weight Unit Enum
enum WeightUnit: String, CaseIterable, Identifiable {
    case lbs = "lbs"
    case kg = "kg"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .lbs: return "Pounds (lbs)"
        case .kg: return "Kilograms (kg)"
        }
    }
    
    /// Conversion factor from lbs to this unit
    var fromLbsFactor: Double {
        switch self {
        case .lbs: return 1.0
        case .kg: return 0.453592
        }
    }
    
    /// Conversion factor from this unit to lbs (for storage)
    var toLbsFactor: Double {
        switch self {
        case .lbs: return 1.0
        case .kg: return 2.20462
        }
    }
}

// MARK: - User Settings Manager
@Observable
final class UserSettingsManager {
    static let shared = UserSettingsManager()
    
    // MARK: - Keys
    private enum Keys {
        static let weightUnit = "weightUnit"
        static let defaultRestDuration = "defaultRestDuration"
        static let hapticFeedbackEnabled = "hapticFeedbackEnabled"
        static let soundEnabled = "soundEnabled"
        static let appearanceMode = "appearanceMode"
    }
    
    // MARK: - Properties
    var weightUnit: WeightUnit {
        didSet {
            UserDefaults.standard.set(weightUnit.rawValue, forKey: Keys.weightUnit)
        }
    }
    
    var defaultRestDuration: TimeInterval {
        didSet {
            UserDefaults.standard.set(defaultRestDuration, forKey: Keys.defaultRestDuration)
        }
    }
    
    var hapticFeedbackEnabled: Bool {
        didSet {
            UserDefaults.standard.set(hapticFeedbackEnabled, forKey: Keys.hapticFeedbackEnabled)
        }
    }
    
    var soundEnabled: Bool {
        didSet {
            UserDefaults.standard.set(soundEnabled, forKey: Keys.soundEnabled)
        }
    }
    
    var appearanceMode: AppearanceMode {
        didSet {
            UserDefaults.standard.set(appearanceMode.rawValue, forKey: Keys.appearanceMode)
        }
    }
    
    // MARK: - Initialization
    private init() {
        // Load saved values or use defaults
        let savedUnit = UserDefaults.standard.string(forKey: Keys.weightUnit) ?? WeightUnit.lbs.rawValue
        self.weightUnit = WeightUnit(rawValue: savedUnit) ?? .lbs
        
        let savedRestDuration = UserDefaults.standard.double(forKey: Keys.defaultRestDuration)
        self.defaultRestDuration = savedRestDuration > 0 ? savedRestDuration : 90
        
        // Defaults to true if not set
        if UserDefaults.standard.object(forKey: Keys.hapticFeedbackEnabled) == nil {
            self.hapticFeedbackEnabled = true
        } else {
            self.hapticFeedbackEnabled = UserDefaults.standard.bool(forKey: Keys.hapticFeedbackEnabled)
        }
        
        if UserDefaults.standard.object(forKey: Keys.soundEnabled) == nil {
            self.soundEnabled = true
        } else {
            self.soundEnabled = UserDefaults.standard.bool(forKey: Keys.soundEnabled)
        }
        
        // Default to light mode
        let savedAppearance = UserDefaults.standard.string(forKey: Keys.appearanceMode) ?? AppearanceMode.light.rawValue
        self.appearanceMode = AppearanceMode(rawValue: savedAppearance) ?? .light
    }
    
    // MARK: - Formatting Helpers
    
    /// Formats a weight value (stored in lbs) for display in user's preferred unit
    func formatWeight(_ weightInLbs: Double) -> String {
        let converted = weightInLbs * weightUnit.fromLbsFactor
        if converted == floor(converted) {
            return String(format: "%.0f", converted)
        }
        return String(format: "%.1f", converted)
    }
    
    /// Formats a weight with unit label
    func formatWeightWithUnit(_ weightInLbs: Double) -> String {
        return "\(formatWeight(weightInLbs)) \(weightUnit.rawValue)"
    }
    
    /// Converts user input to lbs for storage
    func convertToLbs(_ value: Double) -> Double {
        return value * weightUnit.toLbsFactor
    }
    
    /// Converts stored lbs value to user's unit for display
    func convertFromLbs(_ weightInLbs: Double) -> Double {
        return weightInLbs * weightUnit.fromLbsFactor
    }
}
