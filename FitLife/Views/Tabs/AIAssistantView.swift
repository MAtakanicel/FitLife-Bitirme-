import SwiftUI
import Combine

// MARK: - Recommendation Models

struct RecommendationItem: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let type: RecommendationType
    let calories: Int
    let duration: String
    let exerciseProgram: ExerciseProgram? // Gerçek egzersiz programı
    let dietName: String? // Diyet adı
}

enum RecommendationType {
    case exercise
    case diet
    
    var icon: String {
        switch self {
        case .exercise:
            return "dumbbell.fill"
        case .diet:
            return "fork.knife"
        }
    }
    
    var color: Color {
        switch self {
        case .exercise:
            return AppColors.accentYellow
        case .diet:
            return AppColors.primaryGreen
        }
    }
}

// MARK: - Diet Info View
struct DietInfoView: View {
    let dietName: String
    @Environment(\.dismiss) private var dismiss
    private let dietService = DietService.shared
    @ObservedObject private var selectedDietService = SelectedDietService.shared
    @State private var showingAlert = false
    @State private var dietData: DietDataResponse?
    
    var body: some View {
        ZStack {
            Color.backgroundDarkBlue.ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Header
                headerView
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Diyet Açıklaması
                        descriptionView
                        
                        // Diyet Bilgileri
                        if let data = dietData {
                            detailsView(data)
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
                
                // Diyet Seç Butonu
                selectDietButton
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            loadDietData()
        }
        .alert("Diyet Seçildi", isPresented: $showingAlert) {
            Button("Tamam", role: .cancel) { 
                dismiss()
            }
            .foregroundColor(AppColors.primaryGreen)
        } message: {
            Text("\(getDietDisplayName(dietName)) diyetiniz başarıyla seçildi!")
        }
    }
    
    private var headerView: some View {
        HStack {
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            Text(getDietDisplayName(dietName))
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Spacer()
            
            Button(action: {}) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(.clear)
            }
        }
        .padding(.horizontal)
    }
    
    private var descriptionView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Diyet Hakkında")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Text(dietService.getDietDescription(fileName: dietName))
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(nil)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white.opacity(0.1))
        )
    }
    
    private func detailsView(_ data: DietDataResponse) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Diyet Detayları")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Süre")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    Text("\(getDietDuration(dietName)) Gün")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Günlük Öğün")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    Text("\(data.diet.first?.meals.count ?? 0) Öğün")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white.opacity(0.1))
        )
    }
    
    private var selectDietButton: some View {
        Button(action: selectDiet) {
            HStack {
                Image(systemName: "checkmark")
                    .font(.title2)
                Text("Bu Diyeti Seç")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 55)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(isCurrentDiet ? AppColors.primaryGreen.opacity(0.2) : Color.backgroundLightBlue)
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(isCurrentDiet ? AppColors.primaryGreen : Color.clear, lineWidth: 2)
                    )
            )
        }
    }
    
    private var isCurrentDiet: Bool {
        selectedDietService.selectedDiet?.fileName == dietName
    }
    
    private func loadDietData() {
        dietData = dietService.loadDietData(fileName: dietName)
    }
    
    private func selectDiet() {
        guard let data = dietData else { return }
        
        // DietListView'daki DietPlan modeline uygun obje oluştur
        let dietPlan = DietPlan(
            name: data.name ?? getDietDisplayName(dietName),
            description: data.description ?? "",
            image: getDietImage(dietName),
            duration: "\(getDietDuration(dietName)) gün",
            meals: data.diet.first?.meals.count ?? 0,
            calories: Int(data.diet.first?.meals.reduce(0) { $0 + $1.calories } ?? 0),
            difficulty: "Orta",
            category: getDietCategory(dietName),
            fileName: dietName
        )
        
        selectedDietService.selectDiet(dietPlan)
        showingAlert = true
    }
    
    private func getDietImage(_ fileName: String) -> String {
        switch fileName {
        case "Keto":
            return "keto_diet"
        case "Akdeniz":
            return "mediterranean_diet"
        case "high_protein":
            return "high_protein_diet"
        case "paleo":
            return "paleo_diet"
        case "vegan":
            return "vegan_diet"
        case "intermittent_fasting":
            return "intermittent_fasting"
        default:
            return "default_diet"
        }
    }
    
    private func getDietCategory(_ fileName: String) -> String {
        switch fileName {
        case "Keto":
            return "Düşük Karb"
        case "Akdeniz":
            return "Dengeli"
        case "high_protein":
            return "Protein"
        case "paleo":
            return "Doğal"
        case "vegan":
            return "Bitkisel"
        case "intermittent_fasting":
            return "Aralıklı"
        default:
            return "Diğer"
        }
    }
    
    private func getDietDisplayName(_ fileName: String) -> String {
        switch fileName {
        case "Keto":
            return "Ketojenik Diyet"
        case "Akdeniz":
            return "Akdeniz Diyeti"
        case "high_protein":
            return "Yüksek Protein Diyeti"
        case "paleo":
            return "Paleo Diyet"
        case "vegan":
            return "Vegan Diyet"
        case "intermittent_fasting":
            return "Aralıklı Oruç"
        default:
            return fileName
        }
    }
    
    private func getDietDuration(_ fileName: String) -> Int {
        return dietService.getMaxDayCount(fileName: fileName)
    }
}

