import Foundation

// MARK: - Meal Models

struct MealData: Identifiable, Codable {
    let id: String
    let foodId: String?
    let foodName: String
    let servingDescription: String?
    let quantity: Double
    let calories: Double
    let carbs: Double
    let protein: Double
    let fat: Double
    let mealType: MealType
    let dateAdded: Date
    
    init(id: String = UUID().uuidString, foodId: String? = nil, foodName: String, servingDescription: String? = nil, quantity: Double, calories: Double, carbs: Double, protein: Double, fat: Double, mealType: MealType, dateAdded: Date) {
        self.id = id
        self.foodId = foodId
        self.foodName = foodName
        self.servingDescription = servingDescription
        self.quantity = quantity
        self.calories = calories
        self.carbs = carbs
        self.protein = protein
        self.fat = fat
        self.mealType = mealType
        self.dateAdded = dateAdded
    }
    
    enum MealType: String, CaseIterable, Codable {
        case breakfast = "Kahvaltı"
        case lunch = "Öğle Yemeği"
        case dinner = "Akşam Yemeği"
        case snack = "Atıştırmalık"
    }
}

// MARK: - Meal Service
class MealService: ObservableObject {
    static let shared = MealService()
    
    @Published var meals: [MealData] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let coreDataService = CoreDataService.shared
    
    private init() {
        loadMeals()
    }
    
    var todaysMeals: [MealData] {
        return getMeals(for: Date())
    }
    
    func addMeal(_ meal: MealData) {
        meals.append(meal)
        // CoreData'ya kaydet
        saveMealToCoreData(meal)
    }
    
    func deleteMeal(withId id: String) {
        meals.removeAll { $0.id == id }
        // CoreData'dan da sil
        if let uuid = UUID(uuidString: id) {
            coreDataService.deleteMeal(id: uuid)
        }
    }
    
    func removeMeal(_ meal: MealData) {
        meals.removeAll { $0.id == meal.id }
        // CoreData'dan da sil
        if let uuid = UUID(uuidString: meal.id) {
            coreDataService.deleteMeal(id: uuid)
        }
    }
    
    func addManualMeal(foodName: String, calories: Double, protein: Double, carbs: Double, fat: Double, mealType: MealData.MealType) {
        let meal = MealData(
            foodName: foodName,
            quantity: 1.0,
            calories: calories,
            carbs: carbs,
            protein: protein,
            fat: fat,
            mealType: mealType,
            dateAdded: Date()
        )
        addMeal(meal)
    }
    
    var totalCalories: Double {
        let today = Date()
        return getTotalCalories(for: today)
    }
    
    var totalCarbs: Double {
        let today = Date()
        return getTotalCarbs(for: today)
    }
    
    var totalProtein: Double {
        let today = Date()
        return getTotalProtein(for: today)
    }
    
    var totalFat: Double {
        let today = Date()
        return getTotalFat(for: today)
    }
    
    func getMeals(for date: Date, mealType: MealData.MealType? = nil) -> [MealData] {
        let calendar = Calendar.current
        return meals.filter { meal in
            let sameDay = calendar.isDate(meal.dateAdded, inSameDayAs: date)
            if let mealType = mealType {
                return sameDay && meal.mealType == mealType
            }
            return sameDay
        }
    }
    
    func getTotalCalories(for date: Date) -> Double {
        return getMeals(for: date).reduce(0) { $0 + $1.calories }
    }
    
    func getTotalCarbs(for date: Date) -> Double {
        return getMeals(for: date).reduce(0) { $0 + $1.carbs }
    }
    
    func getTotalProtein(for date: Date) -> Double {
        return getMeals(for: date).reduce(0) { $0 + $1.protein }
    }
    
    func getTotalFat(for date: Date) -> Double {
        return getMeals(for: date).reduce(0) { $0 + $1.fat }
    }
    
    func getTotalMacros(for date: Date) -> (carbs: Double, protein: Double, fat: Double) {
        let dayMeals = getMeals(for: date)
        let totalCarbs = dayMeals.reduce(0) { $0 + $1.carbs }
        let totalProtein = dayMeals.reduce(0) { $0 + $1.protein }
        let totalFat = dayMeals.reduce(0) { $0 + $1.fat }
        return (carbs: totalCarbs, protein: totalProtein, fat: totalFat)
    }
    
    private func loadMeals() {
        // CoreData'dan meal'ları yükle
        guard let currentUser = getCurrentUserId() else {
            meals = []
            return
        }
        
        let coreDataMeals = coreDataService.fetchMeals(for: currentUser)
        meals = coreDataMeals.map { mealEntry in
            MealData(
                id: mealEntry.id?.uuidString ?? UUID().uuidString,
                foodId: nil,
                foodName: mealEntry.foodName ?? "",
                servingDescription: nil,
                quantity: mealEntry.quantity,
                calories: mealEntry.calories,
                carbs: mealEntry.carbs,
                protein: mealEntry.protein,
                fat: mealEntry.fat,
                mealType: MealData.MealType(rawValue: mealEntry.mealType ?? "Kahvaltı") ?? .breakfast,
                dateAdded: mealEntry.dateAdded ?? Date()
            )
        }
    }
    
    private func saveMealToCoreData(_ meal: MealData) {
        guard let currentUser = getCurrentUserId() else {
            print("❌ MealService: Current user UID not found")
            print("🔍 Auth Status: \(AuthenticationManager.shared.isAuthenticated)")
            print("🔍 Current Email: \(AuthenticationManager.shared.currentUserEmail)")
            return
        }
        
        print("✅ MealService: Saving meal for user UID: \(currentUser)")
        
        let _ = coreDataService.saveMeal(
            userUID: currentUser,
            foodName: meal.foodName,
            calories: meal.calories,
            protein: meal.protein,
            carbs: meal.carbs,
            fat: meal.fat,
            mealType: meal.mealType.rawValue,
            quantity: meal.quantity,
            date: meal.dateAdded
        )
        
        print("✅ MealService: Meal saved successfully")
    }
    
    private func getCurrentUserId() -> String? {
        return AuthenticationManager.shared.isAuthenticated ? 
               AuthenticationManager.shared.currentUserUID : nil
    }
} 