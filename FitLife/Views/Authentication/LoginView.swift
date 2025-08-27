import SwiftUI

struct LoginView: View {
    @ObservedObject private var authManager = AuthenticationManager.shared
    @State private var email = ""
    @State private var password = ""
    @State private var showRegisterView = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var showForgotPassword = false
    
    var body: some View {
        
            ZStack {
                Color.backgroundDarkBlue.ignoresSafeArea()
                
    
                VStack(spacing: 25) {
                    Image("ScreenLogo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width:200, height: 200)
                            .foregroundColor(.blue)
                    
                    Text("FitLife")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        
                    
                    VStack(spacing: 15) {
                        TextField("E-posta", text: $email)
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
                        
                        SecureField("Şifre", text: $password)
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
                    }
                    .padding(.horizontal, 20)
                    
                    Button(action: {
                        login()
                    }) {
                        ZStack {
                        Text("Giriş Yap")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                                .background(isFormValid ? Color.buttonGreen : Color.gray.opacity(0.5))
                            .cornerRadius(10)
                            
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                        }
                    }
                    .disabled(!isFormValid || isLoading)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    VStack(spacing: 10) {
                        Button(action: {
                            showForgotPassword = true
                        }) {
                            Text("Şifremi Unuttum")
                                .foregroundColor(.buttonlightGreen)
                                .font(.subheadline)
                        }
                    
                    Button(action: {
                        showRegisterView = true
                    }) {
                        Text("Hesabın yok mu? Kayıt ol")
                            .foregroundColor(.buttonlightGreen)
                        }
                    }
                    .padding(.top, 10)
                }
                .padding()
            }
            .dismissKeyboard()
            .fullScreenCover(isPresented: $showRegisterView) {
                RegisterNameView()
            }
            .alert("Hata", isPresented: $showError) {
                Button("Tamam", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .alert("Şifre Sıfırlama", isPresented: $showForgotPassword) {
                TextField("E-posta", text: $email)
                Button("Gönder") {
                    resetPassword()
                }
                Button("İptal", role: .cancel) {}
            } message: {
                Text("Şifre sıfırlama bağlantısı e-posta adresinize gönderilecek.")
            }

        
    }
    
    private var isFormValid: Bool {
        return !email.isEmpty && !password.isEmpty && Validators.isValidEmail(email)
    }
    
    private func login() {
        // E-posta ve şifre kontrolü
        guard !email.isEmpty else {
            errorMessage = "Lütfen e-posta adresinizi girin"
            showError = true
            return
        }
        
        guard !password.isEmpty else {
            errorMessage = "Lütfen şifrenizi girin"
            showError = true
            return
        }
        
        // Validasyon kullanarak kontroller yapalım
        guard Validators.isValidEmail(email) else {
            errorMessage = "Geçerli bir e-posta adresi girin"
            showError = true
            return
        }
        
        guard Validators.isValidPassword(password) else {
            errorMessage = "Şifre en az \(AppConstants.Validation.minPasswordLength) karakter olmalıdır"
            showError = true
            return
        }
        
        isLoading = true
        
        // AuthenticationManager ile giriş
        authManager.login(email: email, password: password) { [self] success, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if success {
                    print("Giriş başarılı")
                    // FitLifeApp.swift AuthenticationManager listener'ı otomatik olarak MainTabView'a yönlendirecek
                } else {
                    errorMessage = "E-posta ile şifreniz eşleşmiyor."
                    showError = true
                }
            }
        }
    }
    
    private func resetPassword() {
        guard !email.isEmpty else {
            errorMessage = "Lütfen e-posta adresinizi girin"
            showError = true
            return
        }
        
        guard Validators.isValidEmail(email) else {
            errorMessage = "Geçerli bir e-posta adresi girin"
            showError = true
            return
        }
        
        authManager.resetPassword(email: email) { success, message in
            if success {
                // Başarı mesajı göster
                print("Şifre sıfırlama e-postası gönderildi")
            } else {
                // Hata mesajı göster
                print("Hata: \(message ?? "Bilinmeyen hata")")
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            if let error = authManager.authenticationError {
                errorMessage = error
            } else {
                errorMessage = "Şifre sıfırlama bağlantısı e-posta adresinize gönderildi"
            }
            showError = true
        }
    }
}

#Preview {
    LoginView()
} 
