import SwiftUI

struct RegionSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedRegion: String
    
    let countries = [
        ("Türkiye", "turkey"),
        ("Amerika Birleşik Devletleri", "united_states"),
        ("Almanya", "germany"),
        ("Fransa", "france"),
        ("İngiltere", "united_kingdom"),
        ("İtalya", "italy"),
        ("İspanya", "spain"),
        ("Japonya", "japan"),
        ("Çin", "china"),
        ("Hindistan", "india"),
        ("Brezilya", "brazil"),
        ("Kanada", "canada"),
        ("Avustralya", "australia"),
        ("Rusya", "russia"),
        ("Güney Kore", "south_korea"),
        ("Hollanda", "netherlands"),
        ("İsveç", "sweden"),
        ("Norveç", "norway"),
        ("Danimarka", "denmark"),
        ("Belçika", "belgium"),
        ("İsviçre", "switzerland"),
        ("Avusturya", "austria"),
        ("Polonya", "poland"),
        ("Çek Cumhuriyeti", "czech_republic"),
        ("Yunanistan", "greece")
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
                    
                    Text("region".localized)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Boş alan (simetri için)
                    Color.clear
                        .frame(width: 40, height: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                // Ülke listesi
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(countries, id: \.0) { countryKey, localizedKey in
                            Button(action: {
                                selectedRegion = countryKey
                                // Seçimi kaydet
                                DataStorageService.shared.setRegion(countryKey)
                                dismiss()
                            }) {
                                HStack {
                                    Text(localizedKey.localized)
                                        .font(.system(size: 16))
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    if selectedRegion == countryKey {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.buttonlightGreen)
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .background(
                                    selectedRegion == countryKey ? 
                                    Color.buttonlightGreen.opacity(0.1) : 
                                    Color.white.opacity(0.05)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            // Ayırıcı çizgi
                            if countryKey != countries.last?.0 {
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
    RegionSelectionView(selectedRegion: .constant("Türkiye"))
} 