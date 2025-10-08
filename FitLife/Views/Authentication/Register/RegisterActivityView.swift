import SwiftUI

struct RegisterActivityView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var registrationManager = RegistrationManager.shared
    @State private var selectedActivityLevel: ActivityLevel?
    @State private var showRegisterGoalView = false
    @State private var currentStep = 6
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
                
                // İçerik
                VStack(alignment: .center, spacing: 15) {
                    Text("Aktivite Seviyesi")
                        .font(.system(size: 35, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Günlük aktivite seviyenizi seçin")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.75))
                        .padding(.bottom, 10)
                    
                    // Aktivite seviyesi seçimi
                    VStack(spacing: 15) {
                        ForEach(ActivityLevel.allCases, id: \.self) { level in
                            Button(action: {
                                selectedActivityLevel = level
                            }) {
                                HStack {
                                    Text(level.description)
                                        .font(.system(size: 18))
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    if selectedActivityLevel == level {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(Color.buttonlightGreen)
                                    }
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 15)
                                        .stroke(selectedActivityLevel == level ? Color.buttonlightGreen : Color.white.opacity(0.3), lineWidth: 2)
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.top, 20)
                
                Spacer()
            }
            
            // Devam butonu
            VStack {
                Spacer()
                
                Button(action: {
                    if let activityLevel = selectedActivityLevel {
                        registrationManager.updateActivityLevel(activityLevel)
                        showRegisterGoalView = true
                    } else {
                        alertMessage = "Lütfen aktivite seviyenizi seçin"
                        showAlert = true
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(selectedActivityLevel != nil ? Color.buttonlightGreen : Color.gray.opacity(0.5))
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: "arrow.right")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .disabled(selectedActivityLevel == nil)
                .padding(.bottom, 30)
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .fullScreenCover(isPresented: $showRegisterGoalView) {
            RegisterGoalView()
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
    RegisterActivityView()
} 
