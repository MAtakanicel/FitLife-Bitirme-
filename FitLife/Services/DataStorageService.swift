import Foundation

class DataStorageService {
    static let shared = DataStorageService()
    
    private let userDefaults = UserDefaults.standard
    
    // Current user UID for user-specific data
    private var currentUserUID: String {
        return AuthenticationManager.shared.currentUserUID ?? "anonymous"
    }
    
    private init() {}
    
    // MARK: - Kullanıcı Kayıt Dataları
    
    private let registrationDataKey = "registrationData"
    
    func saveRegistrationData(_ data: UserRegistrationModel) {
        debugLog("🔍 DEBUG: saveRegistrationData çağrıldı")
        debugLog("🔍 DEBUG: Kaydedilecek data: \(data.name)")
        
        do {
            let encoded = try JSONEncoder().encode(data)
            debugLog("🔍 DEBUG: JSON encoding başarılı, boyut: \(encoded.count) bytes")
            
            userDefaults.set(encoded, forKey: registrationDataKey)
            debugLog("✅ DEBUG: UserDefaults'a kaydedildi")
            
            // Doğrulama için geri oku
            if let savedData = userDefaults.data(forKey: registrationDataKey) {
                debugLog("✅ DEBUG: Kaydedilen veri doğrulandı, boyut: \(savedData.count) bytes")
            } else {
                debugLog("❌ DEBUG: Kaydedilen veri okunamadı!")
            }
        } catch {
            debugLog("❌ DEBUG: Registration data kaydetme hatası: \(error)")
        }
    }
    
    func loadRegistrationData() -> UserRegistrationModel? {
        guard let data = userDefaults.data(forKey: registrationDataKey) else {
            return nil
        }
        
        do {
            let decoded = try JSONDecoder().decode(UserRegistrationModel.self, from: data)
            return decoded
        } catch {
            debugLog("Error loading registration data: \(error)")
            return nil
        }
    }
    
    func clearRegistrationData() {
        userDefaults.removeObject(forKey: registrationDataKey)
    }
    
    // MARK: - Authentication
    
    private let isLoggedInKey = "isLoggedIn"
    private let userEmailKey = "userEmail"
    
    func setLoggedIn(_ value: Bool, email: String = "") {
        userDefaults.set(value, forKey: isLoggedInKey)
        userDefaults.set(email, forKey: userEmailKey)
    }
    
    func isLoggedIn() -> Bool {
        return userDefaults.bool(forKey: isLoggedInKey)
    }
    
    func getUserEmail() -> String? {
        return userDefaults.string(forKey: userEmailKey)
    }
    
    func getUserName() -> String? {
        // Kayıt verilerinden kullanıcı adını al
        return loadRegistrationData()?.name
    }
    
    func clearLoginData() {
        userDefaults.removeObject(forKey: isLoggedInKey)
        userDefaults.removeObject(forKey: userEmailKey)
    }
    
    // MARK: - Uygulama Ayarları
    
    private let notificationsEnabledKey = "notificationsEnabled"
    private let darkModeEnabledKey = "darkModeEnabled"
    
    func setNotificationsEnabled(_ value: Bool) {
        userDefaults.set(value, forKey: notificationsEnabledKey)
    }
    
    func areNotificationsEnabled() -> Bool {
        return userDefaults.bool(forKey: notificationsEnabledKey)
    }
    
    func setDarkModeEnabled(_ value: Bool) {
        userDefaults.set(value, forKey: darkModeEnabledKey)
    }
    
    func isDarkModeEnabled() -> Bool {
        //varsayılan değer true
        if userDefaults.object(forKey: darkModeEnabledKey) == nil {
            return true
        }
        return userDefaults.bool(forKey: darkModeEnabledKey)
    }
    
    
    // MARK: - Kullanıcı Tercihleri
    
    private let weightUnitKey = "weightUnit"
    private let regionKey = "userRegion"
    private let dataSharingEnabledKey = "dataSharingEnabled"
    private let healthAppSyncEnabledKey = "healthAppSyncEnabled"
    private let appleWatchSyncEnabledKey = "appleWatchSyncEnabled"
    
    // Ağırlık birimi tercihi
    func setWeightUnit(_ unit: WeightUnit) {
        userDefaults.set(unit == .kg ? "kg" : "lb", forKey: weightUnitKey)
    }
    
    func getWeightUnit() -> WeightUnit {
        return userDefaults.string(forKey: weightUnitKey) == "lb" ? .lb : .kg
    }
    
    // Bölge tercihi
    func setRegion(_ region: String) {
        userDefaults.set(region, forKey: regionKey)
    }
    
    func getRegion() -> String {
        return userDefaults.string(forKey: regionKey) ?? "Türkiye"
    }
    
    // Veri paylaşımı tercihleri
    func setDataSharingEnabled(_ enabled: Bool) {
        userDefaults.set(enabled, forKey: dataSharingEnabledKey)
    }
    
    func isDataSharingEnabled() -> Bool {
        // Varsayılan olarak kapalı
        if userDefaults.object(forKey: dataSharingEnabledKey) == nil {
            return false
        }
        return userDefaults.bool(forKey: dataSharingEnabledKey)
    }
    
