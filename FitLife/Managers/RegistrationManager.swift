import Foundation
import SwiftUI

class RegistrationManager: ObservableObject {
    static let shared = RegistrationManager()
    
    @Published var registrationData: UserRegistrationModel?
    @Published var registrationError: String?
    
    public init() {
        print("🔍 DEBUG: RegistrationManager init başladı")
        
        // App başlatıldığında yerel depolamadan verileri yükle
        registrationData = DataStorageService.shared.loadRegistrationData()
        if let data = registrationData {
            print("✅ DEBUG: Mevcut kayıt verisi yüklendi: \(data.name)")
        } else {
            print("ℹ️ DEBUG: Önceki kayıt verisi bulunamadı")
        }
        
        print("✅ DEBUG: RegistrationManager init tamamlandı")
    }
    
    // Kayıt verilerini güncelleme fonksiyonları
    func updatePersonalInfo(name: String, email: String, password: String) {
        print("🔍 DEBUG: updatePersonalInfo çağrıldı")
        print("🔍 DEBUG: name: '\(name)', email: '\(email)', password: '\(password)'")
        
        // Önce hata mesajını temizle
        registrationError = nil
        print("🔍 DEBUG: registrationError temizlendi")
        
        // Boş alan kontrolü
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            print("❌ DEBUG: İsim boş!")
            registrationError = "İsim alanı boş olamaz"
            return
        }
        
        print("✅ DEBUG: İsim boş değil")
        
        // E-posta ve şifre boş bırakılabilir (başlangıç aşamasında)
        // Ancak doldurulmuşsa validasyon yapılır
        if !email.isEmpty {
            guard Validators.isValidEmail(email) else {
                print("❌ DEBUG: E-posta geçersiz!")
                registrationError = "Geçerli bir e-posta adresi girin"
                return
            }
        }
        
        if !password.isEmpty {
            guard Validators.isValidPassword(password) else {
                print("❌ DEBUG: Şifre geçersiz!")
                registrationError = "Şifre en az \(AppConstants.Validation.minPasswordLength) karakter olmalıdır"
                return
            }
        }
        
        print("✅ DEBUG: Validasyon kontrolü geçti")
        
        // Kayıt verisi yoksa yeni oluştur
        if registrationData == nil {
            print("🔍 DEBUG: Yeni registrationData oluşturuluyor...")
            
            // Güvenli bir tarih oluştur (18 yaş için)
            let calendar = Calendar.current
            let safeDate = calendar.date(byAdding: .year, value: -18, to: Date()) ?? Date()
            print("🔍 DEBUG: safeDate oluşturuldu: \(safeDate)")
            
            print("🔍 DEBUG: UserRegistrationModel oluşturuluyor...")
            
            // Guard kontrolü ile güvenli tarih oluşturma
            guard let calendar = Calendar.current.date(byAdding: .year, value: -18, to: Date()) else {
                print("❌ DEBUG: Güvenli tarih oluşturulamadı")
                registrationError = "Tarih oluşturma hatası"
                return
            }
            
            print("🔍 DEBUG: Güvenli tarih oluşturuldu: \(calendar)")
            
            let newRegistrationData = UserRegistrationModel(
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                password: password,
                gender: .male,
                birthDate: calendar,
                height: 170.0, // Varsayılan boy
                weight: 70.0,  // Varsayılan kilo
                targetWeight: 70.0, // Varsayılan hedef kilo
                goal: .maintainWeight,
                activityLevel: .sedentary
            )
            
            print("✅ DEBUG: UserRegistrationModel başarıyla oluşturuldu")
            registrationData = newRegistrationData
            print("✅ DEBUG: registrationData atandı")
            
        } else {
            print("🔍 DEBUG: Mevcut registrationData güncelleniyor...")
            
            // Mevcut veriyi güncelle
            if !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                registrationData?.name = name
                print("✅ DEBUG: İsim güncellendi: '\(name)'")
            }
            
            if !email.isEmpty {
                registrationData?.email = email
                print("✅ DEBUG: E-posta güncellendi: '\(email)'")
            }
            
