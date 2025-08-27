import SwiftUI
import Combine

class KeyboardResponder: ObservableObject {
    @Published var isKeyboardVisible: Bool = false
    private var cancellableSet: Set<AnyCancellable> = []

    init() {
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .sink { _ in self.isKeyboardVisible = true }
            .store(in: &cancellableSet)

        NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .sink { _ in self.isKeyboardVisible = false }
            .store(in: &cancellableSet)
    }
}

struct RegisterFinalView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var registrationManager: RegistrationManager
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showPassword: Bool = false
    @State private var showingAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var isRegistering: Bool = false
    @State private var showCompletionSheet: Bool = false
    @State private var showLoginView: Bool = false
    @StateObject private var keyboard = KeyboardResponder()
    
    var body: some View {
        ZStack {
            Color.backgroundDarkBlue.ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Üst kısım - Geri butonu
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                            .font(.title2)
                    }
                    
                    Spacer()
                }
                .padding(.leading, 20)
                .padding(.trailing, 20)
                .padding(.top, 20)
                
                // Başlık kısmı
                VStack(spacing: 12) {
                    Text("Kayıt İşlemini Tamamla")
                        .font(.system(size: 38, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.top, 10)
                        .padding(.leading, 20)
                        .padding(.trailing, 20)
                    
                    Text("Hesabınızı oluşturmak için e-posta ve parola girin")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.leading, 20)
                        .padding(.trailing, 20)
                        .padding(.bottom, 30)
                }
                
                // Form alanları
                VStack(spacing: 20) {
                    // E-posta
                    TextField("E-posta", text: $email)
                        .font(.title3)
                        .foregroundColor(.white)
                        .textFieldStyle(CustomTextFieldStyle())
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .padding(.bottom, 5)
                        .frame(height: 50)
                        .background(
                            ZStack {
                                // Gölge
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.black.opacity(0.2))
                                    .offset(y: 2)
                                
                                // Arkaplan
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.white.opacity(0.15))
                            }
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                        .padding(.leading, 20)
                        .padding(.trailing, 20)
                    
                    // Parola
                    ZStack(alignment: .trailing) {
                        if showPassword {
                            TextField("Parola", text: $password)
                                .font(.title3)
                                .foregroundColor(.white)
                        .textFieldStyle(CustomTextFieldStyle())
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .padding(.bottom, 5)
                        .frame(height: 50)
                        .background(
                            ZStack {
                                        // Gölge
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color.black.opacity(0.2))
                                            .offset(y: 2)
                                        
                                        // Arkaplan
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color.white.opacity(0.15))
                                    }
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                                .padding(.leading, 20)
                                .padding(.trailing, 20)
                        } else {
                            SecureField("Parola", text: $password)
                                .font(.title3)
                                .foregroundColor(.white)
                                .textFieldStyle(CustomTextFieldStyle())
                                .padding(.bottom, 5)
                                .frame(height: 50)
                                .background(
                                    ZStack {
                                        // Gölge
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.black.opacity(0.2))
                                    .offset(y: 2)
                                
                                        // Arkaplan
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.white.opacity(0.15))
                            }
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                                .padding(.leading, 20)
                                .padding(.trailing, 20)
                        }
                        
                        Button(action: {
                            showPassword.toggle()
                        }) {
                            Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .padding(.trailing, 30)
                    }
                        }
                    
                // Şifre gücü göstergesi
                VStack(alignment: .leading, spacing: 8) {
                        Text("Parola Gücü")
                            .foregroundColor(.white)
                        .font(.headline)
                        .padding(.leading, 20)
                        
                    HStack(spacing: 2) {
                        Rectangle()
                            .fill(passwordStrength == .weak ? Color.red : Color.red.opacity(0.3))
                            .frame(height: 6)
                        
                                Rectangle()
                            .fill(passwordStrength == .medium || passwordStrength == .strong ? Color.yellow : Color.gray.opacity(0.3))
                            .frame(height: 6)
                        
                        Rectangle()
                            .fill(passwordStrength == .strong ? Color.green : Color.gray.opacity(0.3))
                            .frame(height: 6)
                    }
                    .padding(.leading, 20)
                    .padding(.trailing, 20)
                    .padding(.top, 5)
                    
                    Text(passwordStrengthText)
                        .foregroundColor(passwordStrength == .weak ? .red : .gray)
                        .font(.subheadline)
                        .padding(.leading, 20)
                }
                
                Spacer()
                
                // Zaten hesabın var mı?
                if !keyboard.isKeyboardVisible {
                    HStack {
                        Text("Zaten bir hesabın var mı?")
                            .foregroundColor(.white)
                        
                        Button("Giriş Yap") {
                            showLoginView = true
                        }
                                .foregroundColor(Color.buttonlightGreen)
                    }
                    .padding(.bottom, 20)
                    .fullScreenCover(isPresented: $showLoginView, content: {
                        LoginView()
                    })
                }
                // Kayıt ol butonu
                Button(action: {
                    registerUser()
                    hideKeyboard()
                }) {
                    ZStack {
                        Circle()
                            .fill(isFormValid ? Color.buttonlightGreen : Color.gray.opacity(0.3))
                            .frame(width: 70, height: 70)
                        
                        if isRegistering {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                .scaleEffect(1.5)
                        } else {
                        Image(systemName: "checkmark")
                                .font(.system(size: 30, weight: .bold))
                                .foregroundColor(Color.backgroundDarkBlue)
                        }
                    }
                }
                .disabled(!isFormValid || isRegistering)
                .padding(.bottom, 80)
            }
        }
        .dismissKeyboard()
        .alert(alertMessage, isPresented: $showingAlert) {
            Button("Tamam", role: .cancel) {}
        }
        .sheet(isPresented: $showCompletionSheet) {
            FinalCompletionSheetView(newUserMail: email, newUserPassword: password)
                .presentationDetents([.fraction(0.5)])
        }
       /* .fullScreenCover(isPresented: $showLoginView) {
            // Burada LoginView() olarak güncellenecek
            LoginView()
        }*/
    }
    
    private var passwordStrength: PasswordStrength {
        if password.isEmpty {
            return .weak
        }
        
        let hasUppercase = password.rangeOfCharacter(from: .uppercaseLetters) != nil
        let hasLowercase = password.rangeOfCharacter(from: .lowercaseLetters) != nil
        let hasDigit = password.rangeOfCharacter(from: .decimalDigits) != nil
        let hasSpecialChar = password.rangeOfCharacter(from: .punctuationCharacters) != nil
        let length = password.count
        
        if length >= 8 && hasUppercase && hasLowercase && hasDigit && hasSpecialChar {
            return .strong
        } else if length >= 6 && (hasUppercase || hasLowercase) && (hasDigit || hasSpecialChar) {
            return .medium
        } else {
            return .weak
        }
    }
    
    private var passwordStrengthText: String {
        switch passwordStrength {
        case .weak:
            return "Zayıf"
        case .medium:
            return "Orta"
        case .strong:
            return "Güçlü"
        }
    }
    
    private var passwordStrengthColor: Color {
        switch passwordStrength {
        case .weak:
            return .red
        case .medium:
            return .yellow
        case .strong:
            return .green
        }
    }
    
    private var isFormValid: Bool {
        !email.isEmpty && 
        !password.isEmpty && 
        password.count >= 6 &&
        email.contains("@") && email.contains(".")
    }
    
    private func registerUser() {
        if !isFormValid {
            alertMessage = "Lütfen tüm alanları doğru şekilde doldurun."
            showingAlert = true
            return
        }
        
        isRegistering = true
        
        // E-posta ve şifre ile kayıt verilerini günceller
        registrationManager.updateRegistrationData(email: email, password: password)
        
        // Firebase ile kullanıcı kaydını oluştur
        guard let userData = registrationManager.registrationData else {
            alertMessage = "Kayıt verileri eksik. Lütfen kayıt işlemini tekrar başlatın."
            showingAlert = true
            isRegistering = false
            return
        }
        
        AuthenticationManager.shared.signUp(email: email, password: password, userData: userData) { success, error in
            DispatchQueue.main.async {
                self.isRegistering = false
                
                if success {
                    self.showCompletionSheet = true
                } else {
                    self.alertMessage = error ?? "Kayıt işlemi sırasında bir hata oluştu"
                    self.showingAlert = true
                }
            }
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct FinalCompletionSheetView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var authManager = AuthenticationManager.shared
    let newUserMail: String
    let newUserPassword: String
    
    var body: some View {

        VStack(spacing: 20) {
            
            Image(systemName: "checkmark")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .padding(.top, 50)
            
            Text("Kayıt Tamamlandı!")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Hesabınız başarıyla oluşturuldu.")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
            
            Spacer()
            
            VStack(spacing: 15) {
                Button(action: {
                    // Firebase ile kayıt işlemi zaten tamamlandı
                    // FitLifeApp.swift AuthenticationManager listener'ı otomatik olarak MainTabView'a yönlendirecek
                    dismiss()
                }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.buttonlightGreen)
                            .frame(height: 50)
                            .padding(.horizontal,50)
                        
                        Text("Hadi Başlayalım!")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                }
                
            }
        }
    }
}

#Preview {
    RegisterFinalView(registrationManager: RegistrationManager())
} 
