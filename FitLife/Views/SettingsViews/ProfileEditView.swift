import SwiftUI

struct ProfileEditView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var height = ""
    @State private var weight = ""
    @State private var targetWeight = ""
    @State private var selectedGoal: FitnessGoal = .maintainWeight
    @State private var selectedActivityLevel: ActivityLevel = .moderatelyActive
    
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    @State private var isLoadingData = true
    @State private var dailyCalorieNeeds = 0
    
    private let dataStorage = DataStorageService.shared
    private let firebaseService = FirebaseService.shared
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.backgroundDarkBlue.ignoresSafeArea()
                
                if isLoadingData {
                    // Veri yüklenirken loading göster
                    VStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .buttonlightGreen))
                            .scaleEffect(1.5)
                        
                        Text("Profil bilgileri yükleniyor...")
                            .foregroundColor(.white)
                            .font(.body)
                            .padding(.top, 20)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            personalInfoSection
                            physicalInfoSection
                            fitnessGoalSection
                            calorieInfoSection
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Profil Düzenle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kaydet") {
                        saveProfile()
                    }
                    .foregroundColor(.buttonlightGreen)
                    .disabled(isLoading || isLoadingData)
                }
            }
            .alert("Bilgi", isPresented: $showAlert) {
                Button("Tamam", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
            .onAppear {
                loadUserData()
            }
        }
    }
    
    private var personalInfoSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Kişisel Bilgiler")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                CustomTextField(
                    title: "İsim",
                    text: $name,
                    placeholder: "Adınızı girin"
                )
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var physicalInfoSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Fiziksel Bilgiler")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                CustomTextField(
                    title: "Boy (cm)",
                    text: $height,
                    placeholder: "Boyunuzu girin",
                    keyboardType: .numberPad
                )
                
                CustomTextField(
                    title: "Kilo (kg)",
                    text: $weight,
                    placeholder: "Kilonuzu girin",
                    keyboardType: .decimalPad
                )
                
                                    if selectedGoal != .maintainWeight {
                        CustomTextField(
                            title: "Hedef Kilo (kg)",
                            text: $targetWeight,
                            placeholder: "Hedef kilonuzu girin",
                            keyboardType: .decimalPad
                        )
                    }
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var fitnessGoalSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Fitness Hedefi")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            VStack(spacing: 10) {
                ForEach(FitnessGoal.allCases, id: \.self) { goal in
                    goalButton(for: goal)
                }
            }
            
            Text("Aktivite Seviyesi")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.top, 10)
            
            VStack(spacing: 8) {
                ForEach(ActivityLevel.allCases, id: \.self) { level in
                    activityButton(for: level)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func goalButton(for goal: FitnessGoal) -> some View {
        Button(action: {
            selectedGoal = goal
        }) {
            HStack {
                Text(goal.displayName)
                    .foregroundColor(.white)
                    .font(.body)
                
                Spacer()
                
                if selectedGoal == goal {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.buttonlightGreen)
                }
            }
            .padding()
            .background(
                selectedGoal == goal ? 
                Color.buttonlightGreen.opacity(0.2) : 
                Color.white.opacity(0.05)
            )
            .cornerRadius(8)
        }
    }
    
    private func activityButton(for level: ActivityLevel) -> some View {
        Button(action: {
            selectedActivityLevel = level
        }) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(level.rawValue)
                        .foregroundColor(.white)
                        .font(.body)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    if selectedActivityLevel == level {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.buttonlightGreen)
                    }
                }
                
                Text(level.description)
                    .foregroundColor(.gray)
                    .font(.caption)
                    .multilineTextAlignment(.leading)
            }
            .padding()
            .background(
                selectedActivityLevel == level ? 
                Color.buttonlightGreen.opacity(0.2) : 
                Color.white.opacity(0.05)
            )
            .cornerRadius(8)
        }
    }
    
    private func loadUserData() {
        print("🔄 Kullanıcı verileri yükleniyor...")
        isLoadingData = true
        
        // Sadece UserDefaults'tan yükle (giriş sırasında zaten Firebase'den cache'lenmiş)
        if let userData = dataStorage.loadRegistrationData() {
            print("✅ UserDefaults'tan veri yüklendi")
            populateFields(with: userData)
            isLoadingData = false
        } else {
            print("❌ UserDefaults'ta kullanıcı verisi bulunamadı")
            // Giriş sırasında veriler cache'lenmemiş olabilir, Firebase'den çekmeyi dene
            print("🔄 Firebase'den veri çekiliyor...")
            
            FirebaseService.shared.getCurrentUserData { userData, error in
                DispatchQueue.main.async {
                    if let userData = userData {
                        print("✅ Firebase'den veri yüklendi ve cache'lendi")
                        
                        // Cache'le
                        self.dataStorage.saveRegistrationData(userData)
                        
                        // Formu doldur
                        self.populateFields(with: userData)
                        self.isLoadingData = false
                    } else {
                        print("❌ Firebase'den de veri yüklenemedi: \(error ?? "Bilinmeyen hata")")
                        self.alertMessage = "Profil verileri bulunamadı. Lütfen uygulamaya yeniden giriş yapın."
                        self.showAlert = true
                        self.isLoadingData = false
                    }
                }
            }
        }
    }
    
    private func populateFields(with userData: UserRegistrationModel) {
        name = userData.name
        height = String(Int(userData.height))
        weight = String(format: "%.1f", userData.weight)
        targetWeight = String(format: "%.1f", userData.targetWeight)
        selectedGoal = userData.goal
        selectedActivityLevel = userData.activityLevel
        dailyCalorieNeeds = userData.dailyCalorieNeeds
        print("📝 Form alanları dolduruldu: \(userData.name)")
    }
    
    // Kalori bilgi section'ı
    private var calorieInfoSection: some View {
        calorieCard
            .onChange(of: height) { _, _ in updateCalorieNeeds() }
            .onChange(of: weight) { _, _ in updateCalorieNeeds() }
            .onChange(of: selectedGoal) { _, _ in updateCalorieNeeds() }
            .onChange(of: selectedActivityLevel) { _, _ in updateCalorieNeeds() }
    }
    
    private var calorieCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Günlük Kalori İhtiyacı")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            calorieContent
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var calorieContent: some View {
        HStack {
            Image(systemName: "flame.fill")
                .foregroundColor(.orange)
                .font(.title2)
            
            calorieTextContent
            
            Spacer()
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(10)
    }
    
    private var calorieTextContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(dailyCalorieNeeds) kcal")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(getMacroText())
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
    
    // Kalori ihtiyacını güncelle
    private func updateCalorieNeeds() {
        // Geçerli değerler var mı kontrol et
        guard let heightValue = Double(height), heightValue > 0,
              let weightValue = Double(weight), weightValue > 0,
              let userData = dataStorage.loadRegistrationData() else {
            return
        }
        
        // Güncellenmiş verilerle geçici model oluştur
        var tempUserData = userData
        tempUserData.height = heightValue
        tempUserData.weight = weightValue
        tempUserData.goal = selectedGoal
        tempUserData.activityLevel = selectedActivityLevel
        
        // Kalori ihtiyacını hesapla
        dailyCalorieNeeds = tempUserData.dailyCalorieNeeds
        print("🔥 Kalori ihtiyacı güncellendi: \(dailyCalorieNeeds) kcal")
    }
    
    // Makro text'ini hesapla
    private func getMacroText() -> String {
        let calories = Double(dailyCalorieNeeds)
        let carbs = Int((calories * 0.50) / 4)
        let protein = Int((calories * 0.20) / 4)
        let fat = Int((calories * 0.30) / 9)
        
        return "Makro dağılımı: Karb. \(carbs)g • Protein \(protein)g • Yağ \(fat)g"
    }
    
    private func saveProfile() {
        // Validasyon
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            alertMessage = "İsim alanı boş olamaz"
            showAlert = true
            return
        }
        
        guard let heightValue = Double(height), heightValue >= 100, heightValue <= 250 else {
            alertMessage = "Geçerli bir boy değeri girin (100-250 cm)"
            showAlert = true
            return
        }
        
        guard let weightValue = Double(weight), weightValue >= 30, weightValue <= 200 else {
            alertMessage = "Geçerli bir kilo değeri girin (30-200 kg)"
            showAlert = true
            return
        }
        
        // Hedef kilo validasyonu - sadece kilo korumak seçili değilse
        var targetWeightValue = weightValue // Varsayılan olarak mevcut kilo
        if selectedGoal != .maintainWeight {
            guard let target = Double(targetWeight), target >= 30, target <= 200 else {
                alertMessage = "Geçerli bir hedef kilo değeri girin (30-200 kg)"
                showAlert = true
                return
            }
            targetWeightValue = target
        }
        
        isLoading = true
        print("🔄 Profil güncelleme başlatılıyor...")
        
        // Kullanıcı verilerini güncelle
        if var userData = dataStorage.loadRegistrationData() {
            print("✅ Mevcut kullanıcı verileri yüklendi")
            
            userData.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
            userData.height = heightValue
            userData.weight = weightValue
            userData.targetWeight = targetWeightValue
            userData.goal = selectedGoal
            userData.activityLevel = selectedActivityLevel
            
            print("📝 Güncellenecek veriler:")
            print("  - İsim: \(userData.name)")
            print("  - Boy: \(userData.height) cm")
            print("  - Kilo: \(userData.weight) kg")
            print("  - Hedef Kilo: \(userData.targetWeight) kg")
            print("  - Hedef: \(userData.goal.displayName)")
            print("  - Aktivite: \(userData.activityLevel.rawValue)")
            
            // Önce yerel olarak kaydet
            dataStorage.saveRegistrationData(userData)
            print("✅ Veriler yerel olarak kaydedildi")
            
            // Kalori ihtiyacını hesapla ve göster
            let dailyCalories = userData.dailyCalorieNeeds
            print("📊 Güncellenmiş günlük kalori ihtiyacı: \(dailyCalories) kcal")
            
            // Firebase'e kaydet (arka planda)
            FirebaseService.shared.updateUserProfile(userData: userData) { success, error in
                print(success ? "✅ Firebase'e kaydedildi" : "⚠️ Firebase kaydetme hatası: \(error ?? "")")
            }
            
            // Başarılı mesajı göster (Firebase sonucunu beklemeden)
            DispatchQueue.main.async {
                self.isLoading = false
                print("✅ Profil başarıyla güncellendi")
                self.alertMessage = "Profil bilgileriniz başarıyla güncellendi\n\n📊 Günlük kalori ihtiyacınız: \(dailyCalories) kcal"
                self.showAlert = true
                
                // Profil güncellendiğini bildirme notification'ı gönder
                NotificationCenter.default.post(name: Notification.Name("ProfileUpdated"), object: nil)
                
                // 2 saniye sonra sayfayı kapat
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.dismiss()
                }
            }
        } else {
            print("❌ Kullanıcı verileri yüklenemedi - Firebase'den deneniyor...")
            
            // Fallback: Firebase'den veri çekip güncelle
            FirebaseService.shared.getCurrentUserData { userData, error in
                DispatchQueue.main.async {
                    if var userData = userData {
                        print("✅ Firebase'den veri yüklendi, güncelleme yapılıyor")
                        
                        // Verileri güncelle
                        userData.name = self.name.trimmingCharacters(in: .whitespacesAndNewlines)
                        userData.height = heightValue
                        userData.weight = weightValue
                        userData.targetWeight = targetWeightValue
                        userData.goal = self.selectedGoal
                        userData.activityLevel = self.selectedActivityLevel
                        
                        // Cache'le
                        self.dataStorage.saveRegistrationData(userData)
                        
                        // Kalori ihtiyacını hesapla
                        let dailyCalories = userData.dailyCalorieNeeds
                        print("📊 Güncellenmiş günlük kalori ihtiyacı (fallback): \(dailyCalories) kcal")
                        
                        // Firebase'e kaydet (arka planda)
                        FirebaseService.shared.updateUserProfile(userData: userData) { success, error in
                            print(success ? "✅ Firebase'e kaydedildi (fallback)" : "⚠️ Firebase kaydetme hatası (fallback): \(error ?? "")")
                        }
                        
                        // Başarılı mesajı göster
                        DispatchQueue.main.async {
                            self.isLoading = false
                            print("✅ Profil başarıyla güncellendi (fallback)")
                            self.alertMessage = "Profil bilgileriniz başarıyla güncellendi\n\n📊 Günlük kalori ihtiyacınız: \(dailyCalories) kcal"
                            self.showAlert = true
                            
                            // Profil güncellendiğini bildirme notification'ı gönder
                            NotificationCenter.default.post(name: Notification.Name("ProfileUpdated"), object: nil)
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                self.dismiss()
                            }
                        }
                    } else {
                        self.isLoading = false
                        print("❌ Firebase'den de veri yüklenemedi")
                        self.alertMessage = "Profil verileri bulunamadı. Lütfen uygulamaya yeniden giriş yapın."
                        self.showAlert = true
                    }
                }
            }
        }
    }
}

#Preview {
    ProfileEditView()
} 