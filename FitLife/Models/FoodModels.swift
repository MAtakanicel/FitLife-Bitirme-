import Foundation

// MARK: - Food Models

struct Food: Identifiable, Codable {
    let id: String
    let foodId: String?
    let foodName: String?
    let foodType: String?
    let foodUrl: String?
    let brandName: String?
    let foodDescription: String?
    
    // Computed properties for nutrition info
    var calories: Int? {
        guard let description = foodDescription else { return nil }
        let regex = try? NSRegularExpression(pattern: "Calories: (\\d+)", options: [])
        let range = NSRange(location: 0, length: description.utf16.count)
        
        if let match = regex?.firstMatch(in: description, options: [], range: range),
           let valueRange = Range(match.range(at: 1), in: description) {
            return Int(String(description[valueRange]))
        }
        return nil
    }
    
    var macros: MacroNutrients? {
        guard let description = foodDescription else { return nil }
        
        let carbs = extractNutrientValue(from: description, pattern: "Carbs: ([\\d.]+)g")
        let protein = extractNutrientValue(from: description, pattern: "Protein: ([\\d.]+)g")
        let fat = extractNutrientValue(from: description, pattern: "Fat: ([\\d.]+)g")
        
        return MacroNutrients(carbs: carbs, protein: protein, fat: fat)
    }
    
    // Additional computed properties for Nutritionix compatibility
    var totalCalories: Int? {
        return calories
    }
    
    var totalProtein: Double? {
        return macros?.protein ?? extractNutrientValue(from: foodDescription ?? "", pattern: "Protein: ([\\d.]+)g")
    }
    
    var totalCarbs: Double? {
        return macros?.carbs ?? extractNutrientValue(from: foodDescription ?? "", pattern: "Carbs: ([\\d.]+)g")
    }
    
    var totalFat: Double? {
        return macros?.fat ?? extractNutrientValue(from: foodDescription ?? "", pattern: "Fat: ([\\d.]+)g")
    }
    
    private func extractNutrientValue(from text: String, pattern: String) -> Double? {
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: text.utf16.count)
        
        if let match = regex?.firstMatch(in: text, options: [], range: range),
           let valueRange = Range(match.range(at: 1), in: text) {
            return Double(String(text[valueRange]))
        }
        return nil
    }
    
    init(foodId: String? = nil, foodName: String? = nil, foodType: String? = nil, foodUrl: String? = nil, brandName: String? = nil, foodDescription: String? = nil) {
        self.id = foodId ?? UUID().uuidString
        self.foodId = foodId
        self.foodName = foodName
        self.foodType = foodType
        self.foodUrl = foodUrl
        self.brandName = brandName
        self.foodDescription = foodDescription
    }
}

struct MacroNutrients: Codable {
    let carbs: Double?
    let protein: Double?
    let fat: Double?
}

struct Serving: Codable {
    let servingId: String?
    let servingDescription: String?
    let servingUrl: String?
    let metricServingAmount: String?
    let metricServingUnit: String?
    let numberOfUnits: String?
    let measurementDescription: String?
    let calories: String?
    let carbohydrate: String?
    let protein: String?
    let fat: String?
    let saturatedFat: String?
    let polyunsaturatedFat: String?
    let monounsaturatedFat: String?
    let transFat: String?
    let cholesterol: String?
    let sodium: String?
    let potassium: String?
    let fiber: String?
    let sugar: String?
    let vitaminA: String?
    let vitaminC: String?
    let calcium: String?
    let iron: String?
}

struct Servings: Codable {
    let serving: [Serving]?
}

struct FoodDetail: Codable {
    let foodId: String?
    let foodName: String?
    let foodType: String?
    let foodUrl: String?
    let servings: Servings?
} 