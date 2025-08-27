import SwiftUI

struct MealManagementView: View {
    @ObservedObject private var mealService = MealService.shared
    @State private var showAddMeal = false
    @State private var selectedMealType: MealData.MealType = .breakfast
    
    var body: some View {
        ZStack {
            Color.backgroundDarkBlue.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Öğün seçici segmented control
                VStack(spacing: 16) {
                    Text("Öğün Türü Seç")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Picker("Öğün Türü", selection: $selectedMealType) {
                                            Text("Kahvaltı").tag(MealData.MealType.breakfast)
                    Text("Öğle").tag(MealData.MealType.lunch)
                    Text("Akşam").tag(MealData.MealType.dinner)
                    Text("Atıştırmalık").tag(MealData.MealType.snack)
                    }
                    .pickerStyle(.segmented)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
                }
                .padding()
                
                // Öğün listesi
                ScrollView {
                    LazyVStack(spacing: 12) {
                        let mealsForType = mealService.todaysMeals.filter { $0.mealType == selectedMealType }
                        
                        if mealsForType.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "fork.knife.circle")
                                    .font(.system(size: 60))
                                    .foregroundColor(.white.opacity(0.3))
                                
                                Text("Henüz \(mealTypeName(selectedMealType)) eklenmedi")
                                    .font(.headline)
                                    .foregroundColor(.white.opacity(0.7))
                                
                                Text("Alt kısımdaki \"Öğün Ekle\" butonunu kullanarak yeni öğün ekleyebilirsiniz")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.5))
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.top, 60)
                        } else {
                            ForEach(mealsForType) { meal in
                                MealRowView(meal: meal, onDelete: {
                                    deleteMeal(meal)
                                })
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
                
                // Öğün ekle butonu
                Button(action: {
                    showAddMeal = true
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                        
                        Text("Öğün Ekle")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.buttonlightGreen)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
        .navigationTitle("Öğünleri Düzenle")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showAddMeal) {
            AddMealView()
        }
    }
    
    private func mealTypeName(_ type: MealData.MealType) -> String {
        switch type {
        case .breakfast:
            return "kahvaltı"
        case .lunch:
            return "öğle yemeği"
        case .dinner:
            return "akşam yemeği"
        case .snack:
            return "atıştırmalık"
        }
    }
    
    private func deleteMeal(_ meal: MealData) {
        mealService.removeMeal(meal)
    }
}

struct MealRowView: View {
    let meal: MealData
    let onDelete: () -> Void
    @State private var showDeleteAlert = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Öğün ikonu
            ZStack {
                Circle()
                    .fill(mealTypeColor.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: mealTypeIcon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(mealTypeColor)
            }
            
            // Öğün bilgileri
            VStack(alignment: .leading, spacing: 4) {
                Text(meal.foodName)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                HStack(spacing: 16) {
                    Label("\(Int(meal.calories)) kcal", systemImage: "flame.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                    
                    Label("P: \(Int(meal.protein))g", systemImage: "leaf.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                    
                    Label("K: \(Int(meal.carbs))g", systemImage: "square.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    Label("Y: \(Int(meal.fat))g", systemImage: "drop.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                }
            }
            
            Spacer()
            
            // Sil butonu
            Button(action: {
                showDeleteAlert = true
            }) {
                Image(systemName: "trash.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.red)
                    .padding(8)
                    .background(Color.red.opacity(0.2))
                    .clipShape(Circle())
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
        .alert("Öğünü Sil", isPresented: $showDeleteAlert) {
            Button("İptal", role: .cancel) { }
            Button("Sil", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("\(meal.foodName) öğününü silmek istediğinizden emin misiniz?")
        }
    }
    
    private var mealTypeColor: Color {
        switch meal.mealType {
        case .breakfast:
            return .orange
        case .lunch:
            return .green
        case .dinner:
            return .blue
        case .snack:
            return .purple
        }
    }
    
    private var mealTypeIcon: String {
        switch meal.mealType {
        case .breakfast:
            return "sun.max.fill"
        case .lunch:
            return "sun.max.fill"
        case .dinner:
            return "moon.fill"
        case .snack:
            return "heart.fill"
        }
    }
}

#Preview {
    MealManagementView()
}