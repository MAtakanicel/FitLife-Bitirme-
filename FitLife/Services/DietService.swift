import Foundation

// MARK: - Diet JSON Models
struct DietDataResponse: Codable {
    let name: String?
    let description: String?
    let diet: [DietDay]
}

struct DietDay: Codable {
    let day: String
    let meals: [DietMeal]
}

struct DietMeal: Codable, Identifiable {
    let id = UUID()
    let type: String
    let calories: Double
    let fatG: Double
    let proteinG: Double
    let carbsG: Double
    let items: [String]
    
    enum CodingKeys: String, CodingKey {
        case type, calories
        case fatG = "fat_g"
        case proteinG = "protein_g"
        case carbsG = "carbs_g"
        case items
    }
}

// MARK: - Diet Service
class DietService: ObservableObject {
    static let shared = DietService()
    
    private init() {}
    
    // Keto diyeti JSON'ından ilk günü yükle
    func loadKetoDayOne() -> [DietMeal] {
        guard let url = Bundle.main.url(forResource: "Keto", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let dietData = try? JSONDecoder().decode(DietDataResponse.self, from: data) else {
            print("Keto.json dosyası yüklenemedi")
            return []
        }
        
        // İlk günü bul (Gün 1)
        if let firstDay = dietData.diet.first(where: { $0.day == "Gün 1" }) {
            return firstDay.meals
        }
        
        return []
    }
    
    // Akdeniz diyeti JSON'ından ilk günü yükle
    func loadMediterraneanDayOne() -> [DietMeal] {
        guard let url = Bundle.main.url(forResource: "Akdeniz", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let dietData = try? JSONDecoder().decode(DietDataResponse.self, from: data) else {
            print("Akdeniz.json dosyası yüklenemedi")
            return []
        }
        
        // İlk günü bul (Gün 1)
        if let firstDay = dietData.diet.first(where: { $0.day == "Gün 1" }) {
            return firstDay.meals
        }
        
        return []
    }
    
    // Herhangi bir diyet JSON'ını yükle
    func loadDietData(fileName: String) -> DietDataResponse? {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let dietData = try? JSONDecoder().decode(DietDataResponse.self, from: data) else {
            print("\(fileName).json dosyası yüklenemedi")
            return nil
        }
        
        return dietData
    }
    
    // Belirli bir günün öğünlerini getir
    func getMealsForDay(fileName: String, dayNumber: Int) -> [DietMeal] {
        guard let dietData = loadDietData(fileName: fileName) else { return [] }
        
        // Mevcut günleri sırala ve dayNumber'a göre seç
        let sortedDays = dietData.diet.sorted { day1, day2 in
            let num1 = extractDayNumber(from: day1.day)
            let num2 = extractDayNumber(from: day2.day)
            return num1 < num2
        }
        
        // dayNumber'a karşılık gelen günü bul (1-based index)
        if dayNumber > 0 && dayNumber <= sortedDays.count {
            return sortedDays[dayNumber - 1].meals
        }
        
        return []
    }
    
    // Gün string'inden sayı çıkar (örn: "Gün 1" -> 1, "Gün 10" -> 10)
    private func extractDayNumber(from dayString: String) -> Int {
        let components = dayString.components(separatedBy: " ")
        if components.count >= 2, let number = Int(components[1]) {
            return number
        }
        return 0
    }
    
    // Maksimum gün sayısını getir
    func getMaxDayCount(fileName: String) -> Int {
        guard let dietData = loadDietData(fileName: fileName) else { return 0 }
        return dietData.diet.count
    }
    
    // Mevcut tüm günleri getir
    func getAllDays(fileName: String) -> [DietDay] {
        guard let dietData = loadDietData(fileName: fileName) else { return [] }
        
        // Günleri sırala
        return dietData.diet.sorted { day1, day2 in
            let num1 = extractDayNumber(from: day1.day)
            let num2 = extractDayNumber(from: day2.day)
            return num1 < num2
        }
    }
    
    // Diyet açıklamasını getir
    func getDietDescription(fileName: String) -> String {
        guard let dietData = loadDietData(fileName: fileName) else { 
            return "Açıklama bulunamadı"
        }
        
        return dietData.description ?? "Bu diyet hakkında açıklama bulunmamaktadır."
    }
    
    // Diyet adını getir
    func getDietName(fileName: String) -> String {
        guard let dietData = loadDietData(fileName: fileName) else { 
            return fileName
        }
        
        return dietData.name ?? fileName
    }
} 
