//
//  FitLifeApp.swift
//  FitLife
//
//  Created by Atakan İçel on 23.01.2025.
//
import SwiftUI
import Firebase

@main
struct FitLifeApp: App {
    // Oturum durumunu izlemek için
    @ObservedObject private var authManager = AuthenticationManager.shared
   
    //firebase başlatma
    init(){
        print("🚀 FitLifeApp init başladı...")
        
        // Firebase'i güvenli modda başlat
        do {
            FirebaseApp.configure()
            print("✅ Firebase konfigürasyonu tamamlandı")
            
            // FirebaseService'i configure et
                FirebaseService.shared.configure()
            
        } catch {
            print("❌ Firebase konfigürasyon hatası: \(error)")
            // Firebase hatası olsa bile uygulamanın çalışmasına devam et
        }
        
        print("✅ CoreData ready to use")
        
        // Firebase configure edildikten sonra AuthenticationManager'ı initialize et
                AuthenticationManager.shared.initializeAfterFirebaseConfig()
        print("✅ AuthenticationManager initialized")
        
        // Apple Watch Connectivity'yi başlat
            let _ = WatchConnectivityService.shared
            print("⌚ WatchConnectivityService başlatıldı")
        
        print("🎯 FitLifeApp init tamamlandı")
    }
    
    var body: some Scene {
        WindowGroup {
            if authManager.isAuthenticated {
                MainTabView()
                    .onAppear {
                        print("🏠 MainTabView appeared - User authenticated")
                    }
            } else {
                WelcomeView()
                    .preferredColorScheme(.dark)
                    .onAppear {
                        print("👋 WelcomeView appeared - User not authenticated")
                        print("📊 Auth status - isLoggedIn: \(authManager.isLoggedIn), isAuthenticated: \(authManager.isAuthenticated)")
                    }
            }
        }
        .onChange(of: authManager.isAuthenticated) { _, isAuthenticated in
            // Kullanıcı durumu değiştiğinde log
            print("🔄 Auth state changed: \(isAuthenticated)")
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                print("📱 App became active")
            case .inactive:
                print("📱 App became inactive")
            case .background:
                print("📱 App moved to background - saving data...")
                saveUserDataOnBackground()
            @unknown default:
                break
            }
        }
    }
    
    @Environment(\.scenePhase) private var scenePhase
    
    /// Uygulama arka plana geçerken kullanıcı verilerini kaydet
    private func saveUserDataOnBackground() {
        // Sadece oturum açık kullanıcılar için kaydet
        guard authManager.isAuthenticated else { return }
        
        print("🔄 Arka plana geçiş - kullanıcı verileri kaydediliyor...")
        
        let dataStorage = DataStorageService.shared
        let firebaseService = FirebaseService.shared
        
        // UserDefaults'tan mevcut veriyi al
        guard let userData = dataStorage.loadRegistrationData() else {
            print("⚠️ Arka plan kaydı için kullanıcı verisi bulunamadı")
            return
        }
        
        // Firebase'e kaydet
        FirebaseService.shared.updateUserProfile(userData: userData) { success, error in
            if success {
                print("✅ Arka plan - veriler Firebase'e kaydedildi")
            } else {
                print("⚠️ Arka plan - Firebase'e kaydetme başarısız: \(error ?? "Bilinmeyen hata")")
            }
        }
    }
}