            if !password.isEmpty {
                registrationData?.password = password
                print("✅ DEBUG: Şifre güncellendi")
            }
        }
        
        // Verileri yerel depolamaya kaydet
        if let data = registrationData {
            print("🔍 DEBUG: Yerel depolamaya kaydediliyor...")
            DataStorageService.shared.saveRegistrationData(data)
            print("✅ Kayıt verisi başarıyla kaydedildi: \(data.name)")
        } else {
            print("❌ Kayıt verisi nil")
            registrationError = "Kayıt verisi oluşturulamadı"
            return
        }
        
        // Hata mesajını temizle
        registrationError = nil
        print("✅ DEBUG: updatePersonalInfo başarıyla tamamlandı")
    }
    
    // Sadece email ve şifre güncellemek için ayrı bir fonksiyon
    func updateEmailAndPassword(email: String, password: String) {
        guard registrationData != nil else {
            registrationError = "Kayıt verileri bulunamadı"
            return
        }
        
        guard Validators.isValidEmail(email) else {
            registrationError = "Geçerli bir e-posta adresi girin"
            return
        }
        
        guard Validators.isValidPassword(password) else {
            registrationError = "Şifre en az \(AppConstants.Validation.minPasswordLength) karakter olmalıdır"
            return
        }
        
        // Sadece email ve şifreyi güncelle, diğer bilgileri koru
        registrationData?.email = email
        registrationData?.password = password
        
        // Verileri yerel depolamaya kaydet
        if let data = registrationData {
            DataStorageService.shared.saveRegistrationData(data)
        }
        
        // Hata mesajını temizle
        registrationError = nil
    }
    
    func updateGender(_ gender: Gender) {
        guard registrationData != nil else {
            registrationError = "Kayıt verileri bulunamadı"
            return
        }
        registrationData?.gender = gender
        
        // Verileri yerel depolamaya kaydet
        if let data = registrationData {
            DataStorageService.shared.saveRegistrationData(data)
        }
        
        registrationError = nil
    }
    
    func updateBirthDate(_ date: Date) {
        guard registrationData != nil else {
            registrationError = "Kayıt verileri bulunamadı"
            return
        }
        
        // Yaş kontrolü (18 yaşından büyük olmalı)
        guard Validators.isAdult(date) else {
            registrationError = "18 yaşından küçükler kayıt olamaz"
            return
        }
        
        registrationData?.birthDate = date
        
        // Verileri yerel depolamaya kaydet
        if let data = registrationData {
            DataStorageService.shared.saveRegistrationData(data)
        }
        
        registrationError = nil
    }
    
    func updateHeight(_ height: Double) {
        guard registrationData != nil else {
            registrationError = "Kayıt verileri bulunamadı"
            return
        }
        
        // Boy kontrolü (100-250 cm arası)
        guard Validators.isValidHeight(height) else {
            registrationError = "Geçerli bir boy değeri girin (100-250 cm)"
            return
        }
        
        registrationData?.height = height
        
        // Verileri yerel depolamaya kaydet
        if let data = registrationData {
            DataStorageService.shared.saveRegistrationData(data)
        }
        
        registrationError = nil
    }
    
    func updateWeight(_ weight: Double) {
        guard registrationData != nil else {
            registrationError = "Kayıt verileri bulunamadı"
            return
        }
        
        // Kilo kontrolü
        guard Validators.isValidWeight(weight) else {
            registrationError = "Geçerli bir kilo değeri girin (30-300 kg)"
            return
        }
        
        registrationData?.weight = weight
        
        // Verileri yerel depolamaya kaydet
        if let data = registrationData {
            DataStorageService.shared.saveRegistrationData(data)
        }
        
        registrationError = nil
    }
    
    func updateTargetWeight(_ targetWeight: Double) {
        guard registrationData != nil else {
            registrationError = "Kayıt verileri bulunamadı"
            return
        }
        
        // Hedef kilo kontrolü
        guard Validators.isValidWeight(targetWeight) else {
            registrationError = "Geçerli bir hedef kilo değeri girin (30-300 kg)"
            return
        }
        
        registrationData?.targetWeight = targetWeight
        
        // Verileri yerel depolamaya kaydet
        if let data = registrationData {
            DataStorageService.shared.saveRegistrationData(data)
        }
        
        registrationError = nil
    }
    
    func updateGoal(_ goal: FitnessGoal) {
        guard registrationData != nil else {
            registrationError = "Kayıt verileri bulunamadı"
            return
        }
        registrationData?.goal = goal
        
        // Verileri yerel depolamaya kaydet
        if let data = registrationData {
            DataStorageService.shared.saveRegistrationData(data)
        }
        
        registrationError = nil
    }
    
    func updateActivityLevel(_ activityLevel: ActivityLevel) {
        guard registrationData != nil else {
            registrationError = "Kayıt verileri bulunamadı"
            return
        }
        registrationData?.activityLevel = activityLevel
        
        // Verileri yerel depolamaya kaydet
        if let data = registrationData {
            DataStorageService.shared.saveRegistrationData(data)
        }
        
        registrationError = nil
    }
    
    // RegisterFinalView uyumluluğu için wrapper
    func updateRegistrationData(email: String, password: String) {
        updateEmailAndPassword(email: email, password: password)
    }
    
    // Kayıt verilerini döndür
    func getRegistrationData() -> UserRegistrationModel? {
        return registrationData
    }
    
    // Kayıt verilerini veritabanına gönderme
    func submitRegistration(completion: @escaping (Bool, String?) -> Void) {
        guard let data = registrationData else {
            completion(false, "Kayıt verileri eksik")
            return
        }
        
        // Tüm alanların dolu olduğunu kontrol et
        guard data.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false,
              data.email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false,
              data.password.isEmpty == false,
              data.height > 0,
              data.weight > 0,
              data.targetWeight > 0 else {
            completion(false, "Tüm alanları doldurun")
            return
        }
        
        // Firebase Authentication ile kayıt
        AuthenticationManager.shared.signUp(email: data.email, password: data.password, userData: data) { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    // Başarılı kayıt
                    completion(true, nil)
                    
                    // İşlem tamamlandıktan sonra verileri temizle
                    self?.clearRegistrationData()
                } else {
                    // Hata durumu
                    completion(false, error ?? "Kayıt işlemi başarısız")
                }
            }
        }
    }
    
    // Kayıt verilerini sıfırlama
    func clearRegistrationData() {
        registrationData = nil
        registrationError = nil
        
        // Yerel depolamadaki verileri de temizle
        DataStorageService.shared.clearRegistrationData()
    }
}
