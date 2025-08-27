import SwiftUI

struct RegisterInfoView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentStep = 2
    @State private var showRegisterGenderView = false
    let screenHeight = UIScreen.main.bounds.height
    
    var body: some View {
        ZStack {
            Color.backgroundDarkBlue.ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Üst kısım 
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
                Text("Profilinizi Ayarlama")
                    .font(.system(size: 35, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.top, 20)
                
                Spacer()
                Spacer()
                
                // Açıklama metni
                Text("Hedeflerinize ulaşmanıza yardımcı olmak için, tavsiye edilen günlük kalori tüketiminizi hesaplayarak başlayacağız. Bu ideal olarak her gün ne kadar besin tüketebileceğinizi gösterir. Aktivite miktarınız, yaşınız, boyunuz ve diğer özellikleriniz bu değeri etkiler.")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                    .padding(.bottom, 35)
                Spacer()
                Spacer()
                // Devam butonu - orta konumda
                Button(action: {
                    // Sonraki adıma geçiş
                    if currentStep < 7 {
                        currentStep += 1
                        showRegisterGenderView = true
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.buttonlightGreen)
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: "arrow.right")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .padding(.bottom, screenHeight * 0.05)
                .frame(maxWidth: .infinity, alignment: .center)
                
                
            }
        }
        .fullScreenCover(isPresented: $showRegisterGenderView) {
            RegisterGenderView()
        }
    }
}

#Preview {
    RegisterInfoView()
} 
