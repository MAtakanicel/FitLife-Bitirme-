import Foundation

struct Validators {
    // MARK: - Text Validation
    
    static func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    static func isValidName(_ name: String) -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedName.isEmpty && trimmedName.count >= AppConstants.Validation.minNameLength
    }
    
    static func isValidPassword(_ password: String) -> Bool {
        return password.count >= AppConstants.Validation.minPasswordLength
    }
    
    // MARK: - Password Gücü
    
    static func getPasswordStrength(_ password: String) -> PasswordStrength {
        if password.isEmpty {
            return .weak
        }
        
        var score = 0
        
        // Uzunluk kontrolü
        if password.count >= 8 {
            score += 1
        }
        
        // Uppercase Kontrolü
        if password.contains(where: { $0.isUppercase }) {
            score += 1
        }
        
        // Lowercase Kontrolü
        if password.contains(where: { $0.isLowercase }) {
            score += 1
        }
        
        // Rakam Kontrolü
        if password.contains(where: { $0.isNumber }) {
            score += 1
        }
        
        // Özel karakter Kontrolü
        if password.contains(where: { !$0.isLetter && !$0.isNumber }) {
            score += 1
        }
        
        switch score {
        case 0...2:
            return .weak
        case 3...4:
            return .medium
        default:
            return .strong
        }
    }
    
    // MARK: - Fiziksel data valitadion
    
    static func isValidHeight(_ height: Double, unit: HeightUnit = .cm) -> Bool {
        let heightInCm = unit == .inch ? height * 2.54 : height
        return heightInCm >= AppConstants.Validation.minHeightCM && heightInCm <= AppConstants.Validation.maxHeightCM
    }
    
    static func isValidWeight(_ weight: Double, unit: WeightUnit = .kg) -> Bool {
        let weightInKg = unit == .lb ? weight / 2.20462 : weight
        return weightInKg >= AppConstants.Validation.minWeightKG && weightInKg <= AppConstants.Validation.maxWeightKG
    }
    
    static func isAdult(_ birthDate: Date) -> Bool {
        let age = calculateAge(from: birthDate)
        return age >= AppConstants.Validation.minAge
    }
} 
