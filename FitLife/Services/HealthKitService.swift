import Foundation
import HealthKit
import Combine

class HealthKitService: ObservableObject {
    static let shared = HealthKitService()
    
    private let healthStore = HKHealthStore()
    
    @Published var dailySteps: Int = 0
    @Published var dailyCalories: Double = 0.0
    @Published var isAuthorized: Bool = false
    @Published var authorizationError: String?
    
    // HealthKit veri türleri
    private let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
    private let activeEnergyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
    
    private init() {
        checkHealthKitAvailability()
    }
    
    // MARK: - HealthKit Kullanabilirlik
    private func checkHealthKitAvailability() {
        guard HKHealthStore.isHealthDataAvailable() else {
            authorizationError = "HealthKit bu cihazda kullanılamıyor"
            return
        }
    }
    
    // MARK: - Authorization
    func requestAuthorization() async {
        let typesToRead: Set<HKObjectType> = [
            stepCountType,
            activeEnergyType
        ]
        
        do {
            try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
            
            await MainActor.run {
                self.isAuthorized = true
                self.authorizationError = nil
            }
            
            // İzin alındıktan sonra verileri çek
            await fetchTodaysData()
            
        } catch {
            await MainActor.run {
                self.authorizationError = "HealthKit izni alınamadı: \(error.localizedDescription)"
                self.isAuthorized = false
            }
        }
    }
    
    // MARK: - Data Fetching
    func fetchTodaysData() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await self.fetchStepCount()
            }
            group.addTask {
                await self.fetchActiveCalories()
            }
        }
    }
    
    private func fetchStepCount() async {
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: endOfDay,
            options: .strictStartDate
        )
        
        let query = HKStatisticsQuery(
            quantityType: stepCountType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { [weak self] _, result, error in
            
            guard let self = self else { return }
            
            if let error = error {
                DispatchQueue.main.async {
                    self.authorizationError = "Adım verisi alınamadı: \(error.localizedDescription)"
                }
                return
            }
            
            let steps = result?.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
            
            DispatchQueue.main.async {
                self.dailySteps = Int(steps)
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchActiveCalories() async {
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: endOfDay,
            options: .strictStartDate
        )
        
        let query = HKStatisticsQuery(
            quantityType: activeEnergyType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { [weak self] _, result, error in
            
            guard let self = self else { return }
            
            if let error = error {
                DispatchQueue.main.async {
                    self.authorizationError = "Kalori verisi alınamadı: \(error.localizedDescription)"
                }
                return
            }
            
            let calories = result?.sumQuantity()?.doubleValue(for: HKUnit.kilocalorie()) ?? 0
            
            DispatchQueue.main.async {
                self.dailyCalories = calories
            }
        }
        
        healthStore.execute(query)
    }
    
    // MARK: - Weekly Data
    func fetchWeeklySteps() async -> [DailyHealthData] {
        let calendar = Calendar.current
        let now = Date()
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek)!
        
        return await fetchStepsForDateRange(start: startOfWeek, end: endOfWeek)
    }
    
    func fetchWeeklyCalories() async -> [DailyHealthData] {
        let calendar = Calendar.current
        let now = Date()
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek)!
        
        return await fetchCaloriesForDateRange(start: startOfWeek, end: endOfWeek)
    }
    
    private func fetchStepsForDateRange(start: Date, end: Date) async -> [DailyHealthData] {
        return await withCheckedContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
            
            let query = HKStatisticsCollectionQuery(
                quantityType: stepCountType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum,
                anchorDate: start,
                intervalComponents: DateComponents(day: 1)
            )
            
            query.initialResultsHandler = { _, results, error in
                guard let results = results else {
                    continuation.resume(returning: [])
                    return
                }
                
                var dailyData: [DailyHealthData] = []
                
                results.enumerateStatistics(from: start, to: end) { statistics, _ in
                    let steps = statistics.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
                    let data = DailyHealthData(
                        date: statistics.startDate,
                        value: steps,
                        type: .steps
                    )
                    dailyData.append(data)
                }
                
                continuation.resume(returning: dailyData)
            }
            
            healthStore.execute(query)
        }
    }
    
    private func fetchCaloriesForDateRange(start: Date, end: Date) async -> [DailyHealthData] {
        return await withCheckedContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
            
            let query = HKStatisticsCollectionQuery(
                quantityType: activeEnergyType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum,
                anchorDate: start,
                intervalComponents: DateComponents(day: 1)
            )
            
            query.initialResultsHandler = { _, results, error in
                guard let results = results else {
                    continuation.resume(returning: [])
                    return
                }
                
                var dailyData: [DailyHealthData] = []
                
                results.enumerateStatistics(from: start, to: end) { statistics, _ in
                    let calories = statistics.sumQuantity()?.doubleValue(for: HKUnit.kilocalorie()) ?? 0
                    let data = DailyHealthData(
                        date: statistics.startDate,
                        value: calories,
                        type: .calories
                    )
                    dailyData.append(data)
                }
                
                continuation.resume(returning: dailyData)
            }
            
            healthStore.execute(query)
        }
    }
    
    // MARK: - Real-time Updates
    func startObservingHealthData() {
        startObservingSteps()
        startObservingCalories()
    }
    
    private func startObservingSteps() {
        let query = HKObserverQuery(sampleType: stepCountType, predicate: nil) { [weak self] _, _, error in
            if error == nil {
                Task {
                    await self?.fetchStepCount()
                }
            }
        }
        
        healthStore.execute(query)
        healthStore.enableBackgroundDelivery(for: stepCountType, frequency: .immediate) { _, _ in }
    }
    
    private func startObservingCalories() {
        let query = HKObserverQuery(sampleType: activeEnergyType, predicate: nil) { [weak self] _, _, error in
            if error == nil {
                Task {
                    await self?.fetchActiveCalories()
                }
            }
        }
        
        healthStore.execute(query)
        healthStore.enableBackgroundDelivery(for: activeEnergyType, frequency: .immediate) { _, _ in }
    }
    
    func stopObservingHealthData() {
        healthStore.disableAllBackgroundDelivery { _, _ in }
    }
}

// MARK: - Data Models
struct DailyHealthData: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
    let type: HealthDataType
}

enum HealthDataType {
    case steps
    case calories
} 
