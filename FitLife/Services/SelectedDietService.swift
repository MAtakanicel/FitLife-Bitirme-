import Foundation
import SwiftUI

// MARK: - Selected Diet Service
class SelectedDietService: ObservableObject {
    static let shared = SelectedDietService()
    
    @Published var selectedDiet: DietPlan?
    @Published var currentDay: Int = 1
    @Published var todaysMeals: [DietMeal] = []
    @Published var completedMeals: Set<String> = []
    
    private let dataStorage = DataStorageService.shared
    
    private init() {
        loadSelectedDiet()
        loadCurrentDay()
        loadCompletedMeals()
        checkDayReset()
        
        // AuthenticationManager'ın kullanıcı değişikliklerini dinle
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(userChanged),
            name: Notification.Name("UserAuthStateChanged"),
            object: nil
        )
    }
    
    @objc private func userChanged() {
        loadSelectedDiet()
        loadCurrentDay()
        loadCompletedMeals()
        checkDayReset()
    }
    
    // MARK: - Public Methods
    
    func selectDiet(_ diet: DietPlan) {
        selectedDiet = diet
        currentDay = 1
        
        // Diyet başlangıç tarihini kaydet
        dataStorage.setDietStartDate(Date())
        
        saveSelectedDiet()
        saveCurrentDay()
        loadTodaysMeals()
        clearCompletedMeals()
    }
    
    func markMealAsCompleted(_ meal: DietMeal) {
        let mealId = "\(meal.type)_\(currentDay)"
        completedMeals.insert(mealId)
        saveCompletedMeals()
    }
    
    func isMealCompleted(_ meal: DietMeal) -> Bool {
        let mealId = "\(meal.type)_\(currentDay)"
        return completedMeals.contains(mealId)
    }
    
    func nextDay() {
        guard let diet = selectedDiet else { return }
        let maxDays = getDietDuration(diet.fileName)
        
        if currentDay < maxDays {
            currentDay += 1
            saveCurrentDay()
            loadTodaysMeals()
            clearCompletedMeals()
        }
    }
    
    func previousDay() {
        if currentDay > 1 {
            currentDay -= 1
            saveCurrentDay()
            loadTodaysMeals()
            clearCompletedMeals()
        }
    }
    
    func getTotalCaloriesForToday() -> Double {
        return todaysMeals.reduce(0) { total, meal in
            total + meal.calories
        }
    }
    
    func getCompletedCaloriesForToday() -> Double {
        return todaysMeals.reduce(0) { total, meal in
            if isMealCompleted(meal) {
                return total + meal.calories
            }
            return total
        }
    }
    
    func getDietDuration(_ fileName: String) -> Int {
        return DietService.shared.getMaxDayCount(fileName: fileName)
    }
    
    // Diyet başlangıcından bu yana kaç gün geçtiğini hesapla
    func getCurrentDietDay() -> Int {
        guard let diet = selectedDiet,
              let startDate = dataStorage.getDietStartDate() else {
            return 0
        }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dietStartDay = calendar.startOfDay(for: startDate)
        
        let daysDifference = calendar.dateComponents([.day], from: dietStartDay, to: today).day ?? 0
        let currentDietDay = daysDifference + 1
        
        let maxDays = getDietDuration(diet.fileName)
        
        // Diyet süresi aşıldıysa diyeti sıfırla
        if currentDietDay > maxDays {
            resetDiet()
            return 0
        }
        
        return currentDietDay
    }
    
    // Diyet sıfırlama fonksiyonu
    func resetDiet() {
        selectedDiet = nil
        currentDay = 1
        todaysMeals = []
        completedMeals = []
        
        // DataStorage'dan temizle
        dataStorage.clearDietData()
        
        print("🔄 Diyet süresi tamamlandı, diyet sıfırlandı")
    }
    
    // Diyet durumu string'i
    func getDietStatusText() -> String {
        guard let diet = selectedDiet else {
            return "Diyet Seçiniz"
        }
        
        let currentDietDay = getCurrentDietDay()
        if currentDietDay == 0 {
            return "Diyet Seçiniz"
        }
        
        let maxDays = getDietDuration(diet.fileName)
        return "\(diet.name) - \(currentDietDay). Gün / \(maxDays) Gün"
    }
    
    // MARK: - Private Methods
    
    private func loadSelectedDiet() {
        if let diet = dataStorage.loadSelectedDiet(DietPlan.self) {
            selectedDiet = diet
            loadTodaysMeals()
        } else {
            selectedDiet = nil
            todaysMeals = []
        }
    }
    
    private func saveSelectedDiet() {
        if let diet = selectedDiet {
            dataStorage.saveSelectedDiet(diet)
        }
    }
    
    private func loadCurrentDay() {
        currentDay = dataStorage.getCurrentDietDay()
        if currentDay == 0 { currentDay = 1 } // Default value
    }
    
    private func saveCurrentDay() {
        dataStorage.setCurrentDietDay(currentDay)
    }
    
    private func loadCompletedMeals() {
        completedMeals = dataStorage.loadCompletedMeals(Set<String>.self) ?? []
    }
    
    private func saveCompletedMeals() {
        dataStorage.saveCompletedMeals(completedMeals)
    }
    
    private func clearCompletedMeals() {
        completedMeals.removeAll()
        saveCompletedMeals()
    }
    
    private func checkDayReset() {
        let today = Calendar.current.startOfDay(for: Date())
        
        if let lastDate = dataStorage.getLastDietDate(),
           !Calendar.current.isDate(lastDate, inSameDayAs: today) {
            // Yeni gün başladı, tamamlanan öğünleri temizle
            clearCompletedMeals()
        }
    }
    
    private func loadTodaysMeals() {
        guard let diet = selectedDiet else {
            todaysMeals = []
            return
        }
        
        todaysMeals = DietService.shared.getMealsForDay(fileName: diet.fileName, dayNumber: currentDay)
    }
    
    // MARK: - Deinit
    deinit {
        NotificationCenter.default.removeObserver(self)
        debugLog("🗑️ SelectedDietService deinit - observer temizlendi")
    }
} 