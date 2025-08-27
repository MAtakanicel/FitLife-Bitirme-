import SwiftUI

struct HomeView: View {
    @Binding var selectedTab: Int
    @ObservedObject private var authManager = AuthenticationManager.shared
    @ObservedObject private var mealService = MealService.shared
    @ObservedObject private var healthKitService = HealthKitService.shared
    @ObservedObject private var exerciseTrackingService = ExerciseTrackingService.shared
    @ObservedObject private var selectedDietService = SelectedDietService.shared
    @State private var userName = "Kullanıcı"
    @State private var selectedDiet = "Diyet Seçiniz"
    @State private var targetCalories = 2000.0
    @State private var targetCarbs = 250.0
    @State private var targetProtein = 150.0
    @State private var targetFat = 67.0
    @State private var showDietSelection = false
    @State private var showMealManagement = false
    @State private var showDietDay = false
    @State private var showNoDietAlert = false
    
    // Günlük durum enum'u
    enum DayStatus {
        case completed  // Yeşil - öğün girişi yapılmış
        case today      // Sarı - bugün
        case upcoming   // Soluk - gelecek günler
        case missed     // Soluk - giriş yapılmamış geçmiş günler
    }
    
    // Gerçek beslenme verileri
    private var currentCalories: Double {
        mealService.totalCalories
    }
    
    private var currentCarbs: Double {
        mealService.totalCarbs
    }
    
    private var currentProtein: Double {
        mealService.totalProtein
    }
    
    private var currentFat: Double {
        mealService.totalFat
    }
    
