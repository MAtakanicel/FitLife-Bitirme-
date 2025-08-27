import Foundation
import SwiftUI
import FirebaseAuth

class AuthenticationManager: ObservableObject {
    static let shared = AuthenticationManager()
    
    @Published var isLoggedIn: Bool = false
    @Published var currentUserEmail: String = ""
    @Published var authenticationError: String?
    
    // isAuthenticated computed property - isLoggedIn ile aynı değeri döndürür
    var isAuthenticated: Bool {
        return isLoggedIn
    }
    
    // Firebase UID'yi döndür
    var currentUserUID: String? {
        return Auth.auth().currentUser?.uid
    }
    
    private let dataStorage = DataStorageService.shared
    private let coreDataService = CoreDataService.shared
    private let dataSyncService = DataSyncService.shared
    
    private init() {
        // Firebase configuration'ı tamamlandıktan sonra setup yapılacak
    }
    
    // Firebase configuration'ı tamamlandıktan sonra çağrılacak
    func initializeAfterFirebaseConfig() {
        print("🔧 AuthenticationManager initializeAfterFirebaseConfig başladı...")
        
        checkAuthenticationStatus()
        setupAuthStateListener()
            print("✅ AuthenticationManager initializeAfterFirebaseConfig tamamlandı")
    }
    
    // Manuel giriş flag'i - sadece login/register işlemlerinde true yapılır
    private var allowAutoLogin = false
    
