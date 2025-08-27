import SwiftUI

struct DietPlan: Identifiable, Codable {
    var id = UUID()
    var name: String
    var description: String
    var image: String
    var duration: String
    var meals: Int
    var calories: Int
    var difficulty: String
    var category: String
    var fileName: String // JSON dosya adı
}

struct DietListView: View {
    @ObservedObject private var dietService = DietService.shared
    
    // JSON dosyalarındaki diyetler - düzeltilmiş veriler
    @State private var dietPlans: [DietPlan] = []
    
    // Kategori filtreleme seçenekleri - JSON'lardaki diyetlere göre güncellenmiş
    let categories = ["Tümü", "Düşük Karb", "Dengeli", "Aralıklı", "Doğal", "Bitkisel", "Protein"]
    
    // Filtrelenmiş diyet planlarını getir
    var filteredDietPlans: [DietPlan] {
        if selectedCategory == nil || selectedCategory == "Tümü" {
            return dietPlans
        } else {
            return dietPlans.filter { $0.category == selectedCategory }
        }
    }
    
    @State private var selectedCategory: String?
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    // Her diyet için özel renkler
    let dietColors: [String: Color] = [
        "Keto": .orange.opacity(0.8),
        "Akdeniz": .blue.opacity(0.8),
        "intermittent_fasting": .purple.opacity(0.8),
        "paleo": .green.opacity(0.8),
        "vegan": .cyan.opacity(0.8),
        "high_protein": .red.opacity(0.8)
    ]
    
    var body: some View {
        ZStack {
            Color.backgroundDarkBlue.ignoresSafeArea()
            
            VStack {
                // Başlık
                VStack(alignment: .leading, spacing: 15) {
                    Text("Diyet Planları")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Hedeflerinize uygun, uzmanlar tarafından hazırlanmış beslenme programları")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.horizontal)
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Filtre seçenekleri
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(categories, id: \.self) { category in
                            Button(action: {
                                if selectedCategory == category {
                                    selectedCategory = nil
                                } else {
                                    selectedCategory = category
                                }
                            }) {
                                Text(category)
                                    .font(.system(size: 14, weight: .medium))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(selectedCategory == category ? Color.buttonlightGreen : Color.white.opacity(0.15))
                                    .foregroundColor(selectedCategory == category ? .black : .white)
                                    .cornerRadius(20)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.top, 5)
                
                // Diyet planları grid görünümü
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(filteredDietPlans) { diet in
                            NavigationLink(destination: DietDetailView(diet: diet)) {
                                DietCardView(
                                    diet: diet, 
                                    color: dietColors[diet.fileName] ?? .gray.opacity(0.7)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                }
            }
            .padding(.top, 20)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    // Bildirim aksiyonu
                }) {
                    Image(systemName: "bell.fill")
                        .foregroundColor(.white)
                }
            }
        }
        .onAppear {
            loadDietPlans()
        }
    }
    
    private func loadDietPlans() {
        let dietData = [
            ("Keto Diyeti", "Keto", "keto_diet", "14 gün", 5, 2000, "Zor", "Düşük Karb"),
            ("Akdeniz Diyeti", "Akdeniz", "mediterranean_diet", "14 gün", 5, 1937, "Kolay", "Dengeli"),
            ("Aralıklı Oruç", "intermittent_fasting", "intermittent_fasting", "7 gün", 3, 1757, "Orta", "Aralıklı"),
            ("Paleo Diyeti", "paleo", "paleo_diet", "7 gün", 5, 2161, "Orta", "Doğal"),
            ("Vegan Diyeti", "vegan", "vegan_diet", "10 gün", 5, 1992, "Orta", "Bitkisel"),
            ("Yüksek Protein Diyeti", "high_protein", "high_protein_diet", "7 gün", 5, 2610, "Orta", "Protein")
        ]
        
        dietPlans = dietData.map { (name, fileName, image, duration, meals, calories, difficulty, category) in
            DietPlan(
                name: name,
                description: dietService.getDietDescription(fileName: fileName),
                image: image,
                duration: duration,
                meals: meals,
                calories: calories,
                difficulty: difficulty,
                category: category,
                fileName: fileName
            )
        }
    }
}

struct DietCardView: View {
    let diet: DietPlan
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Görsel
            Rectangle()
                .fill(color)
                .aspectRatio(1.5, contentMode: .fit)
                .overlay(
                    Image(systemName: getDietIcon(for: diet.fileName))
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.white)
                        .frame(width: 35, height: 35)
                )
                .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 8) {
                // Diyet adı
                Text(diet.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                // Açıklama
                Text(diet.description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                // Süre ve öğün sayısı
                HStack(spacing: 12) {
                    Label(diet.duration, systemImage: "calendar.circle.fill")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Label("\(diet.meals) öğün", systemImage: "fork.knife.circle.fill")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                // Kalori ve zorluk
                HStack(spacing: 12) {
                    Label("\(diet.calories) kcal", systemImage: "flame.circle.fill")
                        .font(.caption)
                        .foregroundColor(.orange.opacity(0.8))
                    
                    Text(diet.difficulty)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(getDifficultyColor(diet.difficulty))
                        .foregroundColor(.white)
                        .cornerRadius(6)
                }
                

            }
            .padding(.horizontal, 4)
        }
        .padding(12)
        .background(Color.white.opacity(0.08))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
        .frame(minHeight: 200)
    }
    
    private func getDietIcon(for fileName: String) -> String {
        switch fileName {
        case "Keto":
            return "flame.fill"
        case "Akdeniz":
            return "leaf.fill"
        case "intermittent_fasting":
            return "clock.fill"
        case "paleo":
            return "mountain.2.fill"
        case "vegan":
            return "carrot.fill"
        case "high_protein":
            return "dumbbell.fill"
        default:
            return "fork.knife"
        }
    }
    
    private func getDifficultyColor(_ difficulty: String) -> Color {
        switch difficulty {
        case "Kolay":
            return .green.opacity(0.7)
        case "Orta":
            return .orange.opacity(0.7)
        case "Zor":
            return .red.opacity(0.7)
        default:
            return .gray.opacity(0.7)
        }
    }
}

