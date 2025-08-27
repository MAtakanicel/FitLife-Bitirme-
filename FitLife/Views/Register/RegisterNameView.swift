import SwiftUI

struct RegisterNameView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var registrationManager = RegistrationManager.shared
    @State private var name = ""
    @State private var showRegisterInfoView = false
    @State private var currentStep = 1
    @State private var showAlert = false
    @State private var alertMessage = ""
    @FocusState private var isNameFieldFocused: Bool
    @State private var showWelcomeView : Bool = false
    
    var body: some View {
        ZStack {
            Color.backgroundDarkBlue.ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Üst kısım - Geri butonu ve adım göstergesi
                HStack {
                    Button(action: {
                        showWelcomeView.toggle()
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                    }
                    .fullScreenCover(isPresented: $showWelcomeView, content: {
                        WelcomeView()
                    })
                    
                    Spacer()
                    
                    // Adım göstergesi
                    StepIndicator(currentStep: currentStep)
                    
                    Spacer()
                    
                    // Sağ tarafta boşluk bırakıyoruz (simetri için)
                    Image(systemName: "chevron.left")
                        .foregroundColor(.clear)
                }
                .padding(.horizontal)
                .padding(.top, 30)
                
                // İçerik
                VStack(alignment: .center, spacing: 15) {
                    Text("İsim")
                        .font(.system(size: 35, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Merhaba, deneyiminizi size özel hale getirmek için isminizi istiyoruz")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.75))
                        .padding(.bottom, 10)
                    
                    // İsim girişi
                    TextField("İsminizi girin", text: $name)
                        .fitLifeStyle()
                        .focused($isNameFieldFocused)
                        .keyboardType(.default)
                        .textContentType(.name)
                        .autocapitalization(.words)
                        .disableAutocorrection(true)
                        .onChange(of: name) { oldValue, newValue in
                            // Maksimum karakter sınırı (50 karakter)
                            if newValue.count > 50 {
                                name = String(newValue.prefix(50))
                            }
                        }
                        .padding(.horizontal)
                    
                    // Gizlilik bilgileri
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Gizlilik")
                            .font(.system(size: 15,weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("İsminiz ve kişisel bilgileriniz kimseyle paylaşılmaz")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.75))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 10)
                }
                .padding(.top,20)
                .padding(.horizontal, 20)
                
                Spacer()
            }
            
            // Devam butonu
            VStack {
                Spacer()
                
                Button(action: {
                    handleContinueAction()
                }) {
                    ZStack {
                        Circle()
                            .fill(!name.isEmpty ? Color.buttonlightGreen : Color.gray.opacity(0.5))
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: "arrow.right")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .disabled(name.isEmpty)
                .padding(.bottom, isNameFieldFocused ? 20 : 30)
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .dismissKeyboard()
        .onAppear {
            // Ekran açıldığında TextField'a otomatik focus
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isNameFieldFocused = true
            }
        }
        .fullScreenCover(isPresented: $showRegisterInfoView) {
            RegisterInfoView()
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Hata"),
                message: Text(alertMessage),
                dismissButton: .default(Text("Tamam"))
            )
        }
    }
    
    // MARK: - Helper Functions
    
    private func handleContinueAction() {
        print("🔍 DEBUG: İleri butonuna basıldı")
        print("🔍 DEBUG: Girilen isim: '\(name)'")
        
        // İsim validasyonu
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        print("🔍 DEBUG: Temizlenmiş isim: '\(trimmedName)'")
        print("🔍 DEBUG: İsim uzunluğu: \(trimmedName.count)")
        
        guard Validators.isValidName(trimmedName) else {
            print("❌ DEBUG: İsim validasyonu başarısız")
            alertMessage = "Lütfen geçerli bir isim girin (en az 2 karakter)"
            showAlert = true
            return
        }
        
        print("✅ DEBUG: İsim validasyonu başarılı")
        
        // Sonraki adıma geçiş
        guard currentStep < AppConstants.totalRegistrationSteps else {
            print("❌ DEBUG: Maksimum adım sayısına ulaşıldı")
            return
        }
        
        print("🔍 DEBUG: Mevcut adım: \(currentStep), Toplam adım: \(AppConstants.totalRegistrationSteps)")
        currentStep += 1
        print("🔍 DEBUG: Yeni adım: \(currentStep)")
        
        // İsim bilgisini güncelle
        print("🔍 DEBUG: RegistrationManager'a isim gönderiliyor...")
        registrationManager.updatePersonalInfo(
            name: trimmedName,
            email: "",
            password: ""
        )
        
        print("🔍 DEBUG: RegistrationManager güncellemesi tamamlandı")
        
        // Hata kontrolü
        if let error = registrationManager.registrationError {
            print("❌ DEBUG: RegistrationManager hatası: \(error)")
            alertMessage = error
            showAlert = true
            currentStep -= 1 // Adımı geri al
            print("🔍 DEBUG: Adım geri alındı: \(currentStep)")
            return
        }
        
        print("✅ DEBUG: RegistrationManager hatası yok")
        
        // Kayıt verilerini yerel olarak sakla
        guard let registrationData = registrationManager.registrationData else {
            print("❌ DEBUG: Kayıt verileri nil!")
            alertMessage = "Kayıt verileri oluşturulamadı"
            showAlert = true
            currentStep -= 1
            return
        }
        
        print("🔍 DEBUG: Kayıt verileri bulundu, kaydediliyor...")
        print("🔍 DEBUG: Kayıt verisi ismi: \(registrationData.name)")
        DataStorageService.shared.saveRegistrationData(registrationData)
        print("✅ DEBUG: Kayıt verileri başarıyla kaydedildi")
        
        print("🔍 DEBUG: RegisterInfoView açılıyor...")
        showRegisterInfoView = true
        print("✅ DEBUG: RegisterInfoView flag set edildi")
    }
}

#Preview {
    RegisterNameView()
} 
