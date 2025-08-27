import Foundation

// MARK: - ChatGPT API Models
struct ChatGPTRequest: Codable {
    let model: String
    let messages: [ChatGPTMessage]
    let maxTokens: Int
    let temperature: Double
    
    enum CodingKeys: String, CodingKey {
        case model, messages, temperature
        case maxTokens = "max_tokens"
    }
}

struct ChatGPTMessage: Codable {
    let role: String
    let content: String
}

struct ChatGPTResponse: Codable {
    let id: String
    let object: String
    let created: Int
    let model: String
    let choices: [ChatGPTChoice]
    let usage: ChatGPTUsage?
}

struct ChatGPTChoice: Codable {
    let index: Int
    let message: ChatGPTMessage
    let finishReason: String?
    
    enum CodingKeys: String, CodingKey {
        case index, message
        case finishReason = "finish_reason"
    }
}

struct ChatGPTUsage: Codable {
    let promptTokens: Int
    let completionTokens: Int
    let totalTokens: Int
    
    enum CodingKeys: String, CodingKey {
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
        case totalTokens = "total_tokens"
    }
}

// MARK: - ChatGPT Service
struct ChatGPTService {
    private let apiKey = ""
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    
    // Kullanıcının mevcut verilerini al
    private func getUserContext() -> String {
        var context = ""
        
        // Kullanıcı bilgileri
        if let userData = DataStorageService.shared.loadRegistrationData() {
            let age = getAge(from: userData.birthDate)
            let genderText = userData.gender == .male ? "Erkek" : "Kadın"
            let goalText = getGoalText(userData.goal)
            let activityText = getActivityText(userData.activityLevel)
            let bmi = userData.bmi
            let dailyCalories = userData.dailyCalorieNeeds
            
            context += """
            
            KULLANICI BİLGİLERİ:
            - İsim: \(userData.name)
            - Yaş: \(age) yaşında
            - Cinsiyet: \(genderText)
            - Boy: \(Int(userData.height)) cm
            - Mevcut Kilo: \(Int(userData.weight)) kg
            - Hedef Kilo: \(Int(userData.targetWeight)) kg
            - BMI: \(String(format: "%.1f", bmi))
            - Fitness Hedefi: \(goalText)
            - Aktivite Seviyesi: \(activityText)
            - Günlük Kalori İhtiyacı: \(dailyCalories) kcal
            """
        }
        
        // Seçili diyet bilgisi
        if let selectedDiet = SelectedDietService.shared.selectedDiet {
            let dietDescription = DietService.shared.getDietDescription(fileName: selectedDiet.fileName)
            context += """
            
            MEVCUT DİYET:
            - Diyet: \(selectedDiet.name)
            - Açıklama: \(dietDescription)
            - Gün: \(SelectedDietService.shared.currentDay)
            - Bugün Tamamlanan Kalori: \(Int(SelectedDietService.shared.getCompletedCaloriesForToday())) kcal
            - Bugün Hedef Kalori: \(Int(SelectedDietService.shared.getTotalCaloriesForToday())) kcal
            """
        }
        
        // Günlük beslenme verileri
        let mealService = MealService.shared
        if mealService.totalCalories > 0 {
            context += """
            
            BUGÜNKÜ BESİN ALIMI:
            - Toplam Kalori: \(Int(mealService.totalCalories)) kcal
            - Protein: \(Int(mealService.totalProtein))g
            - Karbonhidrat: \(Int(mealService.totalCarbs))g
            - Yağ: \(Int(mealService.totalFat))g
            """
        }
        
        // Egzersiz verileri
        let exerciseService = ExerciseTrackingService.shared
        if exerciseService.totalCaloriesBurnedToday > 0 {
            context += """
            
            BUGÜNKÜ EGZERSİZ:
            - Yakılan Kalori: \(Int(exerciseService.totalCaloriesBurnedToday)) kcal
            - Egzersiz Sayısı: \(exerciseService.todaysExerciseSessions.count)
            """
        }
        
        return context
    }
    
    // Yardımcı fonksiyonlar
    private func getGoalText(_ goal: FitnessGoal) -> String {
        switch goal {
        case .loseWeight:
            return "Kilo Vermek"
        case .gainWeight:
            return "Kilo Almak"
        case .maintainWeight:
            return "Kilonu Korumak"
        case .buildMuscle:
            return "Kas Yapmak"
        case .improveHealth:
            return "Sağlığını İyileştirmek"
        }
    }
    
