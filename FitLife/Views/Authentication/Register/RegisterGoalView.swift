import SwiftUI

struct RegisterGoalView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var registrationManager = RegistrationManager.shared
    @State private var selectedGoal = 0
    @State private var targetWeight = ""
    @State private var targetWeightUnit = "kg"
    @State private var currentStep = 7
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showCompletionSheet = false
    @FocusState private var isTargetWeightFocused: Bool
    
    let goals = ["Kilonu koru", "Kilo ver", "Kilo al"]
    
    var showTargetWeight: Bool {
        return selectedGoal == 2 || selectedGoal == 1 // Kilo al veya Kilo ver seçildiğinde
    }
    
    // Dönüştürülmüş hedef kilo değeri
    var convertedTargetWeight: Double {
        guard let weightValue = Double(targetWeight) else { return 0 }
        return targetWeightUnit == "lb" ? weightValue / 2.20462 : weightValue
    }
    
    var body: some View {
        ZStack {
            Color.backgroundDarkBlue.ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Üst Kısım
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
                    Text("Hedef")
                        .font(.system(size: 35, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Uygulamayı Kullanma hedefinizi seçiniz. Diyetiniz sonucunda kaç kilo olmak istersiniz ?")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.75))
                        .padding(.bottom, 10)
                    
                    // Hedef seçimi
                    GoalPickerView(selectedGoal: $selectedGoal, goals: goals)
                        .frame(height: 150)
                        .padding(.horizontal)
                    
                    // Hedef kilo girişi (sadece kilo al/ver seçildiğinde göster)
                    if showTargetWeight {
                        VStack(spacing: 10) {
                            Text("Hedef kilonuzu girin")
                                .foregroundColor(.white.opacity(0.7))
                                .font(.system(size: 20))
                            
                            HStack {
                                TextField("", text: $targetWeight)
                                    .keyboardType(.numberPad)
                                    .focused($isTargetWeightFocused)
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
                                        targetWeightUnit = "kg"
                                    }
                                    Button("lb") {
                                        targetWeightUnit = "lb"
                                    }
                                } label: {
                                    Text(targetWeightUnit)
                                        .foregroundColor(.white)
                                        .frame(width: 50, height: 50)
                                        .font(.system(size: 24))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color.white.opacity(0.3), lineWidth: 2)
                                        )
                                }
                            }
                        }
                        .padding(.top, 20)
                        .transition(.opacity)
                    }
                }
                .padding(.top, 20)
                
                Spacer()
            }
            
            // Devam butonu
            VStack {
                Spacer()
                
                Button(action: {
                    if showTargetWeight && targetWeight.isEmpty {
                        alertMessage = "Lütfen hedef kilonuzu girin"
                        showAlert = true
                        return
                    }
                    
                    // Hedef seçimine göre FitnessGoal'u belirle
                    let goal: FitnessGoal
                    switch selectedGoal {
                    case 0:
                        goal = .maintainWeight
                    case 1:
                        goal = .loseWeight
                    case 2:
                        goal = .gainWeight
                    default:
                        goal = .maintainWeight
                    }
                    
                    // Sonraki adıma geçiş
                    currentStep += 1
                    registrationManager.updateGoal(goal)
                    if showTargetWeight {
                        registrationManager.updateTargetWeight(convertedTargetWeight)
                    }
                    showCompletionSheet = true
                }) {
                    ZStack {
                        Circle()
                            .fill(isFormValid ? Color.buttonlightGreen : Color.gray.opacity(0.5))
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: "arrow.right")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .disabled(!isFormValid)
                .padding(.bottom, 30)
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .sheet(isPresented: $showCompletionSheet) {
           
            GoalCompletionSheetView()
                .presentationDetents([.fraction(0.35)])
            
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Hata"),
                message: Text(alertMessage),
                dismissButton: .default(Text("Tamam"))
            )
        }
    }
    
    private var isFormValid: Bool {
        if showTargetWeight {
            return !targetWeight.isEmpty
        }
        return true
    }
}
 //Hedef Seçimi PickerView
struct GoalPickerView: UIViewRepresentable {
    @Binding var selectedGoal: Int
    let goals: [String]
    
    func makeUIView(context: Context) -> UIPickerView {
        let picker = UIPickerView()
        picker.delegate = context.coordinator
        picker.dataSource = context.coordinator
        picker.backgroundColor = .clear
        return picker
    }
    
    func updateUIView(_ uiView: UIPickerView, context: Context) {
        uiView.selectRow(selectedGoal, inComponent: 0, animated: true)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIPickerViewDelegate, UIPickerViewDataSource {
        var parent: GoalPickerView
        
        init(_ parent: GoalPickerView) {
            self.parent = parent
        }
        
        func numberOfComponents(in pickerView: UIPickerView) -> Int {
            return 1
        }
        
        func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
            return parent.goals.count
        }
        
        func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
            let label = UILabel()
            label.text = parent.goals[row]
            label.textColor = .white
            label.font = .systemFont(ofSize: 24)
            label.textAlignment = .center
            return label
        }
        
        func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
            parent.selectedGoal = row
        }
    }
}

struct GoalCompletionSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showLoginScreen = false
    @State private var showFinalScreen = false
    
    var body: some View {
        ZStack {
            Color.backgroundDarkBlue.ignoresSafeArea()
            
            VStack(spacing: 15) {
                Text("Kaydını tamamla")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 30)
                    .padding(.bottom,10)
                
                Button(action: {
                    showFinalScreen.toggle()
                }) {
                    Text("E-posta Kullan")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.buttonGreen)
                        .cornerRadius(10)
                }
                .padding(.horizontal, 30)
                .fullScreenCover(isPresented: $showFinalScreen, content: {
                    RegisterFinalView(registrationManager: RegistrationManager.shared)
                })
                
                Text("veya")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.75))
                
                Button(action: {
                    // Apple ile devam et
                }) {
                    HStack {
                        Image(systemName: "apple.logo")
                            .font(.title2)
                        Text("Apple ile devam et")
                            .font(.headline)
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.white)
                    .cornerRadius(10)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 10)
                
                HStack(spacing:10){
                    Text("Zaten bir hesabınız var mı ?")
                        
                    Button(action: {
                        showLoginScreen = true
                    }){
                        Text("Giriş Yap")
                            .foregroundColor(.buttonlightGreen)
                            
                    }
                    .fullScreenCover(isPresented: $showLoginScreen, content:{
                        LoginView()
                    
                    } )
                }
            }
        }
    }
}

#Preview {
    RegisterGoalView()
} 
