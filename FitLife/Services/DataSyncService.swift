import Foundation
import Combine

class DataSyncService: ObservableObject {
    static let shared = DataSyncService()
    
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var syncStatus: SyncStatus = .idle
    @Published var syncProgress: Double = 0.0
    
    private let firebaseService = FirebaseService.shared
    private let coreDataService = CoreDataService.shared
    
    private init() {
        loadLastSyncDate()
    }
    
    enum SyncStatus {
        case idle
        case syncing
        case success
        case error(String)
        
        var description: String {
            switch self {
            case .idle:
                return "Hazır"
            case .syncing:
                return "Senkronize ediliyor..."
            case .success:
                return "Başarılı"
            case .error(let message):
                return "Hata: \(message)"
            }
        }
    }
    
    // MARK: - Public Methods
    
    func performFullSync() {
        guard !isSyncing else { 
            print("⚠️ Senkronizasyon zaten devam ediyor, atlanıyor...")
            return 
        }
        
        print("🚀 Tam senkronizasyon başlatılıyor...")
        
        DispatchQueue.main.async {
            self.isSyncing = true
            self.syncStatus = .syncing
            self.syncProgress = 0.0
        }
        
        // Önce Firestore'dan veri al
        print("⬇️ 1. Aşama: Firestore'dan veri çekiliyor...")
        syncFromFirestore { [weak self] success, error in
            if success {
                print("✅ 1. Aşama tamamlandı: Firestore'dan veri çekildi")
                self?.updateProgress(0.5)
                
                // Sonra CoreData'dan Firestore'a gönder
                print("⬆️ 2. Aşama: CoreData'dan Firestore'a veri yükleniyor...")
                self?.syncToFirestore { success, error in
                    DispatchQueue.main.async {
                        self?.isSyncing = false
                        self?.syncProgress = 1.0
                        
                        if success {
                            print("✅ 2. Aşama tamamlandı: Veriler Firestore'a yüklendi")
                            print("🎉 Tam senkronizasyon başarıyla tamamlandı!")
                            self?.syncStatus = .success
                            self?.lastSyncDate = Date()
                            self?.saveLastSyncDate()
                            
                            // 3 saniye sonra idle'a dön
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                self?.syncStatus = .idle
                                self?.syncProgress = 0.0
                            }
                        } else {
                            print("❌ 2. Aşama başarısız: \(error ?? "Bilinmeyen hata")")
                            self?.syncStatus = .error(error ?? "Bilinmeyen hata")
                        }
                    }
                }
            } else {
                print("❌ 1. Aşama başarısız: \(error ?? "Firestore'dan veri alma hatası")")
                DispatchQueue.main.async {
                    self?.isSyncing = false
                    self?.syncStatus = .error(error ?? "Firestore'dan veri alma hatası")
                    self?.syncProgress = 0.0
                }
            }
        }
    }
    
    func syncToFirestore(completion: @escaping (Bool, String?) -> Void) {
        firebaseService.syncAllDataToFirestore(completion: completion)
    }
    
    func syncFromFirestore(completion: @escaping (Bool, String?) -> Void) {
        firebaseService.syncDataFromFirestore(completion: completion)
    }
    
    func enableAutoSync() {
        firebaseService.enableAutoSync()
    }
    
    // MARK: - Private Methods
    
    private func updateProgress(_ progress: Double) {
        DispatchQueue.main.async {
            self.syncProgress = progress
        }
    }
    
    private let dataStorage = DataStorageService.shared
    
    private func loadLastSyncDate() {
        lastSyncDate = dataStorage.getLastSyncDate()
    }
    
    private func saveLastSyncDate() {
        if let date = lastSyncDate {
            dataStorage.setLastSyncDate(date)
        }
    }
    
    // MARK: - Utility Methods
    
    var timeSinceLastSync: String {
        guard let lastSync = lastSyncDate else {
            return "Henüz senkronize edilmedi"
        }
        
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: lastSync, relativeTo: Date())
    }
    
    var shouldAutoSync: Bool {
        guard let lastSync = lastSyncDate else { return true }
        
        // 1 saatten fazla geçmişse otomatik sync yap
        return Date().timeIntervalSince(lastSync) > 3600
    }
} 