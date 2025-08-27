import Foundation
import SwiftUI

// MARK: - Exercise Session Model
struct ExerciseSession: Identifiable, Codable {
    let id: String
    let exerciseName: String
    let programTitle: String
    let caloriesBurned: Double
    let duration: Int // seconds
    let dateCompleted: Date
    
    init(id: String = UUID().uuidString, exerciseName: String, programTitle: String, caloriesBurned: Double, duration: Int, dateCompleted: Date) {
        self.id = id
        self.exerciseName = exerciseName
        self.programTitle = programTitle
        self.caloriesBurned = caloriesBurned
        self.duration = duration
        self.dateCompleted = dateCompleted
    }
}

// MARK: - Exercise Tracking Service
class ExerciseTrackingService: ObservableObject {
    static let shared = ExerciseTrackingService()
    
    @Published var todaysExerciseSessions: [ExerciseSession] = []
    @Published var totalCaloriesBurnedToday: Double = 0.0
    
    private let dataStorage = DataStorageService.shared
    
    private init() {
        loadTodaysExercises()
        calculateTodaysCalories()
        
        // AuthenticationManager'ın kullanıcı değişikliklerini dinle
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(userChanged),
            name: Notification.Name("UserAuthStateChanged"),
            object: nil
        )
    }
    
    @objc private func userChanged() {
        loadTodaysExercises()
        calculateTodaysCalories()
    }
    
    // MARK: - Public Methods
    
    func addExerciseSession(_ session: ExerciseSession) {
        todaysExerciseSessions.append(session)
        saveTodaysExercises()
        calculateTodaysCalories()
    }
    
    func addExerciseSession(exerciseName: String, programTitle: String, caloriesBurned: Double, duration: Int) {
        let session = ExerciseSession(
            exerciseName: exerciseName,
            programTitle: programTitle,
            caloriesBurned: caloriesBurned,
            duration: duration,
            dateCompleted: Date()
        )
        addExerciseSession(session)
    }
    
    func clearTodaysExercises() {
        todaysExerciseSessions.removeAll()
        saveTodaysExercises()
        calculateTodaysCalories()
    }
    
    // MARK: - Private Methods
    
    private func loadTodaysExercises() {
        let today = Calendar.current.startOfDay(for: Date())
        
        // Eğer bugün değilse, eski verileri temizle
        if let lastSavedDate = dataStorage.getLastExerciseDate(),
           !Calendar.current.isDate(lastSavedDate, inSameDayAs: today) {
            // Yeni gün başladı, eski verileri temizle
            todaysExerciseSessions = []
            saveTodaysExercises()
            dataStorage.setLastExerciseDate(today)
            return
        }
        
        // Bugünün verilerini yükle
        todaysExerciseSessions = dataStorage.loadTodaysExercise([ExerciseSession].self) ?? []
        dataStorage.setLastExerciseDate(today)
    }
    
    private func saveTodaysExercises() {
        dataStorage.saveTodaysExercise(todaysExerciseSessions)
    }
    
    private func calculateTodaysCalories() {
        totalCaloriesBurnedToday = todaysExerciseSessions.reduce(0) { total, session in
            total + session.caloriesBurned
        }
    }
    
    // MARK: - Helper Methods
    
    func getTodaysSessions() -> [ExerciseSession] {
        return todaysExerciseSessions
    }
    
    func getTotalDuration() -> Int {
        return todaysExerciseSessions.reduce(0) { total, session in
            total + session.duration
        }
    }
    
    // MARK: - Deinit
    deinit {
        NotificationCenter.default.removeObserver(self)
        debugLog("🗑️ ExerciseTrackingService deinit - observer temizlendi")
    }
} 