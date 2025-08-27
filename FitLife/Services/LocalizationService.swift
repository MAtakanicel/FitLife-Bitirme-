import Foundation
import SwiftUI

class LocalizationService: ObservableObject {
    static let shared = LocalizationService()
    
    @Published var currentLanguage: String = "tr" {
        didSet {
            dataStorage.setAppLanguage(currentLanguage)
            // Bundle'ı güncelle
            updateBundle()
        }
    }
    
    private var bundle: Bundle = Bundle.main
    private let dataStorage = DataStorageService.shared
    
    private init() {
        // Kaydedilmiş dili yükle
        if let savedLanguage = dataStorage.getAppLanguage() {
            currentLanguage = savedLanguage
        } else {
            // Sistem dilini kontrol et
            let systemLanguage = Locale.current.language.languageCode?.identifier ?? "tr"
            currentLanguage = ["en", "tr"].contains(systemLanguage) ? systemLanguage : "tr"
        }
        updateBundle()
    }
    
    private func updateBundle() {
        guard let path = Bundle.main.path(forResource: currentLanguage, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            self.bundle = Bundle.main
            return
        }
        self.bundle = bundle
    }
    
    func localizedString(for key: String, defaultValue: String? = nil) -> String {
        let value = bundle.localizedString(forKey: key, value: defaultValue, table: nil)
        return value == key && defaultValue != nil ? defaultValue! : value
    }
    
    func changeLanguage(to language: String) {
        currentLanguage = language
    }
    
    var isEnglish: Bool {
        return currentLanguage == "en"
    }
    
    var isTurkish: Bool {
        return currentLanguage == "tr"
    }
}

// MARK: - String Extension for Localization
extension String {
    var localized: String {
        return LocalizationService.shared.localizedString(for: self, defaultValue: self)
    }
    
    func localized(with arguments: CVarArg...) -> String {
        return String(format: self.localized, arguments: arguments)
    }
} 