// MARK: - Diet Detail View
struct DietDetailView: View {
    let diet: DietPlan
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var dietService = DietService.shared
    @ObservedObject private var selectedDietService = SelectedDietService.shared
    @State private var selectedDay = 1
    @State private var dailyMeals: [DietMeal] = []
    
    var body: some View {
        ZStack {
            Color.backgroundDarkBlue.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Başlık ve kapat butonu
                    HStack {
                        VStack(alignment: .leading) {
                            Text(diet.name)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text(diet.category)
                                .font(.subheadline)
                                .foregroundColor(.buttonlightGreen)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    
                    // Diet görseli ve özet bilgiler
                    VStack(spacing: 15) {
                        Rectangle()
                            .fill(dietColors[diet.fileName] ?? .gray.opacity(0.7))
                            .frame(height: 200)
                            .cornerRadius(16)
                            .overlay(
                                Image(systemName: getDietIcon(for: diet.fileName))
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundColor(.white)
                                    .frame(width: 60, height: 60)
                            )
                        
                        // Özet bilgiler
                        HStack(spacing: 15) {
                            // Süre
                            VStack {
                                Text("Süre")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Text(diet.duration)
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(10)
                            
                            // Öğün Sayısı
                            VStack {
                                Text("Öğün")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Text("\(diet.meals)")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(10)
                            
                            // Kalori
                            VStack {
                                Text("Kalori")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Text("\(diet.calories)")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(10)
                        }
                    }
                    
                    // Açıklama
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Program Hakkında")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text(diet.description)
                            .font(.body)
                            .foregroundColor(.white.opacity(0.8))
                            .lineSpacing(5)
                            .multilineTextAlignment(.leading)
                    }
                    .padding()
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)
                    
                    // Gün seçici
                    Text("Günlük Plan")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.top, 10)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(1...getDayCount(for: diet.fileName), id: \.self) { day in
                                Button(action: {
                                    selectedDay = day
                                    loadMealsForDay()
                                }) {
                                    Text("Gün \(day)")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(selectedDay == day ? Color.buttonlightGreen : Color.white.opacity(0.15))
                                        .foregroundColor(selectedDay == day ? .black : .white)
                                        .cornerRadius(20)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Günlük öğünler
                    if !dailyMeals.isEmpty {
                        ForEach(dailyMeals) { meal in
                            MealCardView(meal: meal)
                        }
                    }
                    
                    // Programı başlat butonu
                    Button(action: {
                        // Diyet programını başlat ve SelectedDietService'e kaydet
                        selectedDietService.selectDiet(diet)
                        dismiss()
                    }) {
                        Text("Diyet Programını Başlat")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.buttonlightGreen)
                            .cornerRadius(10)
                    }
                    .padding(.top, 30)
                }
                .padding()
            }
        }
        .onAppear {
            loadMealsForDay()
        }
    }
    
    private func loadMealsForDay() {
        dailyMeals = dietService.getMealsForDay(fileName: diet.fileName, dayNumber: selectedDay)
    }
    
    private func getDayCount(for fileName: String) -> Int {
        // DietService'den gerçek gün sayısını al
        return DietService.shared.getMaxDayCount(fileName: fileName)
    }
    
    private func getDietIcon(for fileName: String) -> String {
        switch fileName {
        case "Keto":
            return "flame.fill"
        case "Akdeniz":
            return "leaf.fill"
        case "intermittent_fasting":
            return "clock.fill"
        case "paleo":
            return "mountain.2.fill"
        case "vegan":
            return "carrot.fill"
        case "high_protein":
            return "dumbbell.fill"
        default:
            return "fork.knife"
        }
    }
    
    private var dietColors: [String: Color] {
        [
            "Keto": .orange.opacity(0.8),
            "Akdeniz": .blue.opacity(0.8),
            "intermittent_fasting": .purple.opacity(0.8),
            "paleo": .green.opacity(0.8),
            "vegan": .cyan.opacity(0.8),
            "high_protein": .red.opacity(0.8)
        ]
    }
}

struct MealCardView: View {
    let meal: DietMeal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(meal.type)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(Int(meal.calories)) kcal")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.orange)
            }
            