struct AIAssistantView: View {
    @State private var showingChatBot = false
    @ObservedObject private var exerciseService = ExerciseService.shared
    private let dietService = DietService.shared // Singleton instance kullan
    @State private var selectedExercise: ExerciseProgram?
    @State private var selectedDietName: String?
    @State private var showingExerciseDetail = false
    @State private var showingDietSelection = false
    @State private var exerciseRecommendations: [RecommendationItem] = []
    @State private var dietRecommendations: [RecommendationItem] = []
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundDarkBlue.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Başlık
                        headerView
                        
                        // AI Önerileri
                        recommendationsSection
                        
                        // ChatBot Butonu
                        chatBotButton
                    }
                    .padding()
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                print("🚀 AI Asistan view açıldı, öneriler yükleniyor...")
                loadRecommendationsWithPreload()
            }
            .onReceive(exerciseService.$exercisePrograms) { programs in
                // ExerciseService veri yüklediğinde önerileri güncelle
                if !programs.isEmpty {
                    loadExerciseRecommendations()
                }
            }
            .sheet(isPresented: $showingChatBot) {
                ChatBotView()
            }
            .navigationDestination(isPresented: $showingExerciseDetail) {
                if let exercise = selectedExercise {
                    ExerciseDetailView(program: exercise)
                }
            }
            .navigationDestination(isPresented: $showingDietSelection) {
                if let dietName = selectedDietName {
                    DietInfoView(dietName: dietName)
                }
            }
        }
    }
    
    // MARK: - View Components
    
    private var headerView: some View {
        VStack(spacing: 8) {
            Text("AI Asistan")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Kişiselleştirilmiş öneriler")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
        }
    }
    
    private var recommendationsSection: some View {
        VStack(spacing: 16) {
            // Egzersiz Önerileri
            if !exerciseRecommendations.isEmpty {
                recommendationCategoryView(
                    title: "Egzersiz Önerileri",
                    icon: "dumbbell.fill",
                    color: .orange,
                    items: exerciseRecommendations
                )
            }
            
            // Diyet Önerileri
            if !dietRecommendations.isEmpty {
                recommendationCategoryView(
                    title: "Diyet Önerileri",
                    icon: "fork.knife",
                    color: .green,
                    items: dietRecommendations
                )
            }
            
            // Yükleniyor durumu
            if exerciseService.isLoading || (exerciseRecommendations.isEmpty && dietRecommendations.isEmpty) {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    
                    Text("AI önerileri yükleniyor...")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 100)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.white.opacity(0.1))
                )
            }
        }
    }
    
    private func recommendationCategoryView(
        title: String,
        icon: String,
        color: Color,
        items: [RecommendationItem]
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            LazyVStack(spacing: 8) {
                ForEach(items) { item in
                    recommendationCard(item)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white.opacity(0.1))
        )
    }
    
    private func recommendationCard(_ item: RecommendationItem) -> some View {
        Button(action: {
            handleRecommendationTap(item)
        }) {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(item.type.color.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: item.type.icon)
                        .foregroundColor(item.type.color)
                        .font(.system(size: 16))
                }
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(item.description)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Stats
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(item.calories) kcal")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(item.type.color)
                    
                    Text(item.duration)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.05))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var chatBotButton: some View {
        Button(action: {
            showingChatBot = true
        }) {
            HStack {
                Image(systemName: "message.fill")
                    .font(.title3)
                
                Text("AI Chat")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [AppColors.primaryGreen, Color.backgroundLightBlue]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
        }
    }
    
    // MARK: - Actions
    
    private func handleRecommendationTap(_ item: RecommendationItem) {
        switch item.type {
        case .exercise:
            if let exercise = item.exerciseProgram {
                selectedExercise = exercise
                showingExerciseDetail = true
            }
        case .diet:
            if let dietName = item.dietName {
                selectedDietName = dietName
                showingDietSelection = true
            }
        }
    }
    
    private func loadRecommendations() {
        loadExerciseRecommendations()
        loadDietRecommendations()
    }
    
    private func loadRecommendationsWithPreload() {
        // Önce diyet önerilerini yükle (bunlar hızlı)
        loadDietRecommendations()
        
        // Egzersiz verileri yoksa zorla yükle
        if exerciseService.exercisePrograms.isEmpty {
            print("⚡ Egzersiz verileri bulunamadı, zorla yükleniyor...")
            
            // ExerciseService singleton olduğu için veri paylaşılacak
            exerciseService.loadExercisePrograms()
            
            // Retry mekanizması - 3 kez deneme
            attemptExerciseLoad(retryCount: 0, maxRetries: 3)
        } else {
            // Veriler zaten varsa direkt yükle
            print("✅ Egzersiz verileri mevcut, öneriler hazırlanıyor...")
            loadExerciseRecommendations()
        }
    }
    
    private func attemptExerciseLoad(retryCount: Int, maxRetries: Int) {
        let delay = Double(retryCount) * 0.3 + 0.2 // 0.2, 0.5, 0.8 saniye
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            if !self.exerciseService.exercisePrograms.isEmpty {
                print("✅ Egzersiz verileri yüklendi (retry \(retryCount + 1))")
                self.loadExerciseRecommendations()
            } else if retryCount < maxRetries - 1 {
                print("⏳ Retry \(retryCount + 1)/\(maxRetries) - Egzersiz verileri henüz hazır değil")
                self.attemptExerciseLoad(retryCount: retryCount + 1, maxRetries: maxRetries)
            } else {
                print("❌ Egzersiz verileri \(maxRetries) denemede yüklenemedi")
                // Son çare olarak tekrar yükleme deneme
                self.exerciseService.loadExercisePrograms()
            }
        }
    }
    
    private func loadExerciseRecommendations() {
        // Egzersiz programları yüklenene kadar bekle
        guard !exerciseService.exercisePrograms.isEmpty else {
            print("⚠️ Egzersiz programları henüz yüklenmedi")
            return
        }
        
        // Kullanıcının fitness hedefine göre önerileri sırala
        let sortedExercises = getSortedExercisesByUserGoal()
        
        // İlk 3 egzersiz programını öneri olarak yükle
        let firstThree = Array(sortedExercises.prefix(3))
        
        exerciseRecommendations = firstThree.map { exercise in
            RecommendationItem(
                title: exercise.title,
                description: exercise.description,
                type: .exercise,
                calories: exercise.estimated_calories,
                duration: "\(calculateDuration(exercise)) dk",
                exerciseProgram: exercise,
                dietName: nil
            )
        }
        
        print("✅ \(exerciseRecommendations.count) egzersiz önerisi yüklendi")
    }
    
    // Kullanıcının fitness hedefine göre egzersiz önerilerini sırala
    private func getSortedExercisesByUserGoal() -> [ExerciseProgram] {
        let userData = DataStorageService.shared.loadRegistrationData()
        let userGoal = userData?.goal ?? .improveHealth
        
        return exerciseService.exercisePrograms.sorted { exercise1, exercise2 in
            let score1 = calculateExerciseScore(exercise1, for: userGoal)
            let score2 = calculateExerciseScore(exercise2, for: userGoal)
            return score1 > score2
        }
    }
    
    // Egzersizin kullanıcının hedefine uygunluk skorunu hesapla
    private func calculateExerciseScore(_ exercise: ExerciseProgram, for goal: FitnessGoal) -> Int {
        var score = 0
        let title = exercise.title.lowercased()
        let description = exercise.description.lowercased()
        
        switch goal {
        case .loseWeight:
            // Kilo vermek için kardiyo ağırlıklı egzersizler
            if title.contains("kardiyo") || title.contains("hiit") || title.contains("tüm vücut") {
                score += 3
            }
            if exercise.estimated_calories > 120 {
                score += 2
            }
        case .buildMuscle:
            // Kas yapmak için kuvvet egzersizleri
            if title.contains("üst vücut") || title.contains("kol") || title.contains("karın") {
                score += 3
            }
            if title.contains("bacak") {
                score += 2
            }
        case .improveHealth, .maintainWeight:
            // Genel sağlık için dengeli egzersizler
            if title.contains("tüm vücut") {
                score += 3
            }
            if exercise.estimated_calories >= 100 && exercise.estimated_calories <= 120 {
                score += 2
            }
        case .gainWeight:
            // Kilo almak için kuvvet egzersizleri
            if title.contains("kol") || title.contains("üst vücut") || title.contains("bacak") {
                score += 3
            }
        }
        
        return score
    }
    
    private func calculateDuration(_ program: ExerciseProgram) -> Int {
        // Egzersizlerin toplam süresini hesapla (saniye cinsinden)
        let totalSeconds = program.exercises.reduce(0) { $0 + $1.duration_sec }
        return totalSeconds / 60 // Dakikaya çevir
    }
    
    private func loadDietRecommendations() {
        // Diyet önerilerini yükle
        let availableDiets = ["Keto", "Akdeniz", "high_protein"]
        
        dietRecommendations = availableDiets.compactMap { dietName in
            let description = dietService.getDietDescription(fileName: dietName)
            let name = dietService.getDietName(fileName: dietName)
            
            // Gerçek kalori verilerini hesapla
            let averageCalories = calculateAverageCalories(for: dietName)
            
            return RecommendationItem(
                title: name,
                description: description,
                type: .diet,
                calories: averageCalories,
                duration: "Günlük",
                exerciseProgram: nil,
                dietName: dietName
            )
        }
    }
    
    private func calculateAverageCalories(for dietFileName: String) -> Int {
        guard let dietData = dietService.loadDietData(fileName: dietFileName) else {
            return 0
        }
        
        // İlk günün toplam kalorisini hesapla
        if let firstDay = dietData.diet.first {
            let totalCalories = firstDay.meals.reduce(0.0) { total, meal in
                return total + meal.calories
            }
            return Int(totalCalories)
        }
        
        return 0
    }
}

