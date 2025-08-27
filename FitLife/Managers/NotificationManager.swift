import Foundation
import UserNotifications
import UIKit

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var isNotificationEnabled = false
    
    private init() {
        checkNotificationStatus()
    }
    
    // Mevcut bildirim durumunu kontrol et
    func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isNotificationEnabled = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // Bildirim izni iste
    func requestNotificationPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                self.isNotificationEnabled = granted
                completion(granted)
            }
        }
    }
    
    // Bildirimleri kapat
    func disableNotifications() {
        isNotificationEnabled = false
        // Mevcut bildirimleri temizle
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
    
    // Ayarlar sayfasına yönlendir
    func openSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    // Test bildirimi gönder
    func scheduleTestNotification() {
        guard isNotificationEnabled else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "FitLife"
        content.body = "Günlük hedeflerinizi kontrol etmeyi unutmayın!"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: "test_notification", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
} 