import SwiftUI

struct DietDayView: View {
    @ObservedObject private var selectedDietService = SelectedDietService.shared
    @ObservedObject private var mealService = MealService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showingDietSelection = false
    @State private var showingCompletionAlert = false
    @State private var completedMealName = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.backgroundDarkBlue.ignoresSafeArea()
                
                if let selectedDiet = selectedDietService.selectedDiet {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Header
                            VStack(spacing: 12) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(selectedDiet.name)
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                        
                                        Text("Gün \(selectedDietService.currentDay)")
                                            .font(.subheadline)
                                            .foregroundColor(.buttonlightGreen)
                                    }
                                    
                                    Spacer()
                                    
                                    // Gün navigasyon butonları
                                    HStack {
                                        Button(action: {
                                            selectedDietService.previousDay()
                                        }) {
                                            Image(systemName: "chevron.left")
                                                .foregroundColor(.white)
                                                .padding(8)
                                                .background(Color.white.opacity(0.2))
                                                .clipShape(Circle())
                                        }
                                        .disabled(selectedDietService.currentDay <= 1)
                                        
                                        Button(action: {
                                            selectedDietService.nextDay()
                                        }) {
                                            Image(systemName: "chevron.right")
                                                .foregroundColor(.white)
                                                .padding(8)
                                                .background(Color.white.opacity(0.2))
                                                .clipShape(Circle())
                                        }
                                        .disabled(selectedDietService.currentDay >= selectedDietService.getDietDuration(selectedDiet.fileName))
                                    }
                                }
                                .padding()
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(16)
                                
                                // Diyet Açıklaması
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Diyet Hakkında")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                    
                                    Text(DietService.shared.getDietDescription(fileName: selectedDiet.fileName))
                                        .font(.body)
                                        .foregroundColor(.white.opacity(0.8))
                                        .lineLimit(nil)
                                        .multilineTextAlignment(.leading)
                                }
                                .padding()
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(12)
                            }
                            
                            // Öğün Listesi
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Bugünün Öğünleri")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                ForEach(selectedDietService.todaysMeals) { meal in
                                    DietMealCard(
                                        meal: meal,
                                        isCompleted: selectedDietService.isMealCompleted(meal),
                                        onComplete: {
                                            completeMeal(meal)
                                        }
                                    )
                                }
                            }
                        }
                        .padding()
                    }
                } else {
                    // Diyet seçilmemiş
                    VStack(spacing: 20) {
                        Text("Diyet Seçilmedi")
                            .font(.title)
                            .foregroundColor(.white)
                        
                        Button("Diyet Seç") {
                            showingDietSelection = true
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.buttonlightGreen)
                        .cornerRadius(12)
                    }
                }
            }
            .navigationTitle("Günlük Diyet")
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
        .sheet(isPresented: $showingDietSelection) {
            SimpleDietSelectionView()
        }
        .alert("Öğün Tamamlandı! 🎉", isPresented: $showingCompletionAlert) {
            Button("Harika!") { }
        } message: {
            Text("\(completedMealName) öğününüz başarıyla tamamlandı ve kalorileri günlük takibinize eklendi.")
        }
        .onAppear {
            if selectedDietService.selectedDiet == nil {
                showingDietSelection = true
            }
        }
    }
    
    private func completeMeal(_ meal: DietMeal) {
        selectedDietService.markMealAsCompleted(meal)
        
        mealService.addManualMeal(
            foodName: meal.type,
            calories: meal.calories,
            protein: meal.proteinG,
            carbs: meal.carbsG,
            fat: meal.fatG,
            mealType: convertToMealType(meal.type)
        )
        
        completedMealName = meal.type
        showingCompletionAlert = true
    }
    
    private func convertToMealType(_ dietMealType: String) -> MealData.MealType {
        switch dietMealType {
        case "Kahvaltı":
            return .breakfast
        case "Öğle", "Öğle Yemeği":
            return .lunch
        case "Akşam", "Akşam Yemeği":
            return .dinner
        default:
            return .snack
        }
    }
}

struct DietMealCard: View {
    let meal: DietMeal
    let isCompleted: Bool
    let onComplete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text(meal.type)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("\(Int(meal.calories)) kcal")
                        .font(.subheadline)
                        .foregroundColor(.orange)
                }
                
                Spacer()
                
                if isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title)
                        .foregroundColor(.green)
                } else {
                    Button("Tamamla") {
                        onComplete()
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color.buttonlightGreen)
                    .cornerRadius(20)
                }
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("İçerik:")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.8))
                
                ForEach(meal.items, id: \.self) { item in
                    HStack {
                        Text("•")
                            .foregroundColor(.buttonlightGreen)
                        Text(item)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(
            isCompleted ? 
            Color.green.opacity(0.1) : 
            Color.white.opacity(0.05)
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    isCompleted ? Color.green : Color.white.opacity(0.1),
                    lineWidth: isCompleted ? 2 : 1
                )
        )
    }
}

struct SimpleDietSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var selectedDietService = SelectedDietService.shared
    
    private let availableDiets: [DietPlan] = [
        DietPlan(
            name: "Keto Diyeti",
            description: "Düşük karbonhidrat diyeti",
            image: "keto",
            duration: "14 gün",
            meals: 5,
            calories: 2000,
            difficulty: "Zor",
            category: "Düşük Karb",
            fileName: "Keto"
        ),
        DietPlan(
            name: "Akdeniz Diyeti",
            description: "Dengeli beslenme",
            image: "mediterranean",
            duration: "14 gün",
            meals: 5,
            calories: 1937,
            difficulty: "Kolay",
            category: "Dengeli",
            fileName: "Akdeniz"
        )
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.backgroundDarkBlue.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Custom header
                    HStack {
                        Text("Diyet Seç")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white.opacity(0.6))
                        
                        Spacer()
                        
                        Button("Kapat") {
                            dismiss()
                        }
                        .foregroundColor(.buttonlightGreen)
                        .font(.headline)
                    }
                    .padding()
                    .background(Color.backgroundDarkBlue)
                    
                    ScrollView {
                        LazyVStack(spacing: 15) {
                        ForEach(availableDiets) { diet in
                            Button(action: {
                                selectedDietService.selectDiet(diet)
                                dismiss()
                            }) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(diet.name)
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        
                                        Text("\(diet.duration) • \(diet.calories) kcal")
                                            .font(.subheadline)
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.buttonlightGreen)
                                }
                                .padding()
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(12)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        }
                        .padding()
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    DietDayView()
} 