// MARK: - ChatBot View
struct ChatBotView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var messageText = ""
    @State private var messages: [ChatMessage] = []
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.backgroundDarkBlue.ignoresSafeArea()
                
                VStack {
                    // Messages
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(messages) { message in
                                    ChatMessageView(message: message)
                                        .id(message.id)
                                }
                                
                                if isLoading {
                                    HStack {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                        Text("AI düşünüyor...")
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                    .padding()
                                }
                            }
                            .padding()
                        }
                        .onChange(of: messages.count) {
                            if let lastMessage = messages.last {
                                withAnimation {
                                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                    }
                    
                    // Input Area
                    HStack(spacing: 12) {
                        TextField("Mesajınızı yazın...", text: $messageText)
                            .textFieldStyle(CustomTextFieldStyle())
                            .frame(height: 50)
                        
                        Button(action: sendMessage) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "paperplane.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(width: 50, height: 50)
                        .background(
                            Circle()
                                .fill(messageText.isEmpty ? Color.gray : AppColors.primaryGreen)
                        )
                        .disabled(messageText.isEmpty || isLoading)
                    }
                    .padding()
                }
            }
            .navigationTitle("AI Chat")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Kapat") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .onAppear {
            if messages.isEmpty {
                addWelcomeMessage()
            }
        }
    }
    
    private func addWelcomeMessage() {
        let welcomeMessage = ChatMessage(
            content: "Merhaba! Ben FitLife AI asistanınızım. Size fitness ve beslenme konularında yardımcı olabilirim. Nasıl yardımcı olabilirim?",
            isUser: false
        )
        messages.append(welcomeMessage)
    }
    
    private func sendMessage() {
        guard !messageText.isEmpty else { return }
        
        let userMessage = ChatMessage(content: messageText, isUser: true)
        messages.append(userMessage)
        
        let currentMessage = messageText
        messageText = ""
        isLoading = true
        
        Task {
            do {
                let response = try await ChatGPTService().sendMessage(currentMessage)
                
                await MainActor.run {
                    let aiMessage = ChatMessage(content: response, isUser: false)
                    messages.append(aiMessage)
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    let errorMessage = ChatMessage(
                        content: "Üzgünüm, bir hata oluştu. Lütfen tekrar deneyin.",
                        isUser: false
                    )
                    messages.append(errorMessage)
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Chat Message Models
struct ChatMessage: Identifiable {
    let id = UUID()
    let content: String
    let isUser: Bool
}

struct ChatMessageView: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
                
                Text(message.content)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(15)
                    .frame(maxWidth: .infinity * 0.7, alignment: .trailing)
            } else {
                Text(message.content)
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .foregroundColor(.white)
                    .cornerRadius(15)
                    .frame(maxWidth: .infinity * 0.7, alignment: .leading)
                
                Spacer()
            }
        }
    }
}

#Preview {
    AIAssistantView()
} 
