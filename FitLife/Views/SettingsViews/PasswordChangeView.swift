import SwiftUI

struct PasswordChangeView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    
    private let dataStorage = DataStorageService.shared
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.backgroundDarkBlue.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        passwordSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Şifre Değiştir")
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
                        changePassword()
                    }
                    .foregroundColor(.buttonlightGreen)
                    .disabled(isLoading)
                }
            }
            .alert("Bilgi", isPresented: $showAlert) {
                Button("Tamam", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private var passwordSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Şifre Bilgileri")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                CustomTextField(
                    title: "Mevcut Şifre",
                    text: $currentPassword,
                    placeholder: "Mevcut şifrenizi girin",
                    isSecure: true
                )
                
                CustomTextField(
                    title: "Yeni Şifre",
                    text: $newPassword,
                    placeholder: "Yeni şifrenizi girin",
                    isSecure: true
                )
                
                CustomTextField(
                    title: "Yeni Şifre Tekrar",
                    text: $confirmPassword,
                    placeholder: "Yeni şifrenizi tekrar girin",
                    isSecure: true
                )
            }
            
            Text("• Şifre en az 6 karakter olmalıdır")
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.top, 8)
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func changePassword() {
        // Validasyon
        guard !currentPassword.isEmpty else {
            alertMessage = "Mevcut şifrenizi girin"
            showAlert = true
            return
        }
        
        guard newPassword.count >= 6 else {
            alertMessage = "Yeni şifre en az 6 karakter olmalıdır"
            showAlert = true
            return
        }
        
        guard newPassword == confirmPassword else {
            alertMessage = "Yeni şifre ve onayı eşleşmiyor"
            showAlert = true
            return
        }
        
        guard newPassword != currentPassword else {
            alertMessage = "Yeni şifre mevcut şifreden farklı olmalıdır"
            showAlert = true
            return
        }
        
        isLoading = true
        
        // Şifre değiştirme işlemi
        if var userData = dataStorage.loadRegistrationData() {
            // Mevcut şifre kontrolü
            guard userData.password == currentPassword else {
                isLoading = false
                alertMessage = "Mevcut şifre yanlış"
                showAlert = true
                return
            }
            
            // Yeni şifreyi kaydet
            userData.password = newPassword
            dataStorage.saveRegistrationData(userData)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isLoading = false
                alertMessage = "Şifreniz başarıyla değiştirildi"
                showAlert = true
                
                // Alanları temizle
                currentPassword = ""
                newPassword = ""
                confirmPassword = ""
                
                // 1 saniye sonra sayfayı kapat
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    dismiss()
                }
            }
        } else {
            isLoading = false
            alertMessage = "Kullanıcı verileri yüklenirken hata oluştu"
            showAlert = true
        }
    }
}

#Preview {
    PasswordChangeView()
} 