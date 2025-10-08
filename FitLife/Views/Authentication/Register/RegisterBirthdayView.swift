import SwiftUI

struct RegisterBirthdayView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var registrationManager = RegistrationManager.shared
    @State private var currentStep = 4
    @State private var birthDate = Date()
    @State private var showWHView = false
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
                Text("Doğum tarihinizi seçin")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.top, 20)
                
                Text("Uygulamamızı kullanabilmeniz için en az 18 yaşında olmanız gerekmektedir.")
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.horizontal, 15)
                    .multilineTextAlignment(.center)
                
                Spacer()
                
                // DatePicker
                DatePicker("", selection: $birthDate, in: ...Date(), displayedComponents: .date)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .colorScheme(.dark)
                    .accentColor(.buttonlightGreen)
                    .frame(height: 200)
                    .padding(.horizontal)
                
                Spacer()
                
                // Devam butonu
                Button(action: {
                    // Yaş kontrolü
                    let calendar = Calendar.current
                    let ageComponents = calendar.dateComponents([.year], from: birthDate, to: Date())
                    if let age = ageComponents.year, age < 18 {
                        alertMessage = "18 yaşından küçükler kayıt olamaz"
                        showAlert = true
                        return
                    }
                    
                    registrationManager.updateBirthDate(birthDate)
                    showWHView = true
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.buttonlightGreen)
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: "arrow.right")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                }
                .padding(.bottom, 30)
            }
            .padding(.horizontal, 20)
        }
        .fullScreenCover(isPresented: $showWHView) {
            RegisterWHView()
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
    RegisterBirthdayView()
} 
