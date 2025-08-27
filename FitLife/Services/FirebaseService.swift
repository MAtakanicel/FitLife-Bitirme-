import Foundation
import FirebaseFirestore
import FirebaseAuth
import FirebaseCore
import CoreData

class FirebaseService: ObservableObject {
    static let shared = FirebaseService()
    
    private var db: Firestore {
        return Firestore.firestore()
    }
    
    private var auth: Auth {
        return Auth.auth()
    }
    
    private let coreDataService = CoreDataService.shared
    private var isConfigured = false
    
    private init() {}
    
    // Firebase configure edildikten sonra çağrılacak
    func configure() {
        guard FirebaseApp.app() != nil else {
            print("❌ Firebase henüz configure edilmemiş!")
            return
        }
        isConfigured = true
        print("✅ FirebaseService configured")
    }
    
    // Firebase'in configure edilip edilmediğini kontrol et
    private func checkConfiguration() -> Bool {
        guard isConfigured else {
            print("❌ FirebaseService henüz configure edilmemiş. Lütfen önce configure() çağırın.")
            print("🔍 Firebase App durumu: \(FirebaseApp.app() != nil ? "Var" : "Yok")")
            return false
        }
        print("✅ Firebase konfigürasyonu doğrulandı")
        return true
    }
    
    // MARK: - Helper Methods
    
    private var currentUserId: String? {
        let userId = auth.currentUser?.uid
        if userId == nil {
            print("⚠️ Firebase Auth: Kullanıcı oturumu bulunamadı!")
            print("🔍 Auth durumu: \(auth.currentUser == nil ? "Kullanıcı yok" : "Kullanıcı var")")
        } else {
            print("✅ Firebase Auth: Kullanıcı ID = \(userId!)")
        }
        return userId
    }
    
    // MARK: - CoreData to Firestore Sync
    
    func syncAllDataToFirestore(completion: @escaping (Bool, String?) -> Void) {
        guard checkConfiguration() else {
            completion(false, "Firebase servis yapılandırılmamış")
            return
        }
        
        guard let userId = currentUserId else {
            completion(false, "Kullanıcı oturumu bulunamadı")
            return
        }
        
        // CoreData'dan tüm verileri al ve Firestore'a gönder
        syncUserDataToFirestore { [weak self] success, error in
            if success {
                self?.syncMealsToFirestore { success, error in
                    if success {
                        self?.syncWeightHistoryToFirestore { success, error in
                            completion(success, error)
                        }
                    } else {
                        completion(false, error)
                    }
                }
            } else {
                completion(false, error)
            }
        }
    }
    
