import Foundation

// MARK: - Enums

// Parola Gücü
enum PasswordStrength {
    case weak
    case medium
    case strong
}

// Boy Birimleri
enum HeightUnit {
    case cm
    case inch
}

// Ağırlık Birimleri
enum WeightUnit {
    case kg
    case lb
}

// Cinsiyet
enum Gender: String, Codable, CaseIterable {
    case male = "Erkek"
    case female = "Kadın"
}

// Fitess Hedefleri
enum FitnessGoal: String, Codable, CaseIterable {
    case loseWeight = "Kilo Vermek"
    case maintainWeight = "Kilo Korumak"
    case gainWeight = "Kilo Almak"
    case buildMuscle = "Kas Yapmak"
    case improveHealth = "Sağlığını İyileştirmek"
    
    var displayName: String {
        return self.rawValue
    }
}

// Aktiflik Seviyleri
enum ActivityLevel: String, Codable, CaseIterable {
    case sedentary = "Hareketsiz"
    case lightlyActive = "Az Hareketli"
    case moderatelyActive = "Orta Hareketli"
    case veryActive = "Çok Hareketli"
    case extraActive = "Ekstra Hareketli"
    
    var description: String {
        switch self {
        case .sedentary:
            return "Masa başı iş, çok az veya hiç egzersiz"
        case .lightlyActive:
            return "Haftada 1-3 gün hafif egzersiz"
        case .moderatelyActive:
            return "Haftada 3-5 gün orta düzey egzersiz"
        case .veryActive:
            return "Haftada 6-7 gün yoğun egzersiz"
        case .extraActive:
            return "Günde 2 kez egzersiz veya fiziksel iş"
        }
    }
} 
 
// MARK: - Debug Utilities
/// Production-safe debug printing
func debugPrint(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    #if DEBUG
    print(items, separator: separator, terminator: terminator)
    #endif
}

/// Production-safe debug print with custom prefix
func debugLog(_ message: String, prefix: String = "🔍") {
    #if DEBUG
    print("\(prefix) \(message)")
    #endif
} 
 