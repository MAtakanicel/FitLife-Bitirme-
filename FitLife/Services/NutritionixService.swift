import Foundation
import Combine

class NutritionixService: ObservableObject {
    static let shared = NutritionixService()
    
    // MARK: - API Configuration Nutritionix
    private let appId = ProcessInfo.processInfo.environment["Nutritionix_App_ID"] ?? ""
    private let appKey = ProcessInfo.processInfo.environment["Nutritionix_App_Key"] ?? ""
    private let baseURL = "https://trackapi.nutritionix.com/v2"
    
    // MARK: - Published Properties
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchResults: [Food] = []
    @Published var instantSuggestions: [NutritionixSuggestion] = []
    @Published var isLoadingSuggestions = false
    
    // MARK: - URLSession Configuration
    private lazy var urlSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30.0
        config.timeoutIntervalForResource = 60.0
        config.waitsForConnectivity = true
        config.allowsCellularAccess = true
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        return URLSession(configuration: config)
    }()
    
    private init() {}
    
    // MARK: - Models
    
    // Simple suggestion model for instant search
    struct NutritionixSuggestion: Codable, Identifiable {
        let id = UUID()
        let foodName: String
        let photo: NutritionixPhoto?
        let type: SuggestionType
        let nixItemId: String?
        let tagId: String?
        
        enum SuggestionType: String, Codable {
            case common = "common"
            case branded = "branded"
        }
        
        private enum CodingKeys: String, CodingKey {
            case foodName = "food_name"
            case photo
            case nixItemId = "nix_item_id"
            case tagId = "tag_id"
        }
        
        // Custom decoder to handle type determination
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            foodName = try container.decode(String.self, forKey: .foodName)
            photo = try container.decodeIfPresent(NutritionixPhoto.self, forKey: .photo)
            nixItemId = try container.decodeIfPresent(String.self, forKey: .nixItemId)
            tagId = try container.decodeIfPresent(String.self, forKey: .tagId)
            
            // Determine type based on which ID is present
            if nixItemId != nil {
                type = .branded
            } else {
                type = .common
            }
        }
    }
    
    struct NutritionixInstantResponse: Codable {
        let common: [NutritionixSuggestion]
        let branded: [NutritionixSuggestion]
    }
    
    struct NutritionixSearchResponse: Codable {
        let common: [NutritionixCommonFood]?
        let branded: [NutritionixBrandedFood]?
    }
    
    struct NutritionixCommonFood: Codable, Identifiable {
        let foodName: String
        let servingUnit: String?
        let tagName: String?
        let servingQty: Double?
        let commonType: Int?
        let tagId: String?
        let photo: NutritionixPhoto?
        let locale: String?
        
        var id: String {
            return tagId ?? foodName
        }
        
        // Convert to Food model
        var asFood: Food {
            let description = "Doğal yiyecek | Porsiyon: \(servingQty ?? 1) \(servingUnit ?? "adet")"
            
            return Food(
                foodId: tagId,
                foodName: foodName,
                foodType: "nutritionix_common",
                foodUrl: photo?.thumb,
                brandName: "Doğal",
                foodDescription: description
            )
        }
        
        private enum CodingKeys: String, CodingKey {
            case foodName = "food_name"
            case servingUnit = "serving_unit"
            case tagName = "tag_name"
            case servingQty = "serving_qty"
            case commonType = "common_type"
            case tagId = "tag_id"
            case photo, locale
        }
    }
    
    struct NutritionixBrandedFood: Codable, Identifiable {
        let foodName: String
        let servingUnit: String?
        let nfCalories: Double?
        let nfServingSize: Double?
        let nfServingSizeUnit: String?
        let brandName: String?
        let brandNameItemName: String?
        let brandType: Int?
        let nixBrandId: String?
        let nixItemId: String?
        let photo: NutritionixPhoto?
        let locale: String?
        
        var id: String {
            return nixItemId ?? "\(brandName ?? "")_\(foodName)"
        }
        
        // Convert to Food model
        var asFood: Food {
            var description = "Markalı ürün"
            if let calories = nfCalories {
                description += " | Kalori: \(Int(calories))"
            }
            if let servingSize = nfServingSize, let unit = nfServingSizeUnit {
                description += " | Porsiyon: \(servingSize) \(unit)"
            }
            
            return Food(
                foodId: nixItemId,
                foodName: brandNameItemName ?? foodName,
                foodType: "nutritionix_branded",
                foodUrl: photo?.thumb,
                brandName: brandName,
                foodDescription: description
            )
        }
        
        private enum CodingKeys: String, CodingKey {
            case foodName = "food_name"
            case servingUnit = "serving_unit"
            case nfCalories = "nf_calories"
            case nfServingSize = "nf_serving_size"
            case nfServingSizeUnit = "nf_serving_size_unit"
            case brandName = "brand_name"
            case brandNameItemName = "brand_name_item_name"
            case brandType = "brand_type"
            case nixBrandId = "nix_brand_id"
            case nixItemId = "nix_item_id"
            case photo, locale
        }
    }
    
    struct NutritionixPhoto: Codable {
        let thumb: String?
        let highres: String?
    }
    
    // MARK: - Natural Language Nutrition API Models
    
    struct NutritionixNutritionResponse: Codable {
        let foods: [NutritionixNutritionFood]
    }
    
    struct NutritionixNutritionFood: Codable {
        let foodName: String
        let brandName: String?
        let servingQty: Double
        let servingUnit: String
        let servingWeightGrams: Double?
        let nfCalories: Double
        let nfTotalFat: Double?
        let nfSaturatedFat: Double?
        let nfCholesterol: Double?
        let nfSodium: Double?
        let nfTotalCarbohydrate: Double?
        let nfDietaryFiber: Double?
        let nfSugars: Double?
        let nfProtein: Double?
        let nfPotassium: Double?
        let nfP: Double?
        let fullNutrients: [NutritionixNutrient]?
        let photo: NutritionixPhoto?
        
        // Convert to Food model with nutrition data
        var asFood: Food {
            // Format nutrition data exactly as Food model expects
            var description = "Calories: \(Int(nfCalories))"
            
            if let carbs = nfTotalCarbohydrate {
                description += " | Carbs: \(carbs)g"
            }
            if let protein = nfProtein {
                description += " | Protein: \(protein)g"
            }
            if let fat = nfTotalFat {
                description += " | Fat: \(fat)g"
            }
            
            // Add additional info
            if let brand = brandName {
                description += " | Marka: \(brand)"
            }
            description += " | Porsiyon: \(servingQty) \(servingUnit)"
            
            // Create servings array with nutrition data
            let _ = Serving(
                servingId: "1",
                servingDescription: "\(servingQty) \(servingUnit)",
                servingUrl: photo?.thumb,
                metricServingAmount: servingWeightGrams?.description,
                metricServingUnit: "g",
                numberOfUnits: servingQty.description,
                measurementDescription: servingUnit,
                calories: nfCalories.description,
                carbohydrate: nfTotalCarbohydrate?.description,
                protein: nfProtein?.description,
                fat: nfTotalFat?.description,
                saturatedFat: nfSaturatedFat?.description,
                polyunsaturatedFat: nil,
                monounsaturatedFat: nil,
                transFat: nil,
                cholesterol: nfCholesterol?.description,
                sodium: nfSodium?.description,
                potassium: nfPotassium?.description,
                fiber: nfDietaryFiber?.description,
                sugar: nfSugars?.description,
                vitaminA: nil,
                vitaminC: nil,
                calcium: nil,
                iron: nil
            )
            
            return Food(
                foodId: UUID().uuidString,
                foodName: foodName,
                foodType: "nutritionix_nutrition",
                foodUrl: photo?.thumb,
                brandName: brandName ?? "Doğal",
                foodDescription: description
            )
        }
        
        // Convert to Serving model
        var asServing: Serving {
            return Serving(
                servingId: "1",
                servingDescription: "\(servingQty) \(servingUnit)",
                servingUrl: photo?.thumb,
                metricServingAmount: servingWeightGrams?.description,
                metricServingUnit: "g",
                numberOfUnits: servingQty.description,
                measurementDescription: servingUnit,
                calories: nfCalories.description,
                carbohydrate: nfTotalCarbohydrate?.description,
                protein: nfProtein?.description,
                fat: nfTotalFat?.description,
                saturatedFat: nfSaturatedFat?.description,
                polyunsaturatedFat: nil,
                monounsaturatedFat: nil,
                transFat: nil,
                cholesterol: nfCholesterol?.description,
                sodium: nfSodium?.description,
                potassium: nfPotassium?.description,
                fiber: nfDietaryFiber?.description,
                sugar: nfSugars?.description,
                vitaminA: nil,
                vitaminC: nil,
                calcium: nil,
                iron: nil
            )
        }
        
        private enum CodingKeys: String, CodingKey {
            case foodName = "food_name"
            case brandName = "brand_name"
            case servingQty = "serving_qty"
            case servingUnit = "serving_unit"
            case servingWeightGrams = "serving_weight_grams"
            case nfCalories = "nf_calories"
            case nfTotalFat = "nf_total_fat"
            case nfSaturatedFat = "nf_saturated_fat"
            case nfCholesterol = "nf_cholesterol"
            case nfSodium = "nf_sodium"
            case nfTotalCarbohydrate = "nf_total_carbohydrate"
            case nfDietaryFiber = "nf_dietary_fiber"
            case nfSugars = "nf_sugars"
            case nfProtein = "nf_protein"
            case nfPotassium = "nf_potassium"
            case nfP = "nf_p"
            case fullNutrients = "full_nutrients"
            case photo
        }
    }
    
    struct NutritionixNutrient: Codable {
        let attrId: Int
        let value: Double
        
        private enum CodingKeys: String, CodingKey {
            case attrId = "attr_id"
            case value
        }
    }
    
    // MARK: - Error Types
    
    enum NutritionixError: LocalizedError {
        case invalidURL
        case invalidAPIKey
        case networkError(Error)
        case decodingError(Error)
        case apiError(Int, String)
        case unknownError
        
        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Geçersiz URL"
            case .invalidAPIKey:
                return "Geçersiz API Key. Lütfen Nutritionix API Key'inizi kontrol edin."
            case .networkError(let error):
                return "Ağ hatası: \(error.localizedDescription)"
            case .decodingError(let error):
                return "Veri işleme hatası: \(error.localizedDescription)"
            case .apiError(let code, let message):
                return "API Hatası (\(code)): \(message)"
            case .unknownError:
                return "Bilinmeyen hata"
            }
        }
    }
    
    // MARK: - API Methods
    
    // INSTANT SEARCH - Fast suggestions for autocomplete
    func searchInstant(query: String, completion: @escaping (Result<[NutritionixSuggestion], Error>) -> Void) {
        print("⚡ [NUTRITIONIX] Instant search başlatılıyor...")
        print("📝 [NUTRITIONIX] Query: '\(query)'")
        
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedQuery.isEmpty else {
            print("❌ [NUTRITIONIX] Hata: Arama metni boş")
            completion(.success([]))
            return
        }
        
        // Minimum 2 karakter yeterli instant search için
        guard trimmedQuery.count >= 2 else {
            print("⚠️ [NUTRITIONIX] Instant search için en az 2 karakter gerekli")
            DispatchQueue.main.async {
                self.instantSuggestions = []
            }
            completion(.success([]))
            return
        }
        
        guard appId != "YOUR_APP_ID_HERE" && appKey != "YOUR_APP_KEY_HERE" else {
            print("❌ [NUTRITIONIX] Hata: API Key yapılandırılmamış")
            completion(.failure(NutritionixError.invalidAPIKey))
            return
        }
        
        DispatchQueue.main.async {
            self.isLoadingSuggestions = true
        }
        
        let encodedQuery = trimmedQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        var components = URLComponents(string: "\(baseURL)/search/instant")
        components?.queryItems = [
            URLQueryItem(name: "query", value: encodedQuery),
            URLQueryItem(name: "common", value: "true"),
            URLQueryItem(name: "branded", value: "true"),
            URLQueryItem(name: "self", value: "false"),
            URLQueryItem(name: "detailed", value: "false") // Hızlı olması için detay istemiyoruz
        ]
        
        guard let url = components?.url else {
            print("❌ [NUTRITIONIX] Geçersiz URL")
            DispatchQueue.main.async {
                self.isLoadingSuggestions = false
            }
            completion(.failure(NutritionixError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 10.0 // Hızlı timeout
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(appId, forHTTPHeaderField: "x-app-id")
        request.setValue(appKey, forHTTPHeaderField: "x-app-key")
        
        let task = urlSession.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoadingSuggestions = false
                
                if let error = error {
                    print("❌ [NUTRITIONIX] Instant search hatası: \(error.localizedDescription)")
                    completion(.failure(NutritionixError.networkError(error)))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                    let errorMessage = data.flatMap { String(data: $0, encoding: .utf8) } ?? "Unknown error"
                    print("❌ [NUTRITIONIX] Instant API Error: \(statusCode) - \(errorMessage)")
                    completion(.failure(NutritionixError.apiError(statusCode, errorMessage)))
                    return
                }
                
                guard let data = data else {
                    print("❌ [NUTRITIONIX] Boş data")
                    completion(.failure(NutritionixError.unknownError))
                    return
                }
                
                do {
                    let response = try JSONDecoder().decode(NutritionixInstantResponse.self, from: data)
                    var suggestions: [NutritionixSuggestion] = []
                    
                    // Common foods'u ekle (en fazla 5 tane)
                    let commonSuggestions = response.common.prefix(5)
                    suggestions.append(contentsOf: commonSuggestions)
                    
                    // Branded foods'u ekle (en fazla 5 tane)
                    let brandedSuggestions = response.branded.prefix(5)
                    suggestions.append(contentsOf: brandedSuggestions)
                    
                    print("⚡ [NUTRITIONIX] \(suggestions.count) öneri alındı (Common: \(response.common.count), Branded: \(response.branded.count))")
                    
                    self?.instantSuggestions = suggestions
                    completion(.success(suggestions))
                } catch {
                    print("❌ [NUTRITIONIX] Instant search decode hatası: \(error)")
                    completion(.failure(NutritionixError.decodingError(error)))
                }
            }
        }
        
        task.resume()
    }
    

    
   
    func searchFoods(query: String, completion: @escaping (Result<[Food], Error>) -> Void) {
        print("🥗 [NUTRITIONIX] Yiyecek araması başlatılıyor...")
        print("📝 [NUTRITIONIX] Arama terimi: '\(query)'")
        
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedQuery.isEmpty else {
            print("❌ [NUTRITIONIX] Hata: Arama metni boş")
            completion(.failure(NutritionixError.invalidURL))
            return
        }
        
        // Nutritionix API minimum 3 karakter gerektirir
        guard trimmedQuery.count >= 3 else {
            print("⚠️ [NUTRITIONIX] Uyarı: En az 3 karakter gerekli, mevcut: \(trimmedQuery.count)")
            DispatchQueue.main.async {
                self.errorMessage = "En az 3 karakter yazın"
                self.searchResults = []
            }
            completion(.success([]))
            return
        }
        
        guard appId != "YOUR_APP_ID_HERE" && appKey != "YOUR_APP_KEY_HERE" else {
            print("❌ [NUTRITIONIX] Hata: API Key yapılandırılmamış")
            DispatchQueue.main.async {
                self.errorMessage = "Nutritionix API Key yapılandırılmamış. Lütfen API Key'lerinizi ekleyin."
            }
            completion(.failure(NutritionixError.invalidAPIKey))
            return
        }
        
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        // Nutritionix'te beslenme bilgisi almak için natural/nutrients endpoint'ini kullanıyoruz
        getNutritionInfo(query: query, completion: completion)
    }
    
  
    private func getNutritionInfo(query: String, completion: @escaping (Result<[Food], Error>) -> Void) {
        print("📊 [NUTRITIONIX] Beslenme bilgisi alınıyor...")
        print("📝 [NUTRITIONIX] Query: '\(query)'")
        
        let url = URL(string: "\(baseURL)/natural/nutrients")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(appId, forHTTPHeaderField: "x-app-id")
        request.setValue(appKey, forHTTPHeaderField: "x-app-key")
        
        let body = ["query": query]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        print("🌐 [NUTRITIONIX] URL: \(url.absoluteString)")
        print("📤 [NUTRITIONIX] POST Request başlatılıyor...")
        
        let task = urlSession.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    print("❌ [NUTRITIONIX] Network hatası: \(error.localizedDescription)")
                    self?.errorMessage = error.localizedDescription
                    completion(.failure(NutritionixError.networkError(error)))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("❌ [NUTRITIONIX] Geçersiz response")
                    completion(.failure(NutritionixError.unknownError))
                    return
                }
                
                print("🔍 [NUTRITIONIX] HTTP Status: \(httpResponse.statusCode)")
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    let errorMessage = data.flatMap { String(data: $0, encoding: .utf8) } ?? "Unknown error"
                    print("❌ [NUTRITIONIX] API Error: \(httpResponse.statusCode) - \(errorMessage)")
                    self?.errorMessage = "API Error: \(errorMessage)"
                    completion(.failure(NutritionixError.apiError(httpResponse.statusCode, errorMessage)))
                    return
                }
                
                guard let data = data else {
                    print("❌ [NUTRITIONIX] Boş data")
                    completion(.failure(NutritionixError.unknownError))
                    return
                }
                
                print("📦 [NUTRITIONIX] Data alındı: \(data.count) bytes")
                
            
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("📄 [NUTRITIONIX] Raw JSON (ilk 1000 karakter):")
                    print(String(jsonString.prefix(1000)))
                }
                
                do {
                    let response = try JSONDecoder().decode(NutritionixNutritionResponse.self, from: data)
                    let foods = response.foods.map { $0.asFood }
                    
                    print("🎉 [NUTRITIONIX] \(foods.count) yiyecek beslenme bilgisiyle dönüştürüldü")
                    
                    // Her yiyecek için beslenme bilgilerini logla
                    for food in foods {
                        print("🍎 [NUTRITIONIX] Yiyecek: \(food.foodName)")
                        if let calories = food.totalCalories {
                            print("   🔥 Kalori: \(calories)")
                        }
                        if let protein = food.totalProtein {
                            print("   🥩 Protein: \(protein)g")
                        }
                        if let carbs = food.totalCarbs {
                            print("   🍞 Karbonhidrat: \(carbs)g")
                        }
                        if let fat = food.totalFat {
                            print("   🥑 Yağ: \(fat)g")
                        }
                    }
                    
                    self?.searchResults = foods
                    completion(.success(foods))
                } catch {
                    print("❌ [NUTRITIONIX] JSON decode hatası: \(error)")
                    self?.errorMessage = "Veri işleme hatası: \(error.localizedDescription)"
                    completion(.failure(NutritionixError.decodingError(error)))
                }
            }
        }
        
        task.resume()
        print("🚀 [NUTRITIONIX] URLSessionDataTask başlatıldı")
    }
    
    private func searchFoodsSimple(query: String, completion: @escaping (Result<[Food], Error>) -> Void) {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        var components = URLComponents(string: "\(baseURL)/search/instant")
        components?.queryItems = [
            URLQueryItem(name: "query", value: encodedQuery),
            URLQueryItem(name: "common", value: "true"),
            URLQueryItem(name: "branded", value: "true"),
            URLQueryItem(name: "self", value: "false"),
            URLQueryItem(name: "detailed", value: "true")
        ]
        
        guard let url = components?.url else {
            print("❌ [NUTRITIONIX] Geçersiz URL")
            DispatchQueue.main.async {
                self.isLoading = false
                completion(.failure(NutritionixError.invalidURL))
            }
            return
        }
        
        print("🌐 [NUTRITIONIX] URL: \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 30.0
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("FitLife-iOS/1.0", forHTTPHeaderField: "User-Agent")
        request.setValue(appId, forHTTPHeaderField: "x-app-id")
        request.setValue(appKey, forHTTPHeaderField: "x-app-key")
        
        print("📤 [NUTRITIONIX] HTTP Request başlatılıyor...")
        
        let task = urlSession.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    print("❌ [NUTRITIONIX] Network hatası: \(error.localizedDescription)")
                    self?.errorMessage = error.localizedDescription
                    completion(.failure(NutritionixError.networkError(error)))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("❌ [NUTRITIONIX] Geçersiz response")
                    completion(.failure(NutritionixError.unknownError))
                    return
                }
                
                print("🔍 [NUTRITIONIX] HTTP Status: \(httpResponse.statusCode)")
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    let errorMessage = data.flatMap { String(data: $0, encoding: .utf8) } ?? "Unknown error"
                    print("❌ [NUTRITIONIX] API Error: \(httpResponse.statusCode) - \(errorMessage)")
                    completion(.failure(NutritionixError.apiError(httpResponse.statusCode, errorMessage)))
                    return
                }
                
                guard let data = data else {
                    print("❌ [NUTRITIONIX] Boş data")
                    completion(.failure(NutritionixError.unknownError))
                    return
                }
                
                print("📦 [NUTRITIONIX] Data alındı: \(data.count) bytes")
                
             
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("📄 [NUTRITIONIX] Raw JSON (ilk 500 karakter):")
                    print(String(jsonString.prefix(500)))
                }
                
                do {
                    let response = try JSONDecoder().decode(NutritionixSearchResponse.self, from: data)
                    
                    var allFoods: [Food] = []
                    
                   
                    if let commonFoods = response.common {
                        let foods = commonFoods.map { $0.asFood }
                        allFoods.append(contentsOf: foods)
                        print("🥗 [NUTRITIONIX] \(foods.count) doğal yiyecek dönüştürüldü")
                    }
                    
                    
                    if let brandedFoods = response.branded {
                        let foods = brandedFoods.map { $0.asFood }
                        allFoods.append(contentsOf: foods)
                        print("🏷️ [NUTRITIONIX] \(foods.count) markalı ürün dönüştürüldü")
                    }
                    
                    print("🎉 [NUTRITIONIX] Toplam \(allFoods.count) yiyecek bulundu")
                    
                    self?.searchResults = allFoods
                    completion(.success(allFoods))
                } catch {
                    print("❌ [NUTRITIONIX] JSON decode hatası: \(error)")
                    completion(.failure(NutritionixError.decodingError(error)))
                }
            }
        }
        
        task.resume()
        print("🚀 [NUTRITIONIX] URLSessionDataTask başlatıldı")
    }
    
   
    func getNutrition(query: String, completion: @escaping (Result<[Serving], Error>) -> Void) {
        print("📊 [NUTRITIONIX] Beslenme bilgisi alınıyor...")
        print("📝 [NUTRITIONIX] Query: '\(query)'")
        
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            completion(.failure(NutritionixError.invalidURL))
            return
        }
        
        guard appId != "YOUR_APP_ID_HERE" && appKey != "YOUR_APP_KEY_HERE" else {
            completion(.failure(NutritionixError.invalidAPIKey))
            return
        }
        
        let url = URL(string: "\(baseURL)/natural/nutrients")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(appId, forHTTPHeaderField: "x-app-id")
        request.setValue(appKey, forHTTPHeaderField: "x-app-key")
        
        let body = ["query": query]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        let task = urlSession.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(NutritionixError.networkError(error)))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                let errorMessage = data.flatMap { String(data: $0, encoding: .utf8) } ?? "Unknown error"
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                completion(.failure(NutritionixError.apiError(statusCode, errorMessage)))
                return
            }
            
            guard let data = data else {
                completion(.failure(NutritionixError.unknownError))
                return
            }
            
            do {
                let response = try JSONDecoder().decode(NutritionixNutritionResponse.self, from: data)
                let servings = response.foods.map { $0.asServing }
                completion(.success(servings))
            } catch {
                completion(.failure(NutritionixError.decodingError(error)))
            }
        }
        
        task.resume()
    }
    
   
    func getNutritionDetails(for suggestion: NutritionixSuggestion, completion: @escaping (Result<Food, Error>) -> Void) {
        print("📊 [NUTRITIONIX] Detay beslenme bilgisi alınıyor...")
        print("📝 [NUTRITIONIX] Suggestion: '\(suggestion.foodName)'")
        
       
        let query: String
        if suggestion.type == .branded {
            query = "1 serving \(suggestion.foodName)"
        } else {
            query = "1 medium \(suggestion.foodName)"
        }
        
       
        getNutritionInfo(query: query) { result in
            switch result {
            case .success(let foods):
                if let firstFood = foods.first {
                    completion(.success(firstFood))
                } else {
                    completion(.failure(NutritionixError.unknownError))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    
    func clearResults() {
        DispatchQueue.main.async {
            self.searchResults = []
            self.instantSuggestions = []
            self.errorMessage = nil
            self.isLoading = false
            self.isLoadingSuggestions = false
        }
    }
}   
