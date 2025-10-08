import SwiftUI

struct RegisterWHView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var registrationManager = RegistrationManager.shared
    @State private var currentStep = 5
    @State private var height = ""
    @State private var weight = ""
    @State private var heightUnit = "cm"
    @State private var weightUnit = "kg"
    @FocusState private var focusedField: Field?
    @State private var showRegisterActivityView = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    enum Field {
        case height, weight
    }
    
    // Dönüştürülmüş değerleri hesapla
    var convertedHeight: Double {
        guard let heightValue = Double(height) else { return 0 }
        return heightUnit == "inch" ? heightValue * 2.54 : heightValue
    }
    
    var convertedWeight: Double {
        guard let weightValue = Double(weight) else { return 0 }
        return weightUnit == "lb" ? weightValue / 2.20462 : weightValue
    }
    
    var body: some View {
        ZStack {
            Color.backgroundDarkBlue.ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Geri butonu ve adım göstergesi
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
                Text("Boyunuz ve kilonuz")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.top, 20)
                
                // İkinci metin - klavye açıkken gizlenecek
                if focusedField == nil {
                    Text("Tüketmeniz gereken kalori miktarını hesaplamamız için gerekli bilgilerden ikisidir.")
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.horizontal, 10)
                        .transition(.opacity)
                }
                
                Spacer()
                
                // Boy ve kilo giriş alanları
                VStack(spacing: 20) {
                    // Boy girişi
                    HStack {
                        TextField("", text: $height)
                            .keyboardType(.numberPad)
                            .focused($focusedField, equals: .height)
                            .foregroundColor(.white)
                            .font(.system(size: 24))
                            .multilineTextAlignment(.center)
                            .frame(width: 100)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 2)
                            )
                        
                        // Boy birimi seçimi
                        Menu {
                            Button("cm") {
                                heightUnit = "cm"
                            }
                            Button("inch") {
                                heightUnit = "inch"
                            }
                        } label: {
                            Text(heightUnit)
                                .foregroundColor(.white)
                                .font(.system(size: 30))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .frame(width: 75, height: 60)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                                )
                        }
                    }
                    
                    // Kilo girişi
                    HStack {
                        TextField("", text: $weight)
                            .keyboardType(.numberPad)
                            .focused($focusedField, equals: .weight)
                            .foregroundColor(.white)
                            .font(.system(size: 24))
                            .multilineTextAlignment(.center)
                            .frame(width: 100)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 2)
                            )
                        
                        // Kilo birimi seçimi
                        Menu {
                            Button("kg") {
                                weightUnit = "kg"
                            }
                            Button("lb") {
                                weightUnit = "lb"
                            }
                        } label: {
                            Text(weightUnit)
                                .foregroundColor(.white)
                                .font(.system(size: 30))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .frame(width: 75, height: 60)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                                )
                        }
                    }
                }
                
                Spacer()
                
                // Devam butonu
                Button(action: {
                    // Validasyon kontrolleri
                    if height.isEmpty {
                        alertMessage = "Lütfen boyunuzu girin"
                        showAlert = true
                        return
                    }
                    
                    if weight.isEmpty {
                        alertMessage = "Lütfen kilonuzu girin"
                        showAlert = true
                        return
                    }
                    
                    let finalHeight = convertedHeight
                    let finalWeight = convertedWeight
                    
                    // Boy kontrolü (100-250 cm arası)
                    if finalHeight < 100 || finalHeight > 250 {
                        alertMessage = "Geçerli bir boy değeri girin (100-250 cm)"
                        showAlert = true
                        return
                    }
                    
                    // Kilo kontrolü (30-200 kg arası)
                    if finalWeight < 30 || finalWeight > 300 {
                        alertMessage = "Geçerli bir kilo değeri girin (30-300 kg)"
                        showAlert = true
                        return
                    }
                    
                    // Değerleri güncelle
                    registrationManager.updateHeight(finalHeight)
                    registrationManager.updateWeight(finalWeight)
                    registrationManager.updateTargetWeight(finalWeight) // Başlangıçta hedef kilo mevcut kilo olarak ayarlanır
                    
                    showRegisterActivityView = true
                }) {
                    ZStack {
                        Circle()
                            .fill(!height.isEmpty && !weight.isEmpty ? Color.buttonlightGreen : Color.gray.opacity(0.5))
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: "arrow.right")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                }
                .disabled(height.isEmpty || weight.isEmpty)
                .padding(.bottom, 30)
            }
            .padding(.horizontal, 20)
        }
        .dismissKeyboard()
        .fullScreenCover(isPresented: $showRegisterActivityView) {
            RegisterActivityView()
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
    RegisterWHView()
} 