    private func getActivityText(_ activity: ActivityLevel) -> String {
        switch activity {
        case .sedentary:
            return "Hareketsiz (Masa başı iş)"
        case .lightlyActive:
            return "Hafif Aktif (Haftada 1-3 gün egzersiz)"
        case .moderatelyActive:
            return "Orta Düzey Aktif (Haftada 3-5 gün egzersiz)"
        case .veryActive:
            return "Çok Aktif (Haftada 6-7 gün egzersiz)"
        case .extraActive:
            return "Aşırı Aktif (Günde 2 kez egzersiz)"
        }
    }
    
    // Sistem prompt'u - fitness asistanı olarak davranması için
    private func getSystemPrompt() -> String {
        let userContext = getUserContext()
        
        return """
        Sen FitLife uygulamasının AI fitness asistanısın. Kullanıcılara fitness, beslenme, diyet ve sağlıklı yaşam konularında yardımcı oluyorsun.
        
        Özellikle şu konularda uzmanlaşmışsın:
        - Diyet planları (Keto, Akdeniz, Vegan, Paleo, Yüksek Protein, Aralıklı Oruç)
        - Egzersiz programları ve fitness tavsiyeleri
        - Kalori hesaplama ve makro besin takibi
        - Sağlıklı yaşam önerileri
        - Motivasyon ve hedef belirleme
        
        Yanıtların her zaman:
        - Türkçe olmalı
        - Kısa ve öz olmalı (maksimum 200 kelime)
        - Dostane ve motive edici bir tonda olmalı
        - Bilimsel ve güvenilir bilgiler içermeli
        - Kullanıcının mevcut durumunu dikkate almalı
        - Gerektiğinde FitLife uygulamasının özelliklerini referans almalı
        
        ÖNEMLI: Aşağıdaki kullanıcı bilgilerini kullanarak kişiselleştirilmiş öneriler sun:
        \(userContext)
        
        Eğer medikal tavsiye isterlerse, mutlaka bir sağlık uzmanına danışmalarını söyle.
        """
    }

    func sendMessage(_ message: String, conversationHistory: [ChatMessage] = []) async throws -> String {
        guard let url = URL(string: baseURL) else {
            throw ChatGPTError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Conversation history'yi ChatGPT formatına çevir
        var messages: [ChatGPTMessage] = [
            ChatGPTMessage(role: "system", content: getSystemPrompt())
        ]
        
        // Son 10 mesajı ekle (token limitini aşmamak için)
        let recentHistory = Array(conversationHistory.suffix(10))
        for chatMessage in recentHistory {
            let role = chatMessage.isUser ? "user" : "assistant"
            messages.append(ChatGPTMessage(role: role, content: chatMessage.content))
        }
        
        // Yeni kullanıcı mesajını ekle
        messages.append(ChatGPTMessage(role: "user", content: message))
        
        let requestBody = ChatGPTRequest(
            model: "gpt-4o",
            messages: messages,
            maxTokens: 400,
            temperature: 0.7
        )
        
        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
        } catch {
            throw ChatGPTError.encodingError
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ChatGPTError.invalidResponse
            }
            
            if httpResponse.statusCode == 401 {
                throw ChatGPTError.unauthorized
            } else if httpResponse.statusCode == 429 {
                throw ChatGPTError.rateLimitExceeded
            } else if httpResponse.statusCode != 200 {
                throw ChatGPTError.httpError(httpResponse.statusCode)
            }
            
            let chatGPTResponse = try JSONDecoder().decode(ChatGPTResponse.self, from: data)
            
            guard let firstChoice = chatGPTResponse.choices.first else {
                throw ChatGPTError.noResponse
            }
            
            return firstChoice.message.content
            
        } catch let error as ChatGPTError {
            throw error
        } catch {
            throw ChatGPTError.networkError(error)
        }
    }
}

// MARK: - ChatGPT Errors
enum ChatGPTError: LocalizedError {
    case invalidURL
    case encodingError
    case invalidResponse
    case unauthorized
    case rateLimitExceeded
    case httpError(Int)
    case noResponse
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Geçersiz URL"
        case .encodingError:
            return "Veri kodlama hatası"
        case .invalidResponse:
            return "Geçersiz yanıt"
        case .unauthorized:
            return "API anahtarı geçersiz"
        case .rateLimitExceeded:
            return "API limit aşıldı. Lütfen daha sonra tekrar deneyin."
        case .httpError(let code):
            return "HTTP hatası: \(code)"
        case .noResponse:
            return "AI'dan yanıt alınamadı"
        case .networkError(let error):
            return "Ağ hatası: \(error.localizedDescription)"
        }
    }
} 
