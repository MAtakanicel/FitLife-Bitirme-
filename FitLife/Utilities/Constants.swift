import Foundation
import SwiftUI

struct AppConstants {
    // Kayıt işlemi adımları
    static let totalRegistrationSteps = 7
    
    // Validation
    struct Validation {
        static let minPasswordLength = 6
        static let minNameLength = 2
        static let minHeightCM = 100.0
        static let maxHeightCM = 250.0
        static let minWeightKG = 30.0
        static let maxWeightKG = 300.0
        static let minAge = 18
    }
    
    // UI
    struct UI {
        static let buttonCornerRadius: CGFloat = 10
        static let textFieldCornerRadius: CGFloat = 10
        static let standardPadding: CGFloat = 20
    }
}

// Kullanıcı yaşı hesaplaması için yardımcı fonksiyon
func calculateAge(from birthDate: Date) -> Int {
    let calendar = Calendar.current
    let ageComponents = calendar.dateComponents([.year], from: birthDate, to: Date())
    return ageComponents.year ?? 0
} 
 