            // Makro besinler
            HStack(spacing: 15) {
                MacroView(title: "Protein", value: meal.proteinG, color: .green)
                MacroView(title: "Karb", value: meal.carbsG, color: .blue)
                MacroView(title: "Yağ", value: meal.fatG, color: .red)
            }
            
            // Yiyecekler
            VStack(alignment: .leading, spacing: 4) {
                Text("Yiyecekler:")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                
                ForEach(meal.items, id: \.self) { item in
                    HStack {
                        Circle()
                            .fill(Color.buttonlightGreen)
                            .frame(width: 4, height: 4)
                        
                        Text(item)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}

struct MacroView: View {
    let title: String
    let value: Double
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.7))
            
            Text("\(Int(value))g")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }
}

// Basit öğün kartı - DailyDietView'deki MealCardView ile çakışmayı önlemek için
struct DietMealCardView: View {
    let meal: DietMeal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(meal.type)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(Int(meal.calories)) kcal")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.orange)
            }
            
            // Makro besinler
            HStack(spacing: 15) {
                DietMacroView(title: "Protein", value: meal.proteinG, color: .green)
                DietMacroView(title: "Karb", value: meal.carbsG, color: .blue)
                DietMacroView(title: "Yağ", value: meal.fatG, color: .red)
            }
            
            // Yiyecekler
            VStack(alignment: .leading, spacing: 4) {
                Text("Yiyecekler:")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                
                ForEach(meal.items, id: \.self) { item in
                    HStack {
                        Circle()
                            .fill(Color.buttonlightGreen)
                            .frame(width: 4, height: 4)
                        
                        Text(item)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}

struct DietMacroView: View {
    let title: String
    let value: Double
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.7))
            
            Text("\(Int(value))g")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }
}

#Preview {
    DietListView()
} 