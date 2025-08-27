import SwiftUI

struct HealthDataView: View {
    @ObservedObject private var healthKitService = HealthKitService.shared
    @State private var weeklySteps: [DailyHealthData] = []
    @State private var weeklyCalories: [DailyHealthData] = []
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Authorization Status
                    if !healthKitService.isAuthorized {
                        authorizationSection
                    }
                    
                    // Today's Data
                    if healthKitService.isAuthorized {
                        todaysDataSection
                        
                        // Weekly Charts
                        weeklyChartsSection
                    }
                    
                    // Error Display
                    if let error = healthKitService.authorizationError {
                        errorSection(error)
                    }
                }
                .padding()
            }
            .navigationTitle("Sağlık Verileri")
            .onAppear {
                if !healthKitService.isAuthorized {
                    Task {
                        await healthKitService.requestAuthorization()
                    }
                }
                healthKitService.startObservingHealthData()
            }
            .onDisappear {
                healthKitService.stopObservingHealthData()
            }
            .task {
                if healthKitService.isAuthorized {
                    await loadWeeklyData()
                }
            }
        }
    }
    
    // MARK: - Authorization Section
    private var authorizationSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.fill")
                .font(.system(size: 50))
                .foregroundColor(.red)
            
            Text("HealthKit İzni Gerekli")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Apple Watch'tan adım ve kalori verilerini almak için HealthKit izni vermeniz gerekiyor.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button("İzin Ver") {
                Task {
                    await healthKitService.requestAuthorization()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Today's Data Section
    private var todaysDataSection: some View {
        VStack(spacing: 16) {
            Text("Bugünkü Veriler")
                .font(.title2)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 16) {
                // Steps Card
                VStack(spacing: 8) {
                    Image(systemName: "figure.walk")
                        .font(.system(size: 30))
                        .foregroundColor(.blue)
                    
                    Text("\(healthKitService.dailySteps)")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Adım")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Calories Card
                VStack(spacing: 8) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.orange)
                    
                    Text("\(Int(healthKitService.dailyCalories))")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Kalori")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Weekly Charts Section
    private var weeklyChartsSection: some View {
        VStack(spacing: 20) {
            // Weekly Steps Chart
            VStack(alignment: .leading, spacing: 12) {
                Text("Haftalık Adımlar")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                if !weeklySteps.isEmpty {
                    SimpleBarChart(data: weeklySteps, color: .blue, maxValue: weeklySteps.map { $0.value }.max() ?? 1)
                        .frame(height: 150)
                } else {
                    ProgressView("Veriler yükleniyor...")
                        .frame(height: 150)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            // Weekly Calories Chart
            VStack(alignment: .leading, spacing: 12) {
                Text("Haftalık Kaloriler")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                if !weeklyCalories.isEmpty {
                    SimpleBarChart(data: weeklyCalories, color: .orange, maxValue: weeklyCalories.map { $0.value }.max() ?? 1)
                        .frame(height: 150)
                } else {
                    ProgressView("Veriler yükleniyor...")
                        .frame(height: 150)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Error Section
    private func errorSection(_ error: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 30))
                .foregroundColor(.red)
            
            Text("Hata")
                .font(.headline)
                .fontWeight(.bold)
            
            Text(error)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Helper Functions
    private func loadWeeklyData() async {
        async let steps = healthKitService.fetchWeeklySteps()
        async let calories = healthKitService.fetchWeeklyCalories()
        
        weeklySteps = await steps
        weeklyCalories = await calories
    }
}

// MARK: - Simple Bar Chart
struct SimpleBarChart: View {
    let data: [DailyHealthData]
    let color: Color
    let maxValue: Double
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter
    }()
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(data) { item in
                VStack(spacing: 4) {
                    Rectangle()
                        .fill(color)
                        .frame(height: CGFloat(item.value / maxValue) * 120)
                        .cornerRadius(4)
                    
                    Text(dateFormatter.string(from: item.date))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    HealthDataView()
} 