    // MARK: - Firebase Auth State Listener
    private func setupAuthStateListener() {
        _ = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                // Sadece manuel giriş işlemlerinde otomatik state güncellemesine izin ver
                if user != nil && self?.allowAutoLogin == true {
                    // Kullanıcı manuel giriş yapmış - state'i güncelle
                    self?.isLoggedIn = true
                    self?.currentUserEmail = user?.email ?? ""
                    self?.dataStorage.setLoggedIn(true, email: user?.email ?? "")
                    
                    // Flag'i sıfırla
                    self?.allowAutoLogin = false
                    
                    // Kullanıcı değişikliği bildirimini gönder
                    NotificationCenter.default.post(name: Notification.Name("UserAuthStateChanged"), object: nil)
                    
                    // Auto sync'i tetikle
                        self?.dataSyncService.performFullSync()
                    
                    // UI güncellemesini zorla
                    self?.objectWillChange.send()
                } else if user == nil && self?.isLoggedIn == true {
                    // Kullanıcı çıkış yapmış
                    self?.isLoggedIn = false
                    self?.currentUserEmail = ""
                    self?.dataStorage.clearLoginData()
                    self?.allowAutoLogin = false
                    
                    // Kullanıcı değişikliği bildirimini gönder
                    NotificationCenter.default.post(name: Notification.Name("UserAuthStateChanged"), object: nil)
                    
                    // UI güncellemesini zorla
                    self?.objectWillChange.send()
                }
                // Eğer user != nil ama allowAutoLogin == false ise, hiçbir şey yapma (otomatik giriş engellendi)
            }
        }
    }
    
    // MARK: - Authentication Status
    func checkAuthenticationStatus() {
        print("🔍 Auth durumu kontrol ediliyor...")
        // Firebase'deki mevcut kullanıcı durumunu kontrol et
        if let currentUser = Auth.auth().currentUser {
            print("✅ Mevcut kullanıcı bulundu: \(currentUser.email ?? "email yok")")
            // Kullanıcı zaten giriş yapmış - durumu güncelle
            DispatchQueue.main.async {
                self.isLoggedIn = true
                self.currentUserEmail = currentUser.email ?? ""
                self.dataStorage.setLoggedIn(true, email: currentUser.email ?? "")
                print("✅ Auth durumu güncellendi - giriş yapılmış")
            }
        } else {
            print("ℹ️ Mevcut kullanıcı bulunamadı")
            // Kullanıcı giriş yapmamış
            DispatchQueue.main.async {
                self.isLoggedIn = false
                self.currentUserEmail = ""
                self.dataStorage.clearLoginData()
                print("✅ Auth durumu güncellendi - giriş yapılmamış")
            }
        }
        allowAutoLogin = false
    }
    
    // MARK: - Login
    func login(email: String, password: String, completion: @escaping (Bool, String?) -> Void) {
        // Basit doğrulama
        guard !email.isEmpty, !password.isEmpty else {
            authenticationError = "E-posta ve şifre alanları boş olamaz"
            completion(false, authenticationError)
            return
        }
        
        guard isValidEmail(email) else {
            authenticationError = "Geçerli bir e-posta adresi girin"
            completion(false, authenticationError)
            return
        }
        
        guard password.count >= 6 else {
            authenticationError = "Şifre en az 6 karakter olmalıdır"
            completion(false, authenticationError)
            return
        }
        
        // Manuel giriş flag'ini aktif et
        allowAutoLogin = true
        
        // Firebase Authentication ile giriş
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                if let error = error {
                    // Hata durumunda flag'i sıfırla
                    self?.allowAutoLogin = false
                    self?.authenticationError = error.localizedDescription
                    completion(false, error.localizedDescription)
                } else if result?.user != nil {
                    // Giriş başarılı - Firebase Auth State Listener otomatik olarak durumu güncelleyecek
                    self?.authenticationError = nil
                    
                    // Giriş başarılı olduktan sonra kullanıcı verilerini Firebase'den çek
                    self?.loadUserDataAfterLogin()
                    
                    completion(true, nil)
                } else {
                    // Hata durumunda flag'i sıfırla
                    self?.allowAutoLogin = false
                    self?.authenticationError = "Bilinmeyen bir hata oluştu"
                    completion(false, "Bilinmeyen bir hata oluştu")
                }
            }
        }
    }
    
    // MARK: - Register
    func register(name: String, email: String, password: String, completion: @escaping (Bool, String?) -> Void) {
        guard !name.isEmpty else {
            authenticationError = "İsim alanı boş olamaz"
            completion(false, authenticationError)
            return
        }
        
        guard !email.isEmpty else {
            authenticationError = "E-posta alanı boş olamaz"
            completion(false, authenticationError)
            return
        }
        
        guard isValidEmail(email) else {
            authenticationError = "Geçerli bir e-posta adresi girin"
            completion(false, authenticationError)
            return
        }
        
        guard password.count >= 6 else {
            authenticationError = "Şifre en az 6 karakter olmalıdır"
            completion(false, authenticationError)
            return
        }
        
        // Manuel kayıt flag'ini aktif et
        allowAutoLogin = true
        
        // Firebase Authentication ile kayıt
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                if let error = error {
                    // Hata durumunda flag'i sıfırla
                    self?.allowAutoLogin = false
                    self?.authenticationError = error.localizedDescription
                    completion(false, error.localizedDescription)
                } else if let user = result?.user {
                    // Kullanıcı profili güncelle
                    let changeRequest = user.createProfileChangeRequest()
                    changeRequest.displayName = name
                    changeRequest.commitChanges { error in
                        if let error = error {
                            print("Profil güncelleme hatası: \(error.localizedDescription)")
                        }
                    }
                    
                    // CoreData'da kullanıcı belgesi oluştur
                    self?.createUserDocument(userId: user.uid, name: name, email: email)
                    
                    // Kayıt başarılı - Firebase Auth State Listener otomatik olarak durumu güncelleyecek
                    self?.authenticationError = nil
                    completion(true, nil)
                } else {
                    // Hata durumunda flag'i sıfırla
                    self?.allowAutoLogin = false
                    self?.authenticationError = "Bilinmeyen bir hata oluştu"
                    completion(false, "Bilinmeyen bir hata oluştu")
                }
            }
        }
    }
    
    // MARK: - Create User Document
    private func createUserDocument(userId: String, name: String, email: String) {
        let _ = coreDataService.createOrUpdateUser(uid: userId, name: name, email: email)
    }
    
    // MARK: - Logout
    func logout() {
        // Çıkıştan önce verileri Firebase'e kaydet
        saveUserDataBeforeLogout()
        
        do {
            // Firebase oturumunu kapat
            try Auth.auth().signOut()
            
            // Otomatik giriş flag'ini sıfırla
            allowAutoLogin = false
            
            // Local state'i temizle
            DispatchQueue.main.async {
                self.isLoggedIn = false
                self.currentUserEmail = ""
            }
            
            // Yerel verileri temizle
            dataStorage.clearLoginData()
            dataStorage.clearRegistrationData()
            
            // Diğer servisleri de temizle
            clearAppData()
            
            // Kullanıcı değişikliği bildirimini gönder
            NotificationCenter.default.post(name: Notification.Name("UserAuthStateChanged"), object: nil)
            
            // UI güncellemesini zorla
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
            
            authenticationError = nil
            print("✅ Çıkış işlemi başarıyla tamamlandı")
        } catch let signOutError as NSError {
            authenticationError = "Çıkış yapılırken hata oluştu: \(signOutError.localizedDescription)"
            print("❌ Çıkış hatası: \(signOutError.localizedDescription)")
        }
    }
    
    // Uygulama verilerini temizle
    private func clearAppData() {
        let userEmail = currentUserEmail
        let userKey = userEmail.replacingOccurrences(of: "@", with: "_").replacingOccurrences(of: ".", with: "_")
        
        // Kullanıcı bazlı tüm anahtarları temizle
        let keysToRemove = [
            // SelectedDietService keys
            "selectedDiet_\(userKey)",
            "currentDayDiet_\(userKey)",
            "completedMealsToday_\(userKey)",
            "lastDietDate_\(userKey)",
            
            // MealService keys
            "SavedMeals_\(userKey)",
            
            // ExerciseTrackingService keys
            "todaysExerciseSessions_\(userKey)",
            "lastExerciseDate_\(userKey)",
            
            // Eski format keys (backward compatibility)
            "selectedDiet",
            "currentDayDiet",
            "completedMealsToday",
            "lastDietDate",
            "SavedMeals",
            "exerciseSessions",
            "lastExerciseDate"
        ]
        
        for key in keysToRemove {
            UserDefaults.standard.removeObject(forKey: key)
        }
        
        UserDefaults.standard.synchronize()
        print("🧹 Kullanıcı verileri temizlendi: \(userEmail)")
    }
    
    // MARK: - Password Reset
    func resetPassword(email: String, completion: @escaping (Bool, String?) -> Void) {
        guard !email.isEmpty else {
            authenticationError = "E-posta alanı boş olamaz"
            completion(false, authenticationError)
            return
        }
        
        guard isValidEmail(email) else {
            authenticationError = "Geçerli bir e-posta adresi girin"
            completion(false, authenticationError)
            return
        }
        
        // Firebase Authentication ile şifre sıfırlama
        Auth.auth().sendPasswordReset(withEmail: email) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.authenticationError = error.localizedDescription
                    completion(false, error.localizedDescription)
                } else {
                    self?.authenticationError = nil
                    completion(true, "Şifre sıfırlama e-postası gönderildi")
                }
            }
        }
    }
    
    // MARK: - Apple Sign In (Placeholder)
    func signInWithApple() {
        // Apple Sign In entegrasyonu için placeholder
        // Gerçek uygulamada AuthenticationServices framework kullanılacak
        authenticationError = "Apple ile giriş henüz desteklenmiyor"
    }
    

    
    // MARK: - Helper Methods
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    // MARK: - User Profile
    func updateUserProfile(name: String, email: String) {
        // Profil güncelleme işlemi
        if !email.isEmpty && isValidEmail(email) {
            currentUserEmail = email
            dataStorage.setLoggedIn(true, email: email)
        }
    }
    
    // MARK: - Account Deletion
    func deleteAccount(completion: @escaping (Bool, String?) -> Void) {
        guard let user = Auth.auth().currentUser else {
            authenticationError = "Kullanıcı oturumu bulunamadı"
            completion(false, authenticationError)
            return
        }
        
        // Önce CoreData'dan kullanıcı verilerini sil
        coreDataService.deleteUser(uid: user.uid)
        
        // Firebase Authentication'dan kullanıcıyı sil
        user.delete { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.authenticationError = error.localizedDescription
                    completion(false, error.localizedDescription)
                } else {
                    // Yerel verileri temizle
                    self?.dataStorage.clearLoginData()
                    self?.dataStorage.clearRegistrationData()
                    self?.authenticationError = nil
                    completion(true, nil)
                }
            }
        }
    }
    
    // MARK: - Firebase Integration Methods (for compatibility)
    func signUp(email: String, password: String, userData: UserRegistrationModel, completion: @escaping (Bool, String?) -> Void) {
        // Manuel kayıt flag'ini aktif et
        allowAutoLogin = true
        
        // Firebase Authentication ile kayıt
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                if let error = error {
                    // Hata durumunda flag'i sıfırla
                    self?.allowAutoLogin = false
                    self?.authenticationError = error.localizedDescription
                    completion(false, error.localizedDescription)
                } else if let user = result?.user {
                    // Kullanıcı profili güncelle
                    let changeRequest = user.createProfileChangeRequest()
                    changeRequest.displayName = userData.name
                    changeRequest.commitChanges { error in
                        if let error = error {
                            print("Profil güncelleme hatası: \(error.localizedDescription)")
                        }
                    }
                    
                    // CoreData'da detaylı kullanıcı belgesi oluştur
                    self?.createDetailedUserDocument(userId: user.uid, userData: userData, email: email)
                    
                    self?.authenticationError = nil
                    completion(true, nil)
                } else {
                    // Hata durumunda flag'i sıfırla
                    self?.allowAutoLogin = false
                    self?.authenticationError = "Bilinmeyen bir hata oluştu"
                    completion(false, "Bilinmeyen bir hata oluştu")
                }
            }
        }
    }
    
    // MARK: - Create Detailed User Document
    private func createDetailedUserDocument(userId: String, userData: UserRegistrationModel, email: String) {
        // CoreData'da detaylı kullanıcı bilgilerini güncelle
        var updatedUserData = userData
        updatedUserData.email = email
        coreDataService.updateUser(uid: userId, userData: updatedUserData)
        print("✅ CoreData: Detailed user document created successfully")
    }
    
    // MARK: - Data Management Methods
    
    /// Giriş yaptıktan sonra kullanıcı verilerini Firebase'den yükle
    private func loadUserDataAfterLogin() {
        print("🔄 Giriş sonrası kullanıcı verileri yükleniyor...")
        
        // Kısa bir delay ile Firebase bağlantısının stabil olmasını bekle
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Firebase'den kullanıcı verilerini çek
            FirebaseService.shared.getCurrentUserData { userData, error in
                DispatchQueue.main.async {
                    if let userData = userData {
                        print("✅ Giriş sonrası Firebase'den veri yüklendi")
                        
                        // UserDefaults'a cache'le (hızlı erişim için)
                        self.dataStorage.saveRegistrationData(userData)
                        print("✅ Kullanıcı verileri UserDefaults'a cache'lendi")
                        
                        // Debug: Cache'lenmiş veriyi kontrol et
                        if let cachedData = self.dataStorage.loadRegistrationData() {
                            print("🔍 Cache doğrulaması: İsim = \(cachedData.name), Boy = \(cachedData.height)")
                        }
                    } else {
                        print("⚠️ Giriş sonrası Firebase'den veri yüklenemedi: \(error ?? "Bilinmeyen hata")")
                        // Hata durumunda da devam et, kullanıcı daha sonra profil sayfasında görebilir
                    }
                }
            }
        }
    }
    
    /// Çıkış yapmadan önce kullanıcı verilerini Firebase'e kaydet
    private func saveUserDataBeforeLogout() {
        print("🔄 Çıkış öncesi kullanıcı verileri kaydediliyor...")
        
        // UserDefaults'tan mevcut veriyi al
        guard let userData = dataStorage.loadRegistrationData() else {
            print("⚠️ Kaydedilecek kullanıcı verisi bulunamadı")
            return
        }
        
        // Firebase'e kaydet (senkron olarak beklemeden, çünkü çıkış işlemi devam etmeli)
        FirebaseService.shared.updateUserProfile(userData: userData) { success, error in
            if success {
                print("✅ Çıkış öncesi veriler Firebase'e kaydedildi")
            } else {
                print("⚠️ Çıkış öncesi Firebase'e kaydetme başarısız: \(error ?? "Bilinmeyen hata")")
            }
        }
    }
}
