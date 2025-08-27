import Foundation

struct UserRegistrationModel: Codable {
    // Kişisel Bilgiler
    var name: String
    var email: String
    var password: String
    var gender: Gender
    var birthDate: Date
    
    // Fiziksel Bilgiler
    var height: Double // cm cinsinden
    var weight: Double // kg cinsinden
    var targetWeight: Double // kg cinsinden
    
    // Hedef Bilgileri
    var goal: FitnessGoal
    var activityLevel: ActivityLevel
    
    // MARK: - Initializer
    init(name: String, email: String, password: String, gender: Gender, birthDate: Date, height: Double, weight: Double, targetWeight: Double, goal: FitnessGoal, activityLevel: ActivityLevel) {
        self.name = name
        self.email = email
        self.password = password
        self.gender = gender
        self.birthDate = birthDate
        self.height = height
        self.weight = weight
        self.targetWeight = targetWeight
        self.goal = goal
        self.activityLevel = activityLevel
    }
    
    // Validasyon fonksiyonları
    func validateName() -> Bool {
        return Validators.isValidName(name)
    }
    
    func validateEmail() -> Bool {
        return Validators.isValidEmail(email)
    }
    
    func validatePassword() -> Bool {
        return Validators.isValidPassword(password)
    }
    
    func validateHeight() -> Bool {
        return Validators.isValidHeight(height)
    }
    
    func validateWeight() -> Bool {
        return Validators.isValidWeight(weight)
    }
    
    func validateTargetWeight() -> Bool {
        return Validators.isValidWeight(targetWeight)
    }
    
    func validateAge() -> Bool {
        return Validators.isAdult(birthDate)
    }
    
    // Tüm validasyonları kontrol et
    func validateAll() -> (isValid: Bool, errorMessage: String?) {
        if !validateName() {
            return (false, "İsim alanı boş olamaz")
        }
        
        if !validateEmail() {
            return (false, "Geçerli bir e-posta adresi girin")
        }
        
        if !validatePassword() {
            return (false, "Şifre en az \(AppConstants.Validation.minPasswordLength) karakter olmalıdır")
        }
        
        if !validateHeight() {
            return (false, "Geçerli bir boy değeri girin (\(AppConstants.Validation.minHeightCM)-\(AppConstants.Validation.maxHeightCM) cm)")
        }
        
        if !validateWeight() {
            return (false, "Geçerli bir kilo değeri girin (\(AppConstants.Validation.minWeightKG)-\(AppConstants.Validation.maxWeightKG) kg)")
        }
        
        if !validateTargetWeight() {
            return (false, "Geçerli bir hedef kilo değeri girin (\(AppConstants.Validation.minWeightKG)-\(AppConstants.Validation.maxWeightKG) kg)")
        }
        
        if !validateAge() {
            return (false, "\(AppConstants.Validation.minAge) yaşından küçükler kayıt olamaz")
        }
        
        return (true, nil)
    }
    
    // Hesaplanan Değerler
    var bmi: Double {
        // Sıfır değer kontrolü
        guard height > 0, weight > 0 else {
            return 25.0 // Varsayılan BMI değeri
        }
        
        // BMI = kilo(kg) / boy(m)²
        let heightInMeters = height / 100
        
        // Sıfıra bölme kontrolü
        guard heightInMeters > 0 else {
            return 25.0
        }
        
        let calculatedBMI = weight / (heightInMeters * heightInMeters)
        
        // Mantıklı aralık kontrolü (10-60 BMI)
        return max(10.0, min(60.0, calculatedBMI))
    }
    
    var dailyCalorieNeeds: Int {
        // Sıfır değer kontrolü
        guard height > 0, weight > 0 else {
            return 2000 // Varsayılan değer
        }
        
        // Mifflin-St Jeor formülü ile bazal metabolizma hızı hesaplama
        var bmr: Double
        
        let age = calculateAge()
        guard age > 0 else {
            return 2000 // Geçersiz yaş için varsayılan değer
        }
        
        if gender == .male {
            // Erkek: BMR = (10 × kilo) + (6.25 × boy) - (5 × yaş) + 5
            bmr = (10 * weight) + (6.25 * height) - (5 * age) + 5
        } else {
            // Kadın: BMR = (10 × kilo) + (6.25 × boy) - (5 × yaş) - 161
            bmr = (10 * weight) + (6.25 * height) - (5 * age) - 161
        }
        
        // BMR negatif olamaz
        guard bmr > 0 else {
            return 1200 // Minimum günlük kalori ihtiyacı
        }
        
        // Aktivite seviyesine göre çarpan
        let activityMultiplier: Double
        switch activityLevel {
        case .sedentary:
            activityMultiplier = 1.2      // Hareketsiz - Masa başı iş, çok az veya hiç egzersiz
        case .lightlyActive:
            activityMultiplier = 1.375    // Hafif aktif - Haftada 1-3 gün hafif egzersiz
        case .moderatelyActive:
            activityMultiplier = 1.55     // Orta düzey aktif - Haftada 3-5 gün orta düzey egzersiz
        case .veryActive:
            activityMultiplier = 1.725    // Çok aktif - Haftada 6-7 gün yoğun egzersiz
        case .extraActive:
            activityMultiplier = 1.9      // Aşırı aktif (atlet seviyesi) - Günde 2 kez egzersiz veya fiziksel iş
        }
        
        let finalCalories = Int(bmr * activityMultiplier)
        
        // Sağlıklı aralık kontrolü (1200-5000 kcal)
        return max(1200, min(5000, finalCalories))
    }
    
    // Yardımcı fonksiyonlar
    private func calculateAge() -> Double {
        return Double(getAge(from: birthDate))
    }
    
    // Veritabanına gönderme için JSON dönüşümü
    func toJSON() -> Data? {
        return try? JSONEncoder().encode(self)
    }
}

//Yaş hesaplama fonksiyonu
func getAge(from birthDate: Date) -> Int {
    let calendar = Calendar.current
    let ageComponents = calendar.dateComponents([.year], from: birthDate, to: Date())
    return ageComponents.year ?? 0
} 
