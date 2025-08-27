import SwiftUI
import WatchConnectivity

struct DataSharingSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var dataSharingEnabled = false
    @State private var healthAppSyncEnabled = false
    @State private var appleWatchSyncEnabled = false
    @State private var showHealthPermissionAlert = false
    @State private var showHealthErrorAlert = false
    @State private var healthErrorMessage = ""
    
    @ObservedObject private var healthKitService = HealthKitService.shared
    @ObservedObject private var dataSyncService = DataSyncService.shared
    @ObservedObject private var watchService = WatchConnectivityService.shared
    
    var body: some View {
        ZStack {
            Color.backgroundDarkBlue.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Üst başlık
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                            .imageScale(.large)
                    }
                    
                    Spacer()
                    
                    Text("data_sharing_sync".localized)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Spacer()
                }
                .padding()
                .background(Color.backgroundDarkBlue.opacity(0.8))
                
                // İçerik
                ScrollView {
                    VStack(spacing: 20) {
                        // Veri Senkronizasyonu Bölümü
                        VStack(alignment: .leading, spacing: 12) {
                            Text("cloud_sync".localized)
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            // Sync durumu
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "icloud.fill")
                                        .foregroundColor(.buttonlightGreen)
                                    Text("cloud_sync".localized)
                                        .foregroundColor(.white)
                                    Spacer()
                                    
                                    // Durum göstergesi
                                    HStack(spacing: 4) {
                                        Circle()
                                            .fill(syncStatusColor)
                                            .frame(width: 8, height: 8)
                                        Text(dataSyncService.syncStatus.description)
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                                
                                // Son sync tarihi
                                if let lastSync = dataSyncService.lastSyncDate {
                                    Text("last_sync".localized + ": \(dataSyncService.timeSinceLastSync)")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                } else {
                                    Text("never_synced".localized)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                
                                // Progress bar
                                if dataSyncService.isSyncing {
                                    ProgressView(value: dataSyncService.syncProgress)
                                        .progressViewStyle(LinearProgressViewStyle(tint: .buttonlightGreen))
                                        .frame(height: 4)
                                }
                            }
                            
                            Divider()
                                .background(Color.white.opacity(0.3))
                            
                            // Sync butonları - minimal tasarım
                            VStack(spacing: 0) {
                                // Manuel sync butonu
                                Button(action: {
                                    print("🔄 Manuel senkronizasyon başlatılıyor...")
                                    dataSyncService.performFullSync()
                                }) {
                                    HStack {
                                        Image(systemName: dataSyncService.isSyncing ? "arrow.triangle.2.circlepath" : "arrow.clockwise")
                                            .foregroundColor(.buttonlightGreen)
                                            .rotationEffect(.degrees(dataSyncService.isSyncing ? 360 : 0))
                                            .animation(dataSyncService.isSyncing ? Animation.linear(duration: 1).repeatForever(autoreverses: false) : .default, value: dataSyncService.isSyncing)
                                        
                                        Text(dataSyncService.isSyncing ? "Senkronize ediliyor..." : "manual_sync".localized)
                                            .foregroundColor(.white)
                                        Spacer()
                                    }
                                    .padding(.vertical, 8)
                                }
                                .disabled(dataSyncService.isSyncing)
                                
                                Divider()
                                    .background(Color.white.opacity(0.2))
                                
                                // Sadece upload
                                Button(action: {
                                    print("⬆️ Sadece yükleme başlatılıyor...")
                                    dataSyncService.syncToFirestore { success, error in
                                        if success {
                                            print("✅ Yükleme başarılı")
                                        } else {
                                            print("❌ Yükleme hatası: \(error ?? "Bilinmeyen hata")")
                                        }
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: "icloud.and.arrow.up")
                                            .foregroundColor(.blue)
                                        Text("upload_only".localized)
                                            .foregroundColor(.white)
                                        Spacer()
                                    }
                                    .padding(.vertical, 8)
                                }
                                .disabled(dataSyncService.isSyncing)
                                
                                Divider()
                                    .background(Color.white.opacity(0.2))
                                
                                // Sadece download
                                Button(action: {
                                    print("⬇️ Sadece indirme başlatılıyor...")
                                    dataSyncService.syncFromFirestore { success, error in
                                        if success {
                                            print("✅ İndirme başarılı")
                                        } else {
                                            print("❌ İndirme hatası: \(error ?? "Bilinmeyen hata")")
                                        }
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: "icloud.and.arrow.down")
                                            .foregroundColor(.orange)
                                        Text("download_only".localized)
                                            .foregroundColor(.white)
                                        Spacer()
                                    }
                                    .padding(.vertical, 8)
                                }
                                .disabled(dataSyncService.isSyncing)
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                        
                        // Entegrasyon seçenekleri
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Uygulama Entegrasyonları")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            // Apple Sağlık Uygulaması
                            Toggle(isOn: $healthAppSyncEnabled) {
                                HStack {
                                    Image(systemName: "heart.fill")
                                        .foregroundColor(.red)
                                    VStack(alignment: .leading) {
                                        Text("health_app_sync".localized)
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        Text("Adım, kalori ve egzersiz verilerinizi Sağlık uygulamasıyla senkronize edin")
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.7))
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                            }
                            .tint(.buttonlightGreen)
                            .onChange(of: healthAppSyncEnabled) {
                                if healthAppSyncEnabled {
                                    // Gerçek HealthKit izinlerini iste
                                    Task {
                                        await requestHealthKitPermission()
                                    }
                                } else {
                                    // Kapatıldığında sadece ayarı kaydet
                                    DataStorageService.shared.setHealthAppSyncEnabled(false)
                                    healthKitService.stopObservingHealthData()
                                }
                            }
                            
                            Divider()
                                .background(Color.white.opacity(0.3))
                            
                            // Apple Watch Bölümü
                            VStack(alignment: .leading, spacing: 12) {
                                Toggle(isOn: $appleWatchSyncEnabled) {
                                    HStack {
                                        Image(systemName: "applewatch")
                                            .foregroundColor(.white)
                                        VStack(alignment: .leading) {
                                            Text("apple_watch_sync".localized)
                                                .font(.headline)
                                                .foregroundColor(.white)
                                            Text("Egzersizlerinizi ve aktivite hedeflerinizi Apple Watch'unuzla senkronize edin")
                                                .font(.caption)
                                                .foregroundColor(.white.opacity(0.7))
                                                .fixedSize(horizontal: false, vertical: true)
                                        }
                                    }
                                }
                                .tint(.buttonlightGreen)
                                .onChange(of: appleWatchSyncEnabled) {
                                    if appleWatchSyncEnabled {
                                        // Apple Watch bağlantısını kontrol et
                                        checkAppleWatchConnection()
                                    } else {
                                        // Kapatıldığında sadece ayarı kaydet
                                        DataStorageService.shared.setAppleWatchSyncEnabled(false)
                                    }
                                }
                                
                                // Apple Watch Durum Bilgisi
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: watchStatusIcon)
                                            .foregroundColor(watchStatusColor)
                                        Text(watchService.connectionStatus.description)
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.8))
                                        Spacer()
                                    }
                                    
                                    // Watch bilgileri (eğer bağlıysa)
                                    if let watchInfo = watchService.watchInfo, watchService.connectionStatus.isConnected {
                                        VStack(alignment: .leading, spacing: 4) {
                                            HStack {
                                                Text(watchInfo.name)
                                                    .font(.caption)
                                                    .foregroundColor(.white)
                                                Spacer()
                                                Text(watchInfo.batteryStatus)
                                                    .font(.caption)
                                                    .foregroundColor(.white.opacity(0.7))
                                            }
                                            
                                            HStack {
                                                Text("\(watchInfo.model) • watchOS \(watchInfo.systemVersion)")
                                                    .font(.caption2)
                                                    .foregroundColor(.white.opacity(0.6))
                                                Spacer()
                                            }
                                            
                                            if let lastSync = watchService.lastSyncDate {
                                                Text("Son senkronizasyon: \(formatDate(lastSync))")
                                                    .font(.caption2)
                                                    .foregroundColor(.white.opacity(0.6))
                                            }
                                        }
                                    }
                                    
                                    // Bağlantı durumuna göre aksiyon butonları
                                    if watchService.connectionStatus == .connected {
                                        Button(action: {
                                            // Test verisi gönder
                                            watchService.sendHealthDataToWatch(
                                                steps: healthKitService.dailySteps,
                                                calories: healthKitService.dailyCalories
                                            )
                                        }) {
                                            HStack {
                                                Image(systemName: "arrow.right.circle")
                                                    .foregroundColor(.buttonlightGreen)
                                                Text("Test Verisi Gönder")
                                                    .font(.caption)
                                                    .foregroundColor(.buttonlightGreen)
                                            }
                                        }
                                    } else if watchService.connectionStatus == .notInstalled {
                                        Button(action: {
                                            // App Store'a yönlendir (Watch uygulaması için)
                                            // Bu gerçek uygulamada implement edilebilir
                                        }) {
                                            HStack {
                                                Image(systemName: "arrow.down.circle")
                                                    .foregroundColor(.blue)
                                                Text("Watch Uygulamasını İndir")
                                                    .font(.caption)
                                                    .foregroundColor(.blue)
                                            }
                                        }
                                    }
                                }
                                .padding(.top, 8)
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                        
                        // Veri erişimi açıklaması
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Veri Erişimi")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            HStack(alignment: .top) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.yellow)
                                
                                Text("FitLife, yalnızca seçtiğiniz verilere erişir ve gizliliğiniz her zaman korunur. İstediğiniz zaman bu izinleri iptal edebilirsiniz.")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .padding()
                }
            }
        }
        .alert("HealthKit Hatası", isPresented: $showHealthErrorAlert) {
            Button("Tamam") {}
        } message: {
            Text(healthErrorMessage)
        }
        .onAppear {
            // Mevcut kullanıcı tercihlerini yükle
            dataSharingEnabled = DataStorageService.shared.isDataSharingEnabled()
            healthAppSyncEnabled = DataStorageService.shared.isHealthAppSyncEnabled()
            appleWatchSyncEnabled = DataStorageService.shared.isAppleWatchSyncEnabled()
            
            // Auto sync kontrolü
            if dataSyncService.shouldAutoSync {
                dataSyncService.performFullSync()
            }
            
            // Watch bilgilerini güncelle
            if watchService.connectionStatus.isConnected {
                watchService.requestWatchInfo()
            }
        }
    }
    
    // Watch durumu ikonu
    private var watchStatusIcon: String {
        switch watchService.connectionStatus {
        case .connected:
            return "checkmark.circle.fill"
        case .appInstalled:
            return "exclamationmark.circle.fill"
        case .notInstalled:
            return "xmark.circle.fill"
        case .notSupported, .notAvailable:
            return "questionmark.circle.fill"
        default:
            return "circle.fill"
        }
    }
    
    // Watch durumu rengi
    private var watchStatusColor: Color {
        switch watchService.connectionStatus {
        case .connected:
            return .green
        case .appInstalled:
            return .orange
        case .notInstalled:
            return .red
        case .notSupported, .notAvailable:
            return .gray
        default:
            return .yellow
        }
    }
    
    // Sync durumu rengi
    private var syncStatusColor: Color {
        switch dataSyncService.syncStatus {
        case .idle:
            return .gray
        case .syncing:
            return .blue
        case .success:
            return .green
        case .error:
            return .red
        }
    }
    
    // Tarih formatlama
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // MARK: - HealthKit İzin İsteme
    @MainActor
    private func requestHealthKitPermission() async {
        do {
            await healthKitService.requestAuthorization()
            
            if healthKitService.isAuthorized {
                // İzin başarılı - ayarı kaydet ve veri çekmeye başla
                DataStorageService.shared.setHealthAppSyncEnabled(true)
                healthKitService.startObservingHealthData()
            } else {
                // İzin reddedildi - toggle'ı geri al
                healthAppSyncEnabled = false
                DataStorageService.shared.setHealthAppSyncEnabled(false)
                
                if let error = healthKitService.authorizationError {
                    healthErrorMessage = error
                    showHealthErrorAlert = true
                }
            }
        } catch {
            // Hata oluştu - toggle'ı geri al
            healthAppSyncEnabled = false
            DataStorageService.shared.setHealthAppSyncEnabled(false)
            healthErrorMessage = "HealthKit izni alınırken hata oluştu: \(error.localizedDescription)"
            showHealthErrorAlert = true
        }
    }
    
    // MARK: - Apple Watch Bağlantı Kontrolü
    private func checkAppleWatchConnection() {
        // WatchConnectivityService zaten bağlantıyı yönetiyor
        // Sadece ayarı güncelle
        if watchService.connectionStatus.isConnected {
            DataStorageService.shared.setAppleWatchSyncEnabled(true)
            // Watch'a sağlık verilerini gönder
            watchService.sendHealthDataToWatch(
                steps: healthKitService.dailySteps,
                calories: healthKitService.dailyCalories
            )
        } else {
            appleWatchSyncEnabled = false
            DataStorageService.shared.setAppleWatchSyncEnabled(false)
            
            // Duruma göre hata mesajı göster
            switch watchService.connectionStatus {
            case .notSupported:
                healthErrorMessage = "Bu cihaz Apple Watch bağlantısını desteklemiyor."
            case .notInstalled:
                healthErrorMessage = "FitLife uygulaması Apple Watch'unuzda yüklü değil. Lütfen App Store'dan indirin."
            case .notAvailable:
                healthErrorMessage = "Apple Watch bulunamadı. Lütfen Watch'unuzun eşleştirildiğinden emin olun."
            case .inactive, .notActivated:
                healthErrorMessage = "Apple Watch bağlantısı kurulamadı. Lütfen tekrar deneyin."
            default:
                healthErrorMessage = "Apple Watch bağlantı hatası."
            }
            showHealthErrorAlert = true
        }
    }
}

#Preview {
    DataSharingSettingsView()
} 