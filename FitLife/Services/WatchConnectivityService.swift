import Foundation
import WatchConnectivity
import Combine

class WatchConnectivityService: NSObject, ObservableObject {
    static let shared = WatchConnectivityService()
    
    @Published var isWatchAppInstalled: Bool = false
    @Published var isWatchReachable: Bool = false
    @Published var watchInfo: WatchInfo?
    @Published var connectionStatus: WatchConnectionStatus = .notAvailable
    @Published var lastSyncDate: Date?
    
    private var session: WCSession?
    
    override init() {
        super.init()
        setupWatchConnectivity()
    }
    
    // MARK: - Setup
    private func setupWatchConnectivity() {
        guard WCSession.isSupported() else {
            connectionStatus = .notSupported
            return
        }
        
        session = WCSession.default
        session?.delegate = self
        session?.activate()
    }
    
    // MARK: - Public Methods
    func sendHealthDataToWatch(steps: Int, calories: Double) {
        guard let session = session,
              session.isReachable else {
            print("Apple Watch ulaşılabilir değil")
            return
        }
        
        let healthData: [String: Any] = [
            "steps": steps,
            "calories": calories,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        session.sendMessage(healthData, replyHandler: { response in
            print("Watch'a veri gönderildi: \(response)")
            DispatchQueue.main.async {
                self.lastSyncDate = Date()
            }
        }) { error in
            print("Watch'a veri gönderilemedi: \(error.localizedDescription)")
        }
    }
    
    func sendWorkoutDataToWatch(workoutName: String, duration: TimeInterval, caloriesBurned: Double) {
        guard let session = session,
              session.isReachable else {
            print("Apple Watch ulaşılabilir değil")
            return
        }
        
        let workoutData: [String: Any] = [
            "type": "workout",
            "name": workoutName,
            "duration": duration,
            "caloriesBurned": caloriesBurned,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        session.sendMessage(workoutData, replyHandler: { response in
            print("Workout verisi Watch'a gönderildi: \(response)")
        }) { error in
            print("Workout verisi gönderilemedi: \(error.localizedDescription)")
        }
    }
    
    func requestWatchInfo() {
        guard let session = session,
              session.isReachable else {
            return
        }
        
        let request = ["action": "getWatchInfo"]
        
        session.sendMessage(request, replyHandler: { [weak self] response in
            DispatchQueue.main.async {
                self?.parseWatchInfo(from: response)
            }
        }) { error in
            print("Watch bilgisi alınamadı: \(error.localizedDescription)")
        }
    }
    
    private func parseWatchInfo(from response: [String: Any]) {
        let info = WatchInfo(
            name: response["name"] as? String ?? "Apple Watch",
            model: response["model"] as? String ?? "Bilinmiyor",
            systemVersion: response["systemVersion"] as? String ?? "Bilinmiyor",
            batteryLevel: response["batteryLevel"] as? Float ?? 0.0,
            isCharging: response["isCharging"] as? Bool ?? false
        )
        
        watchInfo = info
    }
    
    // MARK: - Context Updates
    func updateApplicationContext() {
        guard let session = session else { return }
        
        let context: [String: Any] = [
            "appVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
            "lastUpdate": Date().timeIntervalSince1970,
            "userPreferences": getUserPreferences()
        ]
        
        do {
            try session.updateApplicationContext(context)
            print("Application context güncellendi")
        } catch {
            print("Application context güncellenemedi: \(error.localizedDescription)")
        }
    }
    
    private func getUserPreferences() -> [String: Any] {
        return [
            "language": LocalizationService.shared.currentLanguage,
            "notifications": true
        ]
    }
}

// MARK: - WCSessionDelegate
extension WatchConnectivityService: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            switch activationState {
            case .activated:
                self.connectionStatus = .connected
                self.isWatchAppInstalled = session.isWatchAppInstalled
                self.isWatchReachable = session.isReachable
                
                if session.isWatchAppInstalled {
                    self.requestWatchInfo()
                    self.updateApplicationContext()
                }
                
            case .inactive:
                self.connectionStatus = .inactive
                
            case .notActivated:
                self.connectionStatus = .notActivated
                
            @unknown default:
                self.connectionStatus = .notAvailable
            }
            
            if let error = error {
                print("WCSession aktivasyon hatası: \(error.localizedDescription)")
            }
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        DispatchQueue.main.async {
            self.connectionStatus = .inactive
            self.isWatchReachable = false
        }
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        DispatchQueue.main.async {
            self.connectionStatus = .notActivated
            self.isWatchReachable = false
        }
        
        // Yeniden aktivasyon
        session.activate()
    }
    
    func sessionWatchStateDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isWatchAppInstalled = session.isWatchAppInstalled
            self.isWatchReachable = session.isReachable
            
            if session.isWatchAppInstalled && session.isReachable {
                self.connectionStatus = .connected
                self.requestWatchInfo()
            } else if session.isWatchAppInstalled {
                self.connectionStatus = .appInstalled
            } else {
                self.connectionStatus = .notInstalled
            }
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print("Watch'tan mesaj alındı: \(message)")
        
        // Watch'tan gelen verileri işle
        if let type = message["type"] as? String {
            switch type {
            case "heartRate":
                handleHeartRateData(message)
            case "workout":
                handleWorkoutData(message)
            case "health":
                handleHealthData(message)
            default:
                break
            }
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        print("Watch'tan yanıt gerektiren mesaj alındı: \(message)")
        
        // Yanıt gönder
        let reply: [String: Any] = ["status": "received", "timestamp": Date().timeIntervalSince1970]
        replyHandler(reply)
    }
    
    private func handleHeartRateData(_ data: [String: Any]) {
        // Kalp atış hızı verilerini işle
        if let heartRate = data["value"] as? Double {
            print("Kalp atış hızı: \(heartRate)")
            // HealthKit'e kaydet veya UI'ı güncelle
        }
    }
    
    private func handleWorkoutData(_ data: [String: Any]) {
        // Egzersiz verilerini işle
        print("Watch'tan egzersiz verisi alındı: \(data)")
    }
    
    private func handleHealthData(_ data: [String: Any]) {
        // Sağlık verilerini işle
        print("Watch'tan sağlık verisi alındı: \(data)")
    }
}

// MARK: - Data Models
struct WatchInfo {
    let name: String
    let model: String
    let systemVersion: String
    let batteryLevel: Float
    let isCharging: Bool
    
    var batteryPercentage: Int {
        return Int(batteryLevel * 100)
    }
    
    var batteryStatus: String {
        if isCharging {
            return "Şarj oluyor (\(batteryPercentage)%)"
        } else {
            return "\(batteryPercentage)%"
        }
    }
}

enum WatchConnectionStatus {
    case notSupported
    case notAvailable
    case notActivated
    case inactive
    case notInstalled
    case appInstalled
    case connected
    
    var description: String {
        switch self {
        case .notSupported:
            return "Apple Watch desteklenmiyor"
        case .notAvailable:
            return "Apple Watch bulunamadı"
        case .notActivated:
            return "Bağlantı etkinleştirilmedi"
        case .inactive:
            return "Bağlantı pasif"
        case .notInstalled:
            return "Watch uygulaması yüklü değil"
        case .appInstalled:
            return "Watch uygulaması yüklü"
        case .connected:
            return "Bağlı"
        }
    }
    
    var isConnected: Bool {
        return self == .connected
    }
} 