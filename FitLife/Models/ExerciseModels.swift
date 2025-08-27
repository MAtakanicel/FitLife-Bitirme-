import Foundation

// MARK: - Exercise Models
struct Exercise: Identifiable, Codable {
    let id = UUID()
    let name: String
    let reps: String
    let duration_sec: Int
    
    private enum CodingKeys: String, CodingKey {
        case name, reps, duration_sec
    }
}

struct ExerciseProgram: Identifiable, Codable {
    let id = UUID()
    let title: String
    let description: String
    let estimated_calories: Int
    let exercises: [Exercise]
    
    private enum CodingKeys: String, CodingKey {
        case title, description, estimated_calories, exercises
    }
}

// MARK: - Exercise Service
class ExerciseService: ObservableObject {
    static let shared = ExerciseService()
    
    @Published var exercisePrograms: [ExerciseProgram] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private init() {
        loadExercisePrograms()
    }
    
    func loadExercisePrograms() {
        // Zaten yüklenmişse tekrar yükleme
        guard exercisePrograms.isEmpty else {
            print("✅ Egzersiz verileri zaten yüklü")
            return
        }
        
        isLoading = true
        errorMessage = nil
        print("🔄 Egzersiz verileri yükleniyor...")
        
        guard let url = Bundle.main.url(forResource: "egzersiz_modelleri_genisletilmis", withExtension: "json") else {
            DispatchQueue.main.async {
                self.errorMessage = "Egzersiz dosyası bulunamadı"
                self.isLoading = false
                print("❌ Egzersiz JSON dosyası bulunamadı")
            }
            return
        }
        
        // Background thread'de JSON parse et
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let data = try Data(contentsOf: url)
                let programs = try JSONDecoder().decode([ExerciseProgram].self, from: data)
                
                DispatchQueue.main.async {
                    self.exercisePrograms = programs
                    self.isLoading = false
                    print("✅ \(programs.count) egzersiz programı yüklendi")
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Egzersiz verileri yüklenemedi: \(error.localizedDescription)"
                    self.isLoading = false
                    print("❌ Egzersiz verisi parse hatası: \(error)")
                }
            }
        }
    }
} 