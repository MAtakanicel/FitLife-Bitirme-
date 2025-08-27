import SwiftUI

struct EmptySearchView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.3))
            
            VStack(spacing: 8) {
                Text("Sonuç Bulunamadı")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text("Aradığınız yiyecek bulunamadı.\nFarklı anahtar kelimeler deneyin.")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Öneriler:")
                    .font(.headline)
                    .foregroundColor(.white)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("• Daha genel terimler kullanın")
                    Text("• Yazım hatalarını kontrol edin")
                    Text("• İngilizce terimler deneyin")
                    Text("• Marka ismi yerine genel isim kullanın")
                }
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.white.opacity(0.1))
            .cornerRadius(12)
        }
        .padding(.horizontal, 20)
        .padding(.top, 40)
    }
}

#Preview {
    ZStack {
        Color.backgroundDarkBlue.ignoresSafeArea()
        EmptySearchView()
    }
} 