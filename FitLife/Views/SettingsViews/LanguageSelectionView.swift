import SwiftUI

struct LanguageSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var localizationService = LocalizationService.shared
    
    let languages = [
        ("tr", "turkish"),
        ("en", "english")
    ]
    
    var body: some View {
        ZStack {
            Color.backgroundDarkBlue.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Üst bar
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Text("language".localized)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Boş alan (simetri için)
                    Color.clear
                        .frame(width: 40, height: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                // Dil listesi
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(languages, id: \.0) { languageCode, languageKey in
                            Button(action: {
                                localizationService.changeLanguage(to: languageCode)
                                dismiss()
                            }) {
                                HStack {
                                    Text(languageKey.localized)
                                        .font(.system(size: 16))
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    if localizationService.currentLanguage == languageCode {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.buttonlightGreen)
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .background(
                                    localizationService.currentLanguage == languageCode ? 
                                    Color.buttonlightGreen.opacity(0.1) : 
                                    Color.white.opacity(0.05)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            // Ayırıcı çizgi
                            if languageCode != languages.last?.0 {
                                Divider()
                                    .background(Color.white.opacity(0.1))
                            }
                        }
                    }
                }
                .padding(.top, 20)
            }
        }
    }
}

#Preview {
    LanguageSelectionView()
} 