    var body: some View {
        ZStack {
            Color.backgroundDarkBlue.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 25) {
                    // Greeting Section
                    greetingSection
                    
                    // Weekly Calendar
                    weeklyCalendarSection
                    
                    // Calorie Progress Circle
                    calorieProgressSection
                    
                    // Macros Progress
                    macroProgressSection
                    
                    // Add Meal Button
                    addMealButton
                    
                    // Diet Card
                    dietSection
                    
                    // Burned Calories Section
                    burnedCaloriesSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 100)
            }
        }
        .onAppear {
            loadUserName()
            loadCalorieTarget()
            requestHealthKitPermission()
            updateSelectedDietDisplay()
        }
        .onReceive(selectedDietService.$selectedDiet) { _ in
            updateSelectedDietDisplay()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("ProfileUpdated"))) { _ in
            print("🔄 Profil güncellendi notification'ı alındı - kalori hedefi yeniden yükleniyor")
            loadCalorieTarget()
            loadUserName() // İsim de değişmiş olabilir
        }
        .navigationDestination(isPresented: $showMealManagement) {
            MealManagementView()
        }
        .sheet(isPresented: $showDietSelection) {
            DietSelectionView(selectedDiet: $selectedDiet)
        }
        .sheet(isPresented: $showDietDay) {
            DietDayView()
        }
        .alert("Diyet Seçmediniz", isPresented: $showNoDietAlert) {
            Button("Diyetler Sayfasına Git") {
                selectedTab = 1 // Diyet Planları tab'ı
            }
            Button("İptal", role: .cancel) { }
        } message: {
            Text("Diyetler sayfasından bir diyet seçtikten sonra devam ediniz.")
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            Text("Merhaba, \(userName)!")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Spacer()
            
            Button(action: {
                // Bildirim aksiyonu
            }) {
                Image(systemName: "bell.fill")
                    .font(.title2)
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 5)
    }
    
    // MARK: - Greeting Section
    private var greetingSection: some View {
        HStack {
            Text("Merhaba, \(userName)!")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Spacer()
        }
    }
    
    // MARK: - Weekly Calendar Section
    private var weeklyCalendarSection: some View {
        HStack(spacing: 12) {
            ForEach(0..<7) { index in
                dayCard(for: index)
            }
        }
        .padding(.horizontal, 5)
    }
    
    private func dayCard(for index: Int) -> some View {
        let dayStatus = getDayStatus(for: index)
        let dayName = getDayName(for: index)
        let dayNumber = getDayNumber(for: index)
        
        return VStack(spacing: 8) {
            Text(dayName)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(dayStatus == .today ? .yellow : .white.opacity(0.7))
            
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(getDayColor(for: dayStatus))
                    .frame(width: 40, height: 40)
                
                if dayStatus == .completed {
                    Text("\(dayNumber)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                } else if dayStatus == .today {
                    Text("")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.black)
                } else {
                    Text("\(dayNumber)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
        }
    }
    
    // MARK: - Calorie Progress Section
    private var calorieProgressSection: some View {
        VStack(spacing: 20) {
            ZStack {
                // Background Circle
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 12)
                    .frame(width: 200, height: 200)
                
                // Progress Circle
                Circle()
                    .trim(from: 0, to: min(currentCalories / targetCalories, 1.0))
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.yellow, Color.orange]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.0), value: currentCalories)
                
                // Center Content
                VStack(spacing: 4) {
                    Text("\(Int(currentCalories))")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Kalori")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text("/ \(Int(targetCalories))")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
        }
    }
    
    // MARK: - Macro Progress Section
    private var macroProgressSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Makrolar")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            VStack(spacing: 16) {
                // Tek birleşik makro barı
                CombinedMacroProgressView(
                    carbsCurrent: currentCarbs,
                    carbsTarget: targetCarbs,
                    proteinCurrent: currentProtein,
                    proteinTarget: targetProtein,
                    fatCurrent: currentFat,
                    fatTarget: targetFat
                )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(Color.white.opacity(0.05))
            .cornerRadius(16)
        }
    }
    
    // MARK: - Add Meal Button
    private var addMealButton: some View {
        Button(action: {
            showMealManagement = true
        }) {
            HStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                
                Text("Öğünleri Düzenle")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.green, Color.green.opacity(0.8)]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
        }
    }
    
    // MARK: - Diet Card
    private var dietSection: some View {
        VStack(spacing: 12) {
            Button(action: {
                if selectedDietService.selectedDiet != nil {
                    showDietDay = true
                } else {
                    showNoDietAlert = true
                }
            }) {
                VStack(spacing: 15) {
                    // Üst kısım - Icon ve başlık
                    HStack {
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.buttonlightGreen)
                        
                        Text("Diyet Planım")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        if selectedDietService.selectedDiet != nil {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    
                    // Diyet durumu
                    VStack(spacing: 8) {
                        if selectedDietService.selectedDiet != nil {
                            let currentDay = selectedDietService.getCurrentDietDay()
                            let maxDays = selectedDietService.getDietDuration(selectedDietService.selectedDiet!.fileName)
                            
                            // Progress bar
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.white.opacity(0.1))
                                        .frame(height: 6)
                                    
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(LinearGradient(
                                            colors: [.buttonlightGreen, .buttonGreen],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ))
                                        .frame(width: geometry.size.width * (Double(currentDay) / Double(maxDays)), height: 6)
                                        .animation(.easeInOut(duration: 0.5), value: currentDay)
                                }
                            }
                            .frame(height: 6)
                            
                            // Diyet adı ve gün bilgisi
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(selectedDietService.selectedDiet!.name)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                    
                                    Text("\(currentDay). Gün / \(maxDays) Gün")
                                        .font(.caption)
                                        .foregroundColor(.buttonlightGreen)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("%\(Int((Double(currentDay) / Double(maxDays)) * 100))")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.buttonlightGreen)
                                    
                                    Text("Tamamlandı")
                                        .font(.caption2)
                                        .foregroundColor(.white.opacity(0.6))
                                }
                            }
                        } else {
                            Text("Henüz diyet seçmediniz")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, minHeight: 120)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.white.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(
                                    selectedDietService.selectedDiet != nil ? 
                                    Color.buttonlightGreen.opacity(0.3) : Color.clear,
                                    lineWidth: 1
                                )
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // MARK: - Helper Functions
    private func loadUserName() {
        // Önce kayıtlı kullanıcı adını kontrol et
        if let storedName = DataStorageService.shared.getUserName(), !storedName.isEmpty {
            userName = storedName
        } 
        // Eğer kayıtlı isim yoksa, giriş yapan kullanıcının email'ini kullan
        else if authManager.isLoggedIn && !authManager.currentUserEmail.isEmpty {
            // Email'den isim çıkarmaya çalış (@ işaretinden önceki kısım)
            let emailParts = authManager.currentUserEmail.components(separatedBy: "@")
            if let emailName = emailParts.first, !emailName.isEmpty {
                userName = emailName.capitalized
            } else {
                userName = "Kullanıcı"
            }
        }
        // Son çare olarak registration data'dan al
        else if let registrationName = RegistrationManager.shared.registrationData?.name, !registrationName.isEmpty {
            userName = registrationName
        }
    }
    
    private func loadCalorieTarget() {
        // Önce DataStorageService'den al (en güncel veriler burada)
        if let userData = DataStorageService.shared.loadRegistrationData() {
            let newCalories = Double(userData.dailyCalorieNeeds)
            print("📊 Kalori hedefi güncellendi: \(Int(targetCalories)) → \(Int(newCalories)) kcal")
            targetCalories = newCalories
        }
        // Fallback: RegistrationManager'dan al
        else if let registrationData = RegistrationManager.shared.registrationData {
            targetCalories = Double(registrationData.dailyCalorieNeeds)
            print("📊 Kalori hedefi RegistrationManager'dan yüklendi: \(Int(targetCalories)) kcal")
        }
        // Son çare olarak default değer
        else {
            targetCalories = 2000.0
            print("⚠️ Kalori hedefi default değer kullanıyor: \(Int(targetCalories)) kcal")
        }
        
        // Makro hedeflerini kalori hedefine göre hesapla
        updateMacroTargets()
    }
    
    private func updateMacroTargets() {
        // Standart makro dağılımı:
        // Karbonhidrat: %45-65 (ortalama %50) - 4 kcal/g
        // Protein: %10-35 (ortalama %20) - 4 kcal/g  
        // Yağ: %20-35 (ortalama %30) - 9 kcal/g
        
        targetCarbs = (targetCalories * 0.50) / 4  // %50 karbonhidrat
        targetProtein = (targetCalories * 0.20) / 4  // %20 protein
        targetFat = (targetCalories * 0.30) / 9  // %30 yağ
        
        print("🥗 Makro hedefleri güncellendi:")
        print("  - Karbonhidrat: \(Int(targetCarbs))g")
        print("  - Protein: \(Int(targetProtein))g") 
        print("  - Yağ: \(Int(targetFat))g")
    }
    
    private func getDayStatus(for index: Int) -> DayStatus {
        let today = Calendar.current.component(.weekday, from: Date()) - 1
        let adjustedToday = today == 0 ? 6 : today - 1 // Pazartesi = 0
        
        if index < adjustedToday {
            // Geçmiş günler - rastgele bazıları tamamlanmış
            return [true, false, true, false, true, false, true][index] ? .completed : .missed
        } else if index == adjustedToday {
            return .today
        } else {
            return .upcoming
        }
    }
    
    private func getDayName(for index: Int) -> String {
        let days = ["Pzt", "Sal", "Çar", "Per", "Cum", "Cmt", "Paz"]
        return days[index]
    }
    
    private func getDayNumber(for index: Int) -> Int {
        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        let daysFromMonday = weekday == 1 ? 6 : weekday - 2
        
        if let targetDate = calendar.date(byAdding: .day, value: index - daysFromMonday, to: today) {
            return calendar.component(.day, from: targetDate)
        }
        return index + 1
    }
    
    private func getDayColor(for status: DayStatus) -> Color {
        switch status {
        case .completed:
            return .buttonlightGreen
        case .today:
            return .yellow
        case .upcoming, .missed:
            return .white.opacity(0.2)
        }
    }
}

