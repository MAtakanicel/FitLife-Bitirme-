import SwiftUI

struct AddMealView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var nutritionixService = NutritionixService.shared
    @ObservedObject private var mealService = MealService.shared
    
    @State private var searchText = ""
    @State private var selectedFood: Food?
    @State private var selectedServing: Serving?
    @State private var quantity: Double = 1.0
    @State private var showingFoodDetail = false
    @State private var showingAddMeal = false
    @State private var showingSuccessAlert = false
    @State private var searchTimer: Timer?
    
    private var searchResults: [Food] {
        return nutritionixService.searchResults
    }
    
    private var isLoading: Bool {
        return nutritionixService.isLoading
    }
    
    private var errorMessage: String? {
        return nutritionixService.errorMessage
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.backgroundDarkBlue.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    headerSection
                    
                    // Search Section
                    searchSection
                    
                    // Results List
                    resultsList
                }
            }
        }
        .sheet(isPresented: $showingFoodDetail) {
            if let food = selectedFood {
                FoodDetailView(
                    food: food,
                    onMealAdded: {
                        DispatchQueue.main.async {
                            // Önce sheet'i kapat
                            self.showingFoodDetail = false
                            // Sonra alert göster
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                self.showingSuccessAlert = true
                                // Otomatik dismiss kaldırıldı - kullanıcı manuel kapatacak
                            }
                        }
                    }
                )
            }
        }
        .alert("Öğün Eklendi!", isPresented: $showingSuccessAlert) {
            Button("Tamam") { 
                // Alert otomatik kapanır, sayfa açık kalır
            }
        } message: {
            Text("Öğününüz başarıyla günlük beslenme listenize eklendi.")
        }
        .onDisappear {
            // Clean up timer to prevent memory leaks
            searchTimer?.invalidate()
            searchTimer = nil
        }
    }
    
    private var headerSection: some View {
        HStack {
            Button(action: {
                DispatchQueue.main.async {
                    self.dismiss()
                }
            }) {
                Image(systemName: "xmark")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
            
            Spacer()
            
            Text("Öğün Ekle")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Spacer()
            
            // Placeholder for symmetry
            Color.clear
                .frame(width: 44, height: 44)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
    
    private var searchSection: some View {
        VStack(spacing: 15) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                    .font(.system(size: 18))
                
                TextField("Yiyecek ara...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .foregroundColor(.white)
                    .onSubmit {
                        performSearch()
                    }
                    .onChange(of: searchText) { newValue in
                        // Cancel previous timer
                        searchTimer?.invalidate()
                        
                        let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        // Clear results if search text is empty
                        if trimmed.isEmpty {
                            nutritionixService.clearResults()
                            return
                        }
                        
                        // Use instant search for suggestions
                        if trimmed.count >= 2 {
                            // Start instant search for suggestions
                            let delay: TimeInterval = 0.2 // Very fast for suggestions
                            searchTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { _ in
                                performInstantSearch()
                            }
                        } else {
                            // Clear suggestions for short queries
                            nutritionixService.instantSuggestions = []
                        }
                    }
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        nutritionixService.clearResults()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.1))
            .cornerRadius(12)
            
            if isLoading {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    
                    Text("Aranıyor...")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.top, 5)
            }
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.top, 5)
            }
            

        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    private var resultsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if searchText.isEmpty {
                    // Show initial state message
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundColor(.white.opacity(0.3))
                        
                        Text("Yiyecek aramak için yukarıdaki arama kutusunu kullanın")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 60)
                } else if !nutritionixService.instantSuggestions.isEmpty {
                    // Show Nutritionix instant suggestions
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Sonuçlar")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                        
                        ForEach(nutritionixService.instantSuggestions) { suggestion in
                            Button(action: {
                                selectSuggestion(suggestion)
                            }) {
                                HStack {
                                    AsyncImage(url: URL(string: suggestion.photo?.thumb ?? "")) { image in
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    } placeholder: {
                                        Image(systemName: suggestion.type == .common ? "leaf.fill" : "bag.fill")
                                            .foregroundColor(.gray)
                                    }
                                    .frame(width: 40, height: 40)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(suggestion.foodName)
                                            .font(.body)
                                            .foregroundColor(.white)
                                            .multilineTextAlignment(.leading)
                                        
                                        Text(suggestion.type == .common ? "Doğal Yiyecek" : "Markalı Ürün")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                        .font(.caption)
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(12)
                            }
                        }
                    }
                } else if isLoading || nutritionixService.isLoadingSuggestions {
                    // Loading state
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        Text("Aranıyor...")
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.top, 60)
                } else if searchResults.isEmpty && nutritionixService.instantSuggestions.isEmpty {
                    EmptySearchView()
                } else {
                    ForEach(searchResults) { food in
                        FoodRowView(food: food) {
                            selectedFood = food
                            showingFoodDetail = true
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 100)
        }
    }
    
    private func performInstantSearch() {
        debugLog("⚡ [ADDMEAL] Instant search başlatılıyor...")
        debugLog("📝 [ADDMEAL] Arama metni: '\(searchText)'")
        
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            debugLog("❌ [ADDMEAL] Arama metni boş, işlem iptal edildi")
            return
        }
        
        nutritionixService.searchInstant(query: searchText) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let suggestions):
                    debugLog("⚡ [ADDMEAL] \(suggestions.count) öneri alındı")
                case .failure(let error):
                    debugLog("❌ [ADDMEAL] Instant search hatası: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func selectSuggestion(_ suggestion: NutritionixService.NutritionixSuggestion) {
        debugLog("🎯 [ADDMEAL] Öneri seçildi: \(suggestion.foodName)")
        
        // Clear suggestions and show loading
        nutritionixService.instantSuggestions = []
        
        // Get detailed nutrition info
        nutritionixService.getNutritionDetails(for: suggestion) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let food):
                    debugLog("✅ [ADDMEAL] Detay beslenme bilgisi alındı: \(food.foodName)")
                    selectedFood = food
                    showingFoodDetail = true
                case .failure(let error):
                    debugLog("❌ [ADDMEAL] Detay alma hatası: \(error.localizedDescription)")
                    // Fallback to showing suggestion as basic food
                    let basicFood = Food(
                        foodId: suggestion.nixItemId ?? suggestion.tagId ?? UUID().uuidString,
                        foodName: suggestion.foodName,
                        foodType: suggestion.type.rawValue,
                        foodUrl: suggestion.photo?.thumb,
                        brandName: suggestion.type == .common ? "Doğal" : "Markalı",
                        foodDescription: "Detay bilgi alınamadı"
                    )
                    selectedFood = basicFood
                    showingFoodDetail = true
                }
            }
        }
    }
    
    private func performSearch() {
        debugLog("🔍 [ADDMEAL] performSearch çağrıldı")
        debugLog("📝 [ADDMEAL] Arama metni: '\(searchText)'")
        
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { 
            debugLog("❌ [ADDMEAL] Arama metni boş, işlem iptal edildi")
            return 
        }
        
        // Check minimum character requirement for Nutritionix
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count < 3 {
            debugLog("⚠️ [ADDMEAL] Nutritionix minimum 3 karakter gerekli, mevcut: \(trimmed.count)")
            return
        }
        
        debugLog("🚀 [ADDMEAL] Nutritionix araması başlatılıyor...")
        nutritionixService.searchFoods(query: searchText) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let foods):
                    debugLog("✅ [ADDMEAL] Nutritionix başarılı: \(foods.count) sonuç")
                case .failure(let error):
                    debugLog("❌ [ADDMEAL] Nutritionix hatası: \(error.localizedDescription)")
                }
            }
        }
    }
}

#Preview {
    AddMealView()
}
 