    // Apple Sağlık uygulaması senkronizasyonu
    func setHealthAppSyncEnabled(_ enabled: Bool) {
        userDefaults.set(enabled, forKey: healthAppSyncEnabledKey)
    }
    
    func isHealthAppSyncEnabled() -> Bool {
        return userDefaults.bool(forKey: healthAppSyncEnabledKey)
    }
    
    // Apple Watch senkronizasyonu
    func setAppleWatchSyncEnabled(_ enabled: Bool) {
        userDefaults.set(enabled, forKey: appleWatchSyncEnabledKey)
    }
    
    func isAppleWatchSyncEnabled() -> Bool {
        return userDefaults.bool(forKey: appleWatchSyncEnabledKey)
    }
    
    // MARK: - Diet Service Data (User-Specific)
    
    func saveSelectedDiet<T: Codable>(_ diet: T) {
        if let data = try? JSONEncoder().encode(diet) {
            userDefaults.set(data, forKey: "selectedDiet_\(currentUserUID)")
        }
    }
    
    func loadSelectedDiet<T: Codable>(_ type: T.Type) -> T? {
        guard let data = userDefaults.data(forKey: "selectedDiet_\(currentUserUID)") else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
    
    func setCurrentDietDay(_ day: Int) {
        userDefaults.set(day, forKey: "currentDayDiet_\(currentUserUID)")
    }
    
    func getCurrentDietDay() -> Int {
        return userDefaults.integer(forKey: "currentDayDiet_\(currentUserUID)")
    }
    
    func saveCompletedMeals<T: Codable>(_ meals: T) {
        if let data = try? JSONEncoder().encode(meals) {
            userDefaults.set(data, forKey: "completedMealsToday_\(currentUserUID)")
            userDefaults.set(Date(), forKey: "lastDietDate_\(currentUserUID)")
        }
    }
    
    func loadCompletedMeals<T: Codable>(_ type: T.Type) -> T? {
        guard let data = userDefaults.data(forKey: "completedMealsToday_\(currentUserUID)") else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
    
    func setDietStartDate(_ date: Date) {
        userDefaults.set(date, forKey: "dietStartDate_\(currentUserUID)")
    }
    
    func getDietStartDate() -> Date? {
        return userDefaults.object(forKey: "dietStartDate_\(currentUserUID)") as? Date
    }
    
    func getLastDietDate() -> Date? {
        return userDefaults.object(forKey: "lastDietDate_\(currentUserUID)") as? Date
    }
    
    func clearDietData() {
        userDefaults.removeObject(forKey: "selectedDiet_\(currentUserUID)")
        userDefaults.removeObject(forKey: "currentDayDiet_\(currentUserUID)")
        userDefaults.removeObject(forKey: "completedMealsToday_\(currentUserUID)")
        userDefaults.removeObject(forKey: "dietStartDate_\(currentUserUID)")
        userDefaults.removeObject(forKey: "lastDietDate_\(currentUserUID)")
    }
    
    // MARK: - Sync Service Data (Transferred from DataSyncService)
    
    private let lastSyncDateKey = "lastSyncDate"
    
    func setLastSyncDate(_ date: Date) {
        userDefaults.set(date, forKey: lastSyncDateKey)
    }
    
    func getLastSyncDate() -> Date? {
        return userDefaults.object(forKey: lastSyncDateKey) as? Date
    }
    
    // MARK: - Localization Data (Transferred from LocalizationService)
    
    private let appLanguageKey = "app_language"
    
    func setAppLanguage(_ language: String) {
        userDefaults.set(language, forKey: appLanguageKey)
    }
    
    func getAppLanguage() -> String? {
        return userDefaults.string(forKey: appLanguageKey)
    }
    
    // MARK: - Exercise Tracking Data (User-Specific)
    
    func saveTodaysExercise<T: Codable>(_ exercise: T) {
        if let data = try? JSONEncoder().encode(exercise) {
            userDefaults.set(data, forKey: "todaysExerciseSessions_\(currentUserUID)")
        }
    }
    
    func loadTodaysExercise<T: Codable>(_ type: T.Type) -> T? {
        guard let data = userDefaults.data(forKey: "todaysExerciseSessions_\(currentUserUID)") else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
    
    func setLastExerciseDate(_ date: Date) {
        userDefaults.set(date, forKey: "lastExerciseDate_\(currentUserUID)")
    }
    
    func getLastExerciseDate() -> Date? {
        return userDefaults.object(forKey: "lastExerciseDate_\(currentUserUID)") as? Date
    }
    
    // MARK: - Meal Data (Transferred from MealService)
    
    private let savedMealsKey = "saved_meals"
    
    func saveMeals<T: Codable>(_ meals: T) {
        if let data = try? JSONEncoder().encode(meals) {
            userDefaults.set(data, forKey: savedMealsKey)
        }
    }
    
    func loadMeals<T: Codable>(_ type: T.Type) -> T? {
        if let data = userDefaults.data(forKey: savedMealsKey) {
            return try? JSONDecoder().decode(type, from: data)
        }
        return nil
    }
} 
 