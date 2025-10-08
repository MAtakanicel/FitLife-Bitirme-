import SwiftUI

struct RegisterGenderView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var registrationManager = RegistrationManager.shared
    @State private var currentStep = 3
    @State private var selectedGender: Gender? = nil
    @State private var showBirthdayView = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        ZStack {
            Color.backgroundDarkBlue.ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Üst kısım - Geri butonu ve adım göstergesi
                HStack {
                    Button(action: {
                        currentStep -= 1
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                    }
                    
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
                
                // Başlık
                Text("Cinsiyetini belirt")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.top, 20)
                
                Text("Erkek metabolizması, kadın metabolizmasına göre daha hızlıdır.")
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.horizontal, 15)
                
                Spacer()
                
                // Cinsiyet seçim butonları
                HStack(spacing: 30) {
                    // Erkek seçeneği
                    Button(action: {
                        selectedGender = .male
                    }) {
                        VStack {
                            Text("♂")
                                .font(.system(size: 50))
                                .foregroundColor(selectedGender == .male ? .buttonlightGreen : .white.opacity(0.5))
                            Text("Erkek")
                                .foregroundColor(selectedGender == .male ? .buttonlightGreen : .white.opacity(0.5))
                        }
                        .frame(width: 120, height: 120)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(selectedGender == .male ? Color.buttonlightGreen : Color.white.opacity(0.5), lineWidth: 2)
                        )
                    }
                    
                    // Kadın seçeneği
                    Button(action: {
                        selectedGender = .female
                    }) {
                        VStack {
                            Text("♀")
                                .font(.system(size: 50))
                                .foregroundColor(selectedGender == .female ? .buttonlightGreen : .white.opacity(0.5))
                            Text("Kadın")
                                .foregroundColor(selectedGender == .female ? .buttonlightGreen : .white.opacity(0.5))
                        }
                        .frame(width: 120, height: 120)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(selectedGender == .female ? Color.buttonlightGreen : Color.white.opacity(0.5), lineWidth: 2)
                        )
                    }
                }
                
                Spacer()
                
                // Devam butonu
                Button(action: {
                    if let gender = selectedGender {
                        registrationManager.updateGender(gender)
                        showBirthdayView = true
                    } else {
                        alertMessage = "Lütfen cinsiyetinizi seçin"
                        showAlert = true
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(selectedGender != nil ? Color.buttonlightGreen : Color.gray.opacity(0.5))
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: "arrow.right")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                }
                .disabled(selectedGender == nil)
                .padding(.bottom, 30)
            }
            .padding(.horizontal, 20)
        }
        .fullScreenCover(isPresented: $showBirthdayView) {
            RegisterBirthdayView()
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Hata"),
                message: Text(alertMessage),
                dismissButton: .default(Text("Tamam"))
            )
        }
    }
}

#Preview {
    RegisterGenderView()
} 
