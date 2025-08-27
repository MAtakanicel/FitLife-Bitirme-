import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
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
                    
                    Text("about_title".localized)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Boş alan (simetri için)
                    Color.clear
                        .frame(width: 40, height: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                // İçerik
                ScrollView {
                    VStack(spacing: 24) {
                        // Logo ve başlık
                        VStack(spacing: 16) {
                            Image("ScreenLogo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 120, height: 120)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .shadow(color: .buttonlightGreen.opacity(0.3), radius: 10)
                            
                            Text("FitLife")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("about_app".localized)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 20)
                        
                        // Geliştirici bilgileri kartı
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "person.fill")
                                    .foregroundColor(.buttonlightGreen)
                                    .font(.system(size: 20))
                                Text("developer_info".localized)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            
                            Text("developer_description".localized)
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                                .lineLimit(nil)
                        }
                        .padding(20)
                        .background(Color.white.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        
                        // Önemli uyarı kartı
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                    .font(.system(size: 20))
                                Text("important_notice".localized)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            
                            Text("ai_disclaimer".localized)
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                                .lineLimit(nil)
                        }
                        .padding(20)
                        .background(Color.orange.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        
                        // Teknolojiler kartı
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "gear.circle.fill")
                                    .foregroundColor(.buttonlightGreen)
                                    .font(.system(size: 20))
                                Text("technologies".localized)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                TechRow(icon: "swift", text: "swift_swiftui".localized)
                                TechRow(icon: "person.badge.key.fill", text: "firebase_auth".localized)
                                TechRow(icon: "externaldrive.fill.badge.icloud", text: "coredata_firestore".localized)
                                TechRow(icon: "heart.fill", text: "healthkit_integration".localized)
                                TechRow(icon: "brain.head.profile", text: "ai_recommendations".localized)
                            }
                        }
                        .padding(20)
                        .background(Color.white.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        
                        // Telif hakkı
                        Text("copyright".localized)
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.top, 20)
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }
}

struct InfoRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.buttonlightGreen)
                .frame(width: 20)
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.white)
            Spacer()
        }
    }
}

struct TechRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.buttonlightGreen)
                .frame(width: 20)
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.white)
            Spacer()
        }
    }
}

#Preview {
    AboutView()
} 