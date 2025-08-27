import Foundation

// MARK: - Weight Models

struct WeightData: Identifiable, Codable {
    let id: String
    let weight: Double
    let date: Date
    
    init(id: String = UUID().uuidString, weight: Double, date: Date) {
        self.id = id
        self.weight = weight
        self.date = date
    }
}

// MARK: - Summary Models

struct DailySummary {
    let date: Date
    let totalCaloriesConsumed: Double
    
    var netCalories: Double {
        return totalCaloriesConsumed
    }
} 