// MARK: - Supporting Views
struct CombinedMacroProgressView: View {
    let carbsCurrent: Double
    let carbsTarget: Double
    let proteinCurrent: Double
    let proteinTarget: Double
    let fatCurrent: Double
    let fatTarget: Double
    
    private var totalCurrent: Double {
        carbsCurrent + proteinCurrent + fatCurrent
    }
    
    private var totalTarget: Double {
        carbsTarget + proteinTarget + fatTarget
    }
    
    private var carbsPercentage: Double {
        guard totalCurrent > 0 else { return 0 }
        return carbsCurrent / totalCurrent
    }
    
    private var proteinPercentage: Double {
        guard totalCurrent > 0 else { return 0 }
        return proteinCurrent / totalCurrent
    }
    
    private var fatPercentage: Double {
        guard totalCurrent > 0 else { return 0 }
        return fatCurrent / totalCurrent
    }
    
    private var overallProgress: Double {
        guard totalTarget > 0 else { return 0 }
        return min(totalCurrent / totalTarget, 1.0)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Makro bilgileri
            HStack(spacing: 20) {
                // Karbonhidrat
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 8, height: 8)
                        Text("Karbonhidrat")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                    Text("\(Int(carbsCurrent))g")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    Text("%\(Int(carbsPercentage * 100))")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                // Protein
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                        Text("Protein")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                    Text("\(Int(proteinCurrent))g")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    Text("%\(Int(proteinPercentage * 100))")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                // Yağ
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                        Text("Yağ")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                    Text("\(Int(fatCurrent))g")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    Text("%\(Int(fatPercentage * 100))")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            // Birleşik progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Arka plan
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 12)
                    