    private func syncUserDataToFirestore(completion: @escaping (Bool, String?) -> Void) {
        guard let userId = currentUserId else {
            completion(false, "Kullanıcı oturumu bulunamadı")
            return
        }
        
        // Kullanıcıyı al veya oluştur
        var user = coreDataService.fetchUser(uid: userId)
        if user == nil {
            print("⚠️ CoreData'da kullanıcı bulunamadı, yeni kullanıcı oluşturuluyor...")
            // DataStorageService'den kullanıcı bilgilerini al
            if let registrationData = DataStorageService.shared.loadRegistrationData() {
                user = coreDataService.createOrUpdateUser(
                    uid: userId, 
                    name: registrationData.name, 
                    email: registrationData.email
                )
                // Diğer bilgileri de ekle
                user?.gender = registrationData.gender.rawValue
                user?.birthday = registrationData.birthDate
                user?.height = registrationData.height
                user?.weight = registrationData.weight
                user?.targetWeight = registrationData.targetWeight
                user?.fitnessGoal = registrationData.goal.rawValue
                user?.activityLevel = registrationData.activityLevel.rawValue
                coreDataService.save()
                print("✅ CoreData'da yeni kullanıcı oluşturuldu")
            } else {
                // Hiç veri yoksa boş kullanıcı oluştur
                user = coreDataService.createUser(uid: userId, name: "", email: auth.currentUser?.email ?? "")
                print("⚠️ Minimal kullanıcı oluşturuldu")
            }
        }
        
        guard let user = user else {
            completion(false, "Kullanıcı verisi oluşturulamadı")
            return
        }
        
        let userRef = db.collection("users").document(userId)
        
        var data: [String: Any] = [
            "uid": userId,
            "lastUpdated": Timestamp(date: Date()),
            "syncedAt": Timestamp(date: Date())
        ]
        
        // Sadece boş olmayan verileri ekle
        if let name = user.name, !name.isEmpty {
            data["name"] = name
        }
        if let email = user.email, !email.isEmpty {
            data["email"] = email
        }
        if let gender = user.gender, !gender.isEmpty {
            data["gender"] = gender
        }
        if let birthday = user.birthday {
            data["birthDate"] = Timestamp(date: birthday)
        }
        if user.height > 0 {
            data["height"] = user.height
        }
        if user.weight > 0 {
            data["weight"] = user.weight
        }
        if user.targetWeight > 0 {
            data["targetWeight"] = user.targetWeight
        }
        if let fitnessGoal = user.fitnessGoal, !fitnessGoal.isEmpty {
            data["goal"] = fitnessGoal
        }
        if let activityLevel = user.activityLevel, !activityLevel.isEmpty {
            data["activityLevel"] = activityLevel
        }
        if let createdAt = user.createdAt {
            data["createdAt"] = Timestamp(date: createdAt)
        }
        
        userRef.setData(data, merge: true) { error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(false, "Kullanıcı verisi sync hatası: \(error.localizedDescription)")
                } else {
                    print("✅ Kullanıcı verisi Firestore'a senkronize edildi")
                    completion(true, nil)
                }
            }
        }
    }
    
    private func syncMealsToFirestore(completion: @escaping (Bool, String?) -> Void) {
        guard let userId = currentUserId else {
            completion(false, "Kullanıcı oturumu bulunamadı")
            return
        }
        
        // CoreData'dan senkronize edilmemiş öğünleri al
        let unsyncedMeals = coreDataService.fetchUnsyncedMeals(for: userId)
        
        if unsyncedMeals.isEmpty {
            print("✅ Senkronize edilecek öğün bulunamadı")
            completion(true, nil)
            return
        }
        
        let group = DispatchGroup()
        var hasError = false
        var errorMessage: String?
        
        for meal in unsyncedMeals {
            group.enter()
            
            let mealRef = db.collection("users").document(userId).collection("meals").document()
            
            let data: [String: Any] = [
                "id": meal.id?.uuidString ?? UUID().uuidString,
                "foodName": meal.foodName ?? "",
                "calories": meal.calories,
                "protein": meal.protein,
                "carbs": meal.carbs,
                "fat": meal.fat,
                "mealType": meal.mealType ?? "",
                "quantity": meal.quantity,
                "dateAdded": Timestamp(date: meal.dateAdded ?? Date()),
                "createdAt": Timestamp(date: meal.createdAt ?? Date()),
                "userUID": userId
            ]
            
            mealRef.setData(data) { [weak self] error in
                if let error = error {
                    hasError = true
                    errorMessage = "Öğün sync hatası: \(error.localizedDescription)"
                } else {
                    // CoreData'da senkronize edildi olarak işaretle
                    self?.coreDataService.markMealAsSynced(meal: meal, firestoreId: mealRef.documentID)
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            if hasError {
                completion(false, errorMessage)
            } else {
                print("✅ \(unsyncedMeals.count) öğün Firestore'a senkronize edildi")
                completion(true, nil)
            }
        }
    }
    
    private func syncWeightHistoryToFirestore(completion: @escaping (Bool, String?) -> Void) {
        guard let userId = currentUserId else {
            completion(false, "Kullanıcı oturumu bulunamadı")
            return
        }
        
        // CoreData'dan senkronize edilmemiş kilo kayıtlarını al
        let unsyncedWeights = coreDataService.fetchUnsyncedWeightEntries(for: userId)
        
        if unsyncedWeights.isEmpty {
            print("✅ Senkronize edilecek kilo kaydı bulunamadı")
            completion(true, nil)
            return
        }
        
        let group = DispatchGroup()
        var hasError = false
        var errorMessage: String?
        
        for weightEntry in unsyncedWeights {
            group.enter()
            
            let weightRef = db.collection("users").document(userId).collection("weightHistory").document()
            
            let data: [String: Any] = [
                "id": weightEntry.id?.uuidString ?? UUID().uuidString,
                "weight": weightEntry.weight,
                "date": Timestamp(date: weightEntry.date ?? Date()),
                "createdAt": Timestamp(date: weightEntry.createdAt ?? Date()),
                "userUID": userId
            ]
            
            weightRef.setData(data) { [weak self] error in
                if let error = error {
                    hasError = true
                    errorMessage = "Kilo kaydı sync hatası: \(error.localizedDescription)"
                } else {
                    // CoreData'da senkronize edildi olarak işaretle
                    self?.coreDataService.markWeightEntryAsSynced(weightEntry: weightEntry, firestoreId: weightRef.documentID)
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            if hasError {
                completion(false, errorMessage)
            } else {
                print("✅ \(unsyncedWeights.count) kilo kaydı Firestore'a senkronize edildi")
                completion(true, nil)
            }
        }
    }
    
    // MARK: - Firestore to CoreData Sync
    
    func syncDataFromFirestore(completion: @escaping (Bool, String?) -> Void) {
        print("🔍 Firestore'dan senkronizasyon başlıyor...")
        
        guard checkConfiguration() else {
            print("❌ Firebase konfigürasyonu başarısız")
            completion(false, "Firebase servis yapılandırılmamış")
            return
        }
        
        guard let userId = currentUserId else {
            print("❌ Kullanıcı oturumu bulunamadı")
            completion(false, "Kullanıcı oturumu bulunamadı")
            return
        }
        
        print("📁 Kullanıcı belgesi sorgulanıyor: users/\(userId)")
        let userRef = db.collection("users").document(userId)
        
        userRef.getDocument { [weak self] document, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Firestore sorgu hatası: \(error.localizedDescription)")
                    completion(false, "Firestore'dan veri alma hatası: \(error.localizedDescription)")
                    return
                }
                
                print("📄 Firestore belgesi alındı")
                print("🔍 Belge var mı: \(document?.exists ?? false)")
                
                guard let document = document, document.exists,
                      let data = document.data() else {
                    print("❌ Kullanıcı belgesi bulunamadı veya boş")
                    completion(false, "Firestore'da kullanıcı verisi bulunamadı")
                    return
                }
                
                print("✅ Kullanıcı verisi bulundu, CoreData'ya aktarılıyor...")
                print("📊 Veri içeriği: \(data.keys.joined(separator: ", "))")
                
                self?.updateCoreDataFromFirestore(data: data, userId: userId)
                completion(true, nil)
            }
        }
    }
    
    private func updateCoreDataFromFirestore(data: [String: Any], userId: String) {
        // Mevcut kullanıcıyı al veya oluştur
        let user = coreDataService.fetchUser(uid: userId) ?? 
                   coreDataService.createUser(uid: userId, name: "", email: "")
        
        // Firestore'dan gelen verileri CoreData'ya aktar
        if let name = data["name"] as? String {
            user.name = name
        }
        if let email = data["email"] as? String {
            user.email = email
        }
        if let gender = data["gender"] as? String {
            user.gender = gender
        }
        if let birthDate = data["birthDate"] as? Timestamp {
            user.birthday = birthDate.dateValue()
        }
        if let height = data["height"] as? Double {
            user.height = height
        }
        if let weight = data["weight"] as? Double {
            user.weight = weight
        }
        if let targetWeight = data["targetWeight"] as? Double {
            user.targetWeight = targetWeight
        }
        if let goal = data["goal"] as? String {
            user.fitnessGoal = goal
        }
        if let activityLevel = data["activityLevel"] as? String {
            user.activityLevel = activityLevel
        }
        
        user.lastUpdated = Date()
        coreDataService.save()
        
        print("✅ Firestore verisi CoreData'ya senkronize edildi")
    }
    
    // MARK: - Auto Sync Methods
    
    func enableAutoSync() {
        // Kullanıcı giriş yaptığında otomatik sync
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(userDidSignIn),
            name: .AuthStateDidChange,
            object: nil
        )
    }
    
    @objc private func userDidSignIn() {
        if currentUserId != nil {
            // Önce Firestore'dan al
            syncDataFromFirestore { [weak self] success, error in
                if success {
                    // Sonra CoreData'dan Firestore'a gönder
                    self?.syncAllDataToFirestore { success, error in
                        if success {
                            print("✅ Auto sync completed successfully")
                        } else {
                            print("❌ Auto sync failed: \(error ?? "Unknown error")")
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Manual Sync Triggers
    
    func manualSyncToFirestore(completion: @escaping (Bool, String?) -> Void) {
        syncAllDataToFirestore(completion: completion)
    }
    
    func manualSyncFromFirestore(completion: @escaping (Bool, String?) -> Void) {
        syncDataFromFirestore(completion: completion)
    }

    // MARK: - User Profile Management
    
    func getCurrentUserData(completion: @escaping (UserRegistrationModel?, String?) -> Void) {
        guard checkConfiguration() else {
            completion(nil, "Firebase servis yapılandırılmamış")
            return
        }
        
        guard let userId = currentUserId else {
            completion(nil, "Kullanıcı oturumu bulunamadı")
            return
        }
        
        print("🔄 Firebase'den kullanıcı verileri yükleniyor...")
        
        // Önce CoreData'dan dene
        if let userData = coreDataService.getUser(uid: userId) {
            print("✅ CoreData'dan kullanıcı verileri yüklendi")
            completion(userData, nil)
            return
        }
        
        // CoreData'da yoksa Firestore'dan çek
        print("⚠️ CoreData'da veri yok, Firestore'dan çekiliyor...")
        db.collection("users").document(userId).getDocument { snapshot, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Firestore'dan veri çekme hatası: \(error.localizedDescription)")
                    completion(nil, error.localizedDescription)
                    return
                }
                
                guard let data = snapshot?.data() else {
                    print("❌ Firestore'da kullanıcı verileri bulunamadı")
                    completion(nil, "Kullanıcı verileri bulunamadı")
                    return
                }
                
                // Firestore'dan gelen veriyi UserRegistrationModel'e çevir
                let userData = UserRegistrationModel(
                    name: data["name"] as? String ?? "",
                    email: data["email"] as? String ?? "",
                    password: "", // Password Firestore'da saklanmaz
                    gender: Gender(rawValue: data["gender"] as? String ?? "Erkek") ?? .male,
                    birthDate: (data["birthDate"] as? Timestamp)?.dateValue() ?? Date(),
                    height: data["height"] as? Double ?? 0.0,
                    weight: data["weight"] as? Double ?? 0.0,
                    targetWeight: data["targetWeight"] as? Double ?? 0.0,
                    goal: FitnessGoal(rawValue: data["goal"] as? String ?? "Kilo Korumak") ?? .maintainWeight,
                    activityLevel: ActivityLevel(rawValue: data["activityLevel"] as? String ?? "Orta Hareketli") ?? .moderatelyActive
                )
                
                // Çekilen veriyi CoreData'ya da kaydet (cache için)
                self.coreDataService.updateUser(uid: userId, userData: userData)
                
                print("✅ Firebase'den kullanıcı verileri başarıyla yüklendi")
                completion(userData, nil)
            }
        }
    }
    
    func updateUserProfile(userData: UserRegistrationModel, completion: @escaping (Bool, String?) -> Void) {
        guard checkConfiguration() else {
            completion(false, "Firebase servis yapılandırılmamış")
            return
        }
        
        guard let userId = currentUserId else {
            completion(false, "Kullanıcı oturumu bulunamadı")
            return
        }
        
        print("🔄 Kullanıcı profili güncelleniyor...")
        
        // Önce CoreData'yı güncelle
        coreDataService.updateUser(uid: userId, userData: userData)
        print("✅ CoreData kullanıcı bilgileri güncellendi")
        
        // Sonra Firestore'a sync et
        syncUserDataToFirestore { success, error in
            if success {
                print("✅ Kullanıcı profili Firestore'a senkronize edildi")
            } else {
                print("❌ Firestore sync hatası: \(error ?? "Bilinmeyen hata")")
            }
            completion(success, error)
        }
    }

    // MARK: - Meal Tracking
    
    func saveMeal(meal: MealData, completion: @escaping (Bool, String?) -> Void) {
        guard let userId = currentUserId else {
            completion(false, "Kullanıcı oturumu bulunamadı")
            return
        }
        
        let mealRef = db.collection("users").document(userId).collection("meals").document()
        
        let data: [String: Any] = [
            "name": meal.foodName,
            "calories": meal.calories,
            "protein": meal.protein,
            "carbs": meal.carbs,
            "fat": meal.fat,
            "mealType": meal.mealType.rawValue,
            "date": meal.dateAdded,
            "createdAt": Timestamp(date: Date())
        ]
        
        mealRef.setData(data) { error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(false, error.localizedDescription)
                } else {
                    completion(true, nil)
                }
            }
        }
    }
    
    func getMealsForDate(_ date: Date, completion: @escaping ([MealData]) -> Void) {
        guard let userId = currentUserId else {
            completion([])
            return
        }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        db.collection("users").document(userId).collection("meals")
            .whereField("date", isGreaterThanOrEqualTo: startOfDay)
            .whereField("date", isLessThan: endOfDay)
            .order(by: "date")
            .getDocuments { snapshot, error in
                DispatchQueue.main.async {
                    guard let documents = snapshot?.documents else {
                        completion([])
                        return
                    }
                    
                    let meals = documents.compactMap { doc -> MealData? in
                        let data = doc.data()
                        return MealData(
                            id: doc.documentID,
                            foodName: data["name"] as? String ?? "",
                            quantity: 1.0,
                            calories: data["calories"] as? Double ?? 0,
                            carbs: data["carbs"] as? Double ?? 0,
                            protein: data["protein"] as? Double ?? 0,
                            fat: data["fat"] as? Double ?? 0,
                            mealType: MealData.MealType(rawValue: data["mealType"] as? String ?? "") ?? .breakfast,
                            dateAdded: (data["date"] as? Timestamp)?.dateValue() ?? Date()
                        )
                    }
                    
                    completion(meals)
                }
            }
    }
    
    // MARK: - Weight Tracking
    
    func saveWeightEntry(weight: Double, date: Date, completion: @escaping (Bool, String?) -> Void) {
        guard let userId = currentUserId else {
            completion(false, "Kullanıcı oturumu bulunamadı")
            return
        }
        
        let weightRef = db.collection("users").document(userId).collection("weightHistory").document()
        
        let data: [String: Any] = [
            "weight": weight,
            "date": date,
            "createdAt": Timestamp(date: Date())
        ]
        
        weightRef.setData(data) { error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(false, error.localizedDescription)
                } else {
                    completion(true, nil)
                }
            }
        }
    }
    
    func getWeightHistory(completion: @escaping ([WeightData]) -> Void) {
        guard let userId = currentUserId else {
            completion([])
            return
        }
        
        db.collection("users").document(userId).collection("weightHistory")
            .order(by: "date", descending: true)
            .limit(to: 30) // Son 30 kayıt
            .getDocuments { snapshot, error in
                DispatchQueue.main.async {
                    guard let documents = snapshot?.documents else {
                        completion([])
                        return
                    }
                    
                    let weights = documents.compactMap { doc -> WeightData? in
                        let data = doc.data()
                        return WeightData(
                            id: doc.documentID,
                            weight: data["weight"] as? Double ?? 0,
                            date: (data["date"] as? Timestamp)?.dateValue() ?? Date()
                        )
                    }
                    
                    completion(weights)
                }
            }
    }
    
    // MARK: - Daily Summary
    
    func getDailySummary(for date: Date, completion: @escaping (DailySummary?) -> Void) {
        getMealsForDate(date) { meals in
            let totalCaloriesConsumed = meals.reduce(0) { $0 + $1.calories }
            
            let summary = DailySummary(
                date: date,
                totalCaloriesConsumed: totalCaloriesConsumed
            )
            
            completion(summary)
        }
    }
    
    // MARK: - Deinit
    deinit {
        NotificationCenter.default.removeObserver(self)
        debugLog("🗑️ FirebaseService deinit - observer temizlendi")
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let AuthStateDidChange = Notification.Name("AuthStateDidChange")
}