import SwiftUI

struct FoodDetailView: View {
    let food: Food
    let onMealAdded: () -> Void
    
    @Environment(\.dismiss) private var dismiss

    @ObservedObject private var mealService = MealService.shared
    
    @State private var selectedServing: Serving?
    @State private var gramAmount: Double = 100.0  // Gram bazlı miktar
    @State private var selectedMealType: MealData.MealType = .breakfast  // Öğün tipi seçimi
    @State private var isLoading = false
    @State private var foodDetail: FoodDetail?
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.backgroundDarkBlue.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    headerSection
                    
                    // Content
                    if isLoading {
                        loadingView
                    } else {
                        contentView
                    }
                }
            }
        }
        .onAppear {
            loadFoodDetail()
        }
        .alert("Bilgi", isPresented: $showingAlert) {
            Button("Tamam") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private var headerSection: some View {
        HStack {
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "xmark")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
            
            Spacer()
            
            Text("Yiyecek Detayı")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Spacer()
            
            Button(action: {
                addMeal()
            }) {
                Text("Ekle")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color.white)
                    .cornerRadius(20)
            }
            .disabled(selectedServing == nil)
            .opacity(selectedServing == nil ? 0.5 : 1.0)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
    
    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
            
            Text("Yükleniyor...")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.top, 20)
            Spacer()
        }
    }
    
    private var contentView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Food Info
                foodInfoSection
                
                // Meal Type Selection
                mealTypeSelectionSection
                
                // Serving Selection
                if let detail = foodDetail {
                    servingSelectionSection(detail: detail)
                }
                
                // Gram Amount Selection
                gramAmountSection
                
                // Nutrition Info
                if let serving = selectedServing {
                    nutritionInfoSection(serving: serving)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 100)
        }
    }
    
    private var foodInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(food.foodName ?? "Bilinmeyen Yiyecek")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            if let description = food.foodDescription {
                Text(description)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var mealTypeSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Hangi Öğüne Eklensin?")
                .font(.headline)
                .foregroundColor(.white)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                                        ForEach([MealData.MealType.breakfast, .lunch, .dinner, .snack], id: \.self) { mealType in
                    Button(action: {
                        selectedMealType = mealType
                    }) {
                        HStack {
                            Image(systemName: mealTypeIcon(for: mealType))
                                .font(.title3)
                                .foregroundColor(selectedMealType == mealType ? .black : .white)
                            
                            Text(mealType.rawValue)
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(selectedMealType == mealType ? .black : .white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(
                            selectedMealType == mealType ? 
                            Color.white : Color.white.opacity(0.1)
                        )
                        .cornerRadius(12)
                    }
                }
            }
        }
    }
    
    private func mealTypeIcon(for mealType: MealData.MealType) -> String {
        switch mealType {
        case .breakfast:
            return "sunrise.fill"
        case .lunch:
            return "sun.max.fill"
        case .dinner:
            return "moon.fill"
        case .snack:
            return "leaf.fill"
        }
    }
    
    private func servingSelectionSection(detail: FoodDetail) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Porsiyon Seçin")
                .font(.headline)
                .foregroundColor(.white)
            
            ForEach(detail.servings?.serving ?? [], id: \.servingId) { serving in
                Button(action: {
                    selectedServing = serving
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(serving.servingDescription ?? "Bilinmeyen porsiyon")
                                .font(.body)
                                .foregroundColor(.white)
                            
                            Text("\(serving.calories ?? "0") kalori")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        Spacer()
                        
                        Image(systemName: selectedServing?.servingId == serving.servingId ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(selectedServing?.servingId == serving.servingId ? .green : .white.opacity(0.5))
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(
                        selectedServing?.servingId == serving.servingId ? 
                        Color.white.opacity(0.2) : Color.white.opacity(0.1)
                    )
                    .cornerRadius(8)
                }
            }
        }
    }
    
    private var gramAmountSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Miktar (Gram)")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 16) {
                // Slider for gram amount
                VStack(spacing: 8) {
                    HStack {
                        Text("1g")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        
                        Spacer()
                        
                        Text("\(Int(gramAmount))g")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text("1000g")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Slider(value: $gramAmount, in: 1...1000, step: 1)
                        .accentColor(.white)
                }
                
                // Quick selection buttons
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 8) {
                    ForEach([50, 100, 150, 200], id: \.self) { amount in
                        Button(action: {
                            gramAmount = Double(amount)
                        }) {
                            Text("\(amount)g")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(gramAmount == Double(amount) ? .black : .white)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(
                                    gramAmount == Double(amount) ? 
                                    Color.white : Color.white.opacity(0.2)
                                )
                                .cornerRadius(8)
                        }
                    }
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .background(Color.white.opacity(0.1))
            .cornerRadius(12)
        }
    }
    
    private func nutritionInfoSection(serving: Serving) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Besin Değerleri (\(Int(gramAmount))g için)")
                .font(.headline)
                .foregroundColor(.white)
            
            // 100g bazındaki değerleri gram miktarına göre oranla
            let baseAmount = 100.0 // Nutritionix verileri 100g bazında
            let ratio = gramAmount / baseAmount
            
            let totalCalories = (Double(serving.calories ?? "0") ?? 0) * ratio
            let totalCarbs = (Double(serving.carbohydrate ?? "0") ?? 0) * ratio
            let totalProtein = (Double(serving.protein ?? "0") ?? 0) * ratio
            let totalFat = (Double(serving.fat ?? "0") ?? 0) * ratio
            
            VStack(spacing: 8) {
                nutritionRow(title: "Kalori", value: String(format: "%.0f", totalCalories), unit: "kcal")
                nutritionRow(title: "Karbonhidrat", value: String(format: "%.1f", totalCarbs), unit: "g")
                nutritionRow(title: "Protein", value: String(format: "%.1f", totalProtein), unit: "g")
                nutritionRow(title: "Yağ", value: String(format: "%.1f", totalFat), unit: "g")
                
                Divider()
                    .background(Color.white.opacity(0.3))
                
                // 100g bazındaki referans değerler
                VStack(spacing: 4) {
                    Text("100g başına:")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    
                    HStack {
                        Text("Kalori: \(serving.calories ?? "0") kcal")
                        Spacer()
                        Text("Protein: \(serving.protein ?? "0")g")
                    }
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .background(Color.white.opacity(0.1))
            .cornerRadius(12)
        }
    }
    
    private func nutritionRow(title: String, value: String, unit: String) -> some View {
        HStack {
            Text(title)
                .font(.body)
                .foregroundColor(.white)
            
            Spacer()
            
            Text("\(value) \(unit)")
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.white)
        }
    }
    
    private func loadFoodDetail() {
        // Create food detail from the food info
        // Extract nutrition info from food description
        let description = food.foodDescription ?? ""
        
        // Parse calories, carbs, protein, fat from description
        let calories = extractValue(from: description, pattern: "Calories: (\\d+)")
        let carbs = extractValue(from: description, pattern: "Carbs: ([\\d.]+)g")
        let protein = extractValue(from: description, pattern: "Protein: ([\\d.]+)g")
        let fat = extractValue(from: description, pattern: "Fat: ([\\d.]+)g")
        
        // Create a default serving
        let defaultServing = Serving(
            servingId: "1",
            servingDescription: "1 porsiyon",
            servingUrl: nil,
            metricServingAmount: "100",
            metricServingUnit: "g",
            numberOfUnits: "1",
            measurementDescription: "porsiyon",
            calories: calories,
            carbohydrate: carbs,
            protein: protein,
            fat: fat,
            saturatedFat: nil,
            polyunsaturatedFat: nil,
            monounsaturatedFat: nil,
            transFat: nil,
            cholesterol: nil,
            sodium: nil,
            potassium: nil,
            fiber: nil,
            sugar: nil,
            vitaminA: nil,
            vitaminC: nil,
            calcium: nil,
            iron: nil
        )
        
        // Create food detail with default serving
        let servings = Servings(serving: [defaultServing])
        foodDetail = FoodDetail(
            foodId: food.foodId,
            foodName: food.foodName,
            foodType: food.foodType,
            foodUrl: food.foodUrl,
            servings: servings
        )
        
        // Select the default serving
        selectedServing = defaultServing
    }
    
    private func extractValue(from text: String, pattern: String) -> String {
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: text.utf16.count)
        
        if let match = regex?.firstMatch(in: text, options: [], range: range),
           let valueRange = Range(match.range(at: 1), in: text) {
            return String(text[valueRange])
        }
        
        return "0"
    }
    
    private func addMeal() {
        guard let serving = selectedServing else {
            DispatchQueue.main.async {
                self.alertMessage = "Lütfen bir porsiyon seçin"
                self.showingAlert = true
            }
            return
        }
        
        // 100g bazındaki değerleri gram miktarına göre oranla
        let baseAmount = 100.0 // Nutritionix verileri 100g bazında
        let ratio = gramAmount / baseAmount
        
        let totalCalories = (Double(serving.calories ?? "0") ?? 0) * ratio
        let totalCarbs = (Double(serving.carbohydrate ?? "0") ?? 0) * ratio
        let totalProtein = (Double(serving.protein ?? "0") ?? 0) * ratio
        let totalFat = (Double(serving.fat ?? "0") ?? 0) * ratio
        
                    let mealEntry = MealData(
            foodId: food.foodId,
            foodName: food.foodName ?? "Bilinmeyen Yiyecek",
            servingDescription: "\(Int(gramAmount))g",
            quantity: gramAmount,
            calories: totalCalories,
            carbs: totalCarbs,
            protein: totalProtein,
            fat: totalFat,
            mealType: selectedMealType,
            dateAdded: Date()
        )
        
        // Main thread'de meal ekleme ve UI güncellemesi
        DispatchQueue.main.async {
            self.mealService.addMeal(mealEntry)
            self.onMealAdded()
        }
    }
}

#Preview {
    // Preview content - using mock data
    ZStack {
        Color.backgroundDarkBlue.ignoresSafeArea()
        Text("Food Detail Preview")
            .foregroundColor(.white)
    }
} 