                    // Makro oranlarını gösteren renkli barlar
                    HStack(spacing: 0) {
                        // Karbonhidrat barı
                        if carbsPercentage > 0 {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.blue)
                                .frame(width: geometry.size.width * overallProgress * carbsPercentage, height: 12)
                        }
                        
                        // Protein barı
                        if proteinPercentage > 0 {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.green)
                                .frame(width: geometry.size.width * overallProgress * proteinPercentage, height: 12)
                        }
                        
                        // Yağ barı
                        if fatPercentage > 0 {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.red)
                                .frame(width: geometry.size.width * overallProgress * fatPercentage, height: 12)
                        }
                        
                        Spacer(minLength: 0)
                    }
                    .animation(.easeInOut(duration: 0.5), value: overallProgress)
                }
            }
            .frame(height: 12)
            

        }
    }
}

struct MacroProgressView: View {
    let title: String
    let current: Double
    let target: Double
    let color: Color
    let unit: String
    
    private var progress: Double {
        guard target > 0 else { return 0 }
        return min(current / target, 1.0)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                HStack(spacing: 8) {
                    Circle()
                        .fill(color)
                        .frame(width: 8, height: 8)
                    
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Text("\(Int(current)) / \(Int(target)) \(unit)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geometry.size.width * progress, height: 8)
                        .animation(.easeInOut(duration: 0.5), value: progress)
                }
            }
            .frame(height: 8)
        }
    }
}

// MARK: - Burned Calories Section (HomeView extension)
extension HomeView {
    private var burnedCaloriesSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Yakılan Kalori")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                // HealthKit'ten gelen kalori
                HStack {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 8, height: 8)
                    
