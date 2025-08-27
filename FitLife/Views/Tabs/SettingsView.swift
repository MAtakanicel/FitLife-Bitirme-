import SwiftUI
import UserNotifications

struct SettingsView: View {
    @State private var showConfirmLogout = false
    @State private var showLoginView = false
    @State private var dataSharing = true
    @State private var region = "Türkiye"
    @State private var showDataSharingSettings = false
    @State private var showProfileEdit = false
    @State private var showPasswordChange = false
    @State private var showAbout = false
    @State private var showRegionSelection = false
    @State private var showLanguageSelection = false
    
    @ObservedObject private var notificationManager = NotificationManager.shared
    @ObservedObject private var authManager = AuthenticationManager.shared
    @ObservedObject private var dataSyncService = DataSyncService.shared
    @ObservedObject private var localizationService = LocalizationService.shared
    
    var body: some View {
        ZStack {
            Color.backgroundDarkBlue.ignoresSafeArea()
            
            VStack(spacing: 0) {
                List {
                    Section(header: Text("account".localized)
                                .foregroundColor(.white)
                                .font(.headline)) {
                        
                        // Profil bilgileri
                        Button(action: {
                            showProfileEdit = true
                        }) {
                            HStack {
                                Image(systemName: "person.circle.fill")
                                    .foregroundColor(.buttonlightGreen)
                                Text("profile_info".localized)
                                    .foregroundColor(.white)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                        }
                        .listRowBackground(Color.white.opacity(0.1))
                        
                        // Şifre değiştir
                        Button(action: {
                            showPasswordChange = true
                        }) {
                            HStack {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(.buttonlightGreen)
                                Text("change_password".localized)
                                    .foregroundColor(.white)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                        }
                        .listRowBackground(Color.white.opacity(0.1))
                        
                        // Bildirimler
                        HStack {
                            Image(systemName: "bell.fill")
                                .foregroundColor(.buttonlightGreen)
                            Text("notifications".localized)
                                .foregroundColor(.white)
                            Spacer()
                            Toggle("", isOn: $notificationManager.isNotificationEnabled)
                                .toggleStyle(SwitchToggleStyle(tint: .buttonlightGreen))
                                .onChange(of: notificationManager.isNotificationEnabled) { _, newValue in
                                    handleNotificationToggle(newValue)
                                }
                        }
                        .listRowBackground(Color.white.opacity(0.1))
                        
                        // Bölge seçimi
                        Button(action: {
                            showRegionSelection = true
                        }) {
                            HStack {
                                Image(systemName: "map.fill")
                                    .foregroundColor(.buttonlightGreen)
                                Text("region".localized)
                                    .foregroundColor(.white)
                                Spacer()
                                Text(getLocalizedRegionName(region))
                                    .foregroundColor(.gray)
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                        }
                        .listRowBackground(Color.white.opacity(0.1))
                    }
                    
                    Section(header: Text("application".localized)
                                .foregroundColor(.white)
                                .font(.headline)) {
                        
                        // Tema seçimi
                        HStack {
                            Image(systemName: "moon.fill")
                                .foregroundColor(.buttonlightGreen)
                            Text("theme".localized)
                                .foregroundColor(.white)
                            Spacer()
                            Text("dark".localized)
                                .foregroundColor(.gray)
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .listRowBackground(Color.white.opacity(0.1))
                        
                        // Dil seçimi
                        Button(action: {
                            showLanguageSelection = true
                        }) {
                            HStack {
                                Image(systemName: "globe")
                                    .foregroundColor(.buttonlightGreen)
                                Text("language".localized)
                                    .foregroundColor(.white)
                                Spacer()
                                Text(localizationService.currentLanguage == "tr" ? "turkish".localized : "english".localized)
                                    .foregroundColor(.gray)
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                        }
                        .listRowBackground(Color.white.opacity(0.1))
                        
                        // Veri paylaşımı ve senkronizasyon ayarları 
                        Button(action: {
                            showDataSharingSettings = true
                        }) {
                            HStack {
                                Image(systemName: "chart.bar.doc.horizontal.fill")
                                    .foregroundColor(.buttonlightGreen)
                                Text("data_sharing_sync".localized)
                                    .foregroundColor(.white)
                                Spacer()    
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                        }
                        .listRowBackground(Color.white.opacity(0.1))
                    }
                    
                    Section(header: Text("other".localized)
                                .foregroundColor(.white)
                                .font(.headline)) {
                        
                        // Hakkında
                        Button(action: {
                            showAbout = true
                        }) {
                            HStack {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.buttonlightGreen)
                                Text("about".localized)
                                    .foregroundColor(.white)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                        }
                        .listRowBackground(Color.white.opacity(0.1))
                        
                        // Çıkış yap
                        Button(action: {
                            showConfirmLogout = true
                        }) {
                            HStack {
                                Image(systemName: "arrow.right.square.fill")
                                    .foregroundColor(.red)
                                Text("logout".localized)
                                    .foregroundColor(.white)
                                Spacer()
                            }
                        }
                        .listRowBackground(Color.white.opacity(0.1))
                    }
                }
                .listStyle(InsetGroupedListStyle())
                .scrollContentBackground(.hidden)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Text("settings".localized)
                    .font(.system(size: 40,weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .fullScreenCover(isPresented: $showDataSharingSettings) {
            DataSharingSettingsView()
        }
        .fullScreenCover(isPresented: $showProfileEdit) {
            ProfileEditView()
        }
        .fullScreenCover(isPresented: $showPasswordChange) {
            PasswordChangeView()
        }
        .fullScreenCover(isPresented: $showAbout) {
            AboutView()
        }
        .fullScreenCover(isPresented: $showRegionSelection) {
            RegionSelectionView(selectedRegion: $region)
        }
        .fullScreenCover(isPresented: $showLanguageSelection) {
            LanguageSelectionView()
        }
        .alert("logout".localized, isPresented: $showConfirmLogout) {
            Button("cancel".localized, role: .cancel) {}
            Button("logout".localized, role: .destructive) {
                // AuthenticationManager ile çıkış işlemini gerçekleştir
                authManager.logout()
                // UI güncellemesini tetikle
                showLoginView = true
            }
        } message: {
            Text("logout_confirmation".localized)
        }
        .fullScreenCover(isPresented: $showLoginView) {
            WelcomeView()
        }

        .onAppear {
            // Kullanıcı tercihlerini yükle
            dataSharing = DataStorageService.shared.isDataSharingEnabled()
            region = DataStorageService.shared.getRegion()
            
            // Bildirim durumunu kontrol et
            notificationManager.checkNotificationStatus()
            
            // Auto sync kontrolü
            if dataSyncService.shouldAutoSync {
                dataSyncService.performFullSync()
            }
        }
    }
    
    // Bölge adını lokalize et
    private func getLocalizedRegionName(_ regionName: String) -> String {
        switch regionName {
        case "Türkiye": return "turkey".localized
        case "Amerika Birleşik Devletleri": return "united_states".localized
        case "Almanya": return "germany".localized
        case "Fransa": return "france".localized
        case "İngiltere": return "united_kingdom".localized
        case "İtalya": return "italy".localized
        case "İspanya": return "spain".localized
        case "Japonya": return "japan".localized
        case "Çin": return "china".localized
        case "Hindistan": return "india".localized
        case "Brezilya": return "brazil".localized
        case "Kanada": return "canada".localized
        case "Avustralya": return "australia".localized
        case "Rusya": return "russia".localized
        case "Güney Kore": return "south_korea".localized
        case "Hollanda": return "netherlands".localized
        case "İsveç": return "sweden".localized
        case "Norveç": return "norway".localized
        case "Danimarka": return "denmark".localized
        case "Belçika": return "belgium".localized
        case "İsviçre": return "switzerland".localized
        case "Avusturya": return "austria".localized
        case "Polonya": return "poland".localized
        case "Çek Cumhuriyeti": return "czech_republic".localized
        case "Yunanistan": return "greece".localized
        default: return regionName
        }
    }
    
    // Bildirim toggle işlemini yönet
    private func handleNotificationToggle(_ isEnabled: Bool) {
        if isEnabled {
            // Bildirim açılmaya çalışılıyor
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                DispatchQueue.main.async {
                    switch settings.authorizationStatus {
                    case .notDetermined:
                        // İlk kez izin isteniyor
                        notificationManager.requestNotificationPermission { granted in
                            if !granted {
                                // İzin reddedildi - toggle'ı geri al
                                notificationManager.isNotificationEnabled = false
                            }
                        }
                    case .denied:
                        // İzin daha önce reddedilmiş - toggle'ı geri al
                        notificationManager.isNotificationEnabled = false
                    case .authorized:
                        // Zaten izin verilmiş - hiçbir şey yapma
                        break
                    default:
                        break
                    }
                }
            }
        } else {
            // Bildirimler kapatılıyor - sadece kapat
            notificationManager.disableNotifications()
        }
    }
}

#Preview {
    NavigationView {
        SettingsView()
    }
} 