                    Text("Sağlık Uygulaması")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("\(Int(healthKitService.dailyCalories)) kcal")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.orange)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
                
                // Egzersizlerden yakılan kalori
                HStack {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                    
                    Text("Egzersiz Programları")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("\(Int(exerciseTrackingService.totalCaloriesBurnedToday)) kcal")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.red)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
                
                // Toplam yakılan kalori
                Divider()
                    .background(Color.white.opacity(0.3))
                
                HStack {
                    Text("Toplam Yakılan")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("\(Int(healthKitService.dailyCalories + exerciseTrackingService.totalCaloriesBurnedToday)) kcal")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.buttonlightGreen)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                
                // Grafik Görselleştirme
                burnedCaloriesChart
            }
            .padding(16)
            .background(Color.white.opacity(0.1))
            .cornerRadius(16)
        }
    }
    
    private var burnedCaloriesChart: some View {
        let totalCalories = healthKitService.dailyCalories + exerciseTrackingService.totalCaloriesBurnedToday
        let healthKitPercentage = totalCalories > 0 ? (healthKitService.dailyCalories / totalCalories) : 0
        let exercisePercentage = totalCalories > 0 ? (exerciseTrackingService.totalCaloriesBurnedToday / totalCalories) : 0
        
        return VStack(spacing: 12) {
            Text("Kalori Dağılımı")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
            
            // Progress Bar Chart
            GeometryReader { geometry in
                HStack(spacing: 2) {
                    // HealthKit Bar
                    Rectangle()
                        .fill(Color.orange)
                        .frame(width: geometry.size.width * healthKitPercentage)
                        .cornerRadius(4)
                    
                    // Exercise Bar
                    Rectangle()
                        .fill(Color.red)
                        .frame(width: geometry.size.width * exercisePercentage)
                        .cornerRadius(4)
                    
                    // Empty space
                    if totalCalories == 0 {
                        Rectangle()
                            .fill(Color.white.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
                .animation(.easeInOut(duration: 0.8), value: totalCalories)
            }
            .frame(height: 8)
            
            // Yüzde Bilgileri
            HStack {
                // HealthKit percentage
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 6, height: 6)
                    Text("\(Int(healthKitPercentage * 100))%")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                // Exercise percentage
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 6, height: 6)
                    Text("\(Int(exercisePercentage * 100))%")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
    
    private func requestHealthKitPermission() {
        Task {
            await healthKitService.requestAuthorization()
        }
    }
    
    private func updateSelectedDietDisplay() {
        selectedDiet = selectedDietService.getDietStatusText()
    }
    

}

// MARK: - Add Meal Sheet
struct AddMealSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.backgroundDarkBlue.ignoresSafeArea()
                
                VStack {
                    Text("Öğün Ekleme")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("Bu özellik yakında gelecek!")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Öğün Ekle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") {
                        dismiss()
                    }
                    .foregroundColor(.buttonlightGreen)
                }
            }
        }
    }
}

// MARK: - Diet Selection Sheet
struct DietSelectionSheet: View {
    @Binding var selectedDiet: String
    @Environment(\.dismiss) private var dismiss
    
    let diets = [
        "Akdeniz Diyeti",
        "Ketojenik Diyet",
        "Düşük Karbonhidrat",
        "Vejetaryen",
        "Vegan",
        "Paleo Diyet",
        "DASH Diyeti",
        "Aralıklı Oruç"
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.backgroundDarkBlue.ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 15) {
                        ForEach(diets, id: \.self) { diet in
                            Button(action: {
                                selectedDiet = diet
                                dismiss()
                            }) {
                                HStack {
                                    Image(systemName: "leaf.fill")
                                        .foregroundColor(.buttonlightGreen)
                                    
                                    Text(diet)
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    if selectedDiet == diet {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.buttonlightGreen)
                                    }
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedDiet == diet ? Color.buttonlightGreen.opacity(0.2) : Color.white.opacity(0.1))
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Diyet Seç")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") {
                        dismiss()
                    }
                    .foregroundColor(.buttonlightGreen)
                }
            }
        }
    }
}

#Preview {
    HomeView(selectedTab: .constant(0))
} 
