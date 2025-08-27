import Foundation
import CoreData

class CoreDataService: ObservableObject {
    static let shared = CoreDataService()
    
    private init() {}
    
    // MARK: - Core Data Stack
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "FitLife")
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                print("❌ CoreData: Critical error loading persistent stores: \(error), \(error.userInfo)")
                
                #if DEBUG
                fatalError("Core Data error in DEBUG: \(error), \(error.userInfo)")
                #else
                // Production'da graceful fallback
                print("🔄 CoreData: Attempting to recover from error...")
                // Error recovery logic can be added here if needed
                #endif
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    // MARK: - Core Data Saving
    func save() {
        if context.hasChanges {
            do {
                try context.save()
                print("✅ CoreData: Data saved successfully")
            } catch {
                print("❌ CoreData: Save error: \(error)")
            }
        }
    }
    
    // MARK: - User Operations
    func createUser(uid: String, name: String, email: String) -> User {
        let user = User(context: context)
        user.uid = uid
        user.name = name
        user.email = email
        user.createdAt = Date()
        user.lastUpdated = Date()
        user.isSynced = false
        save()
        return user
    }
    
    // Güvenli kullanıcı oluşturma/güncelleme - mevcut verileri korur
    func createOrUpdateUser(uid: String, name: String, email: String) -> User {
        // Önce mevcut kullanıcıyı kontrol et
        if let existingUser = fetchUser(uid: uid) {
            // Mevcut kullanıcı varsa sadece temel bilgileri güncelle
            existingUser.name = name
            existingUser.email = email
            existingUser.lastUpdated = Date()
            existingUser.isSynced = false
            save()
            return existingUser
        } else {
            // Mevcut kullanıcı yoksa yeni oluştur
            return createUser(uid: uid, name: name, email: email)
        }
    }
    
    // Kullanıcı verilerini güvenli şekilde güncelle - sadece boş olmayan alanları günceller
    func safeUpdateUser(uid: String, name: String? = nil, email: String? = nil) -> User? {
        guard let user = fetchUser(uid: uid) else {
            print("❌ CoreData: User not found for safe update")
            return nil
        }
        
        // Sadece nil olmayan değerleri güncelle
        if let name = name, !name.isEmpty {
            user.name = name
        }
        
        if let email = email, !email.isEmpty {
            user.email = email
        }
        
        user.lastUpdated = Date()
        user.isSynced = false
        save()
        return user
    }
    
    func fetchUser(uid: String) -> User? {
        let request: NSFetchRequest<User> = User.fetchRequest()
        request.predicate = NSPredicate(format: "uid == %@", uid)
        request.fetchLimit = 1
        
        do {
            let users = try context.fetch(request)
            return users.first
        } catch {
            print("❌ CoreData: Fetch user error: \(error)")
            return nil
        }
    }
    
    func updateUser(uid: String, userData: UserRegistrationModel) {
        guard let user = fetchUser(uid: uid) else {
            print("❌ CoreData: User not found for update")
            return
        }
        
        print("🔄 CoreData: Updating user \(uid)")
        
        user.name = userData.name
        user.email = userData.email
        user.gender = userData.gender.rawValue
        user.birthday = userData.birthDate
        user.height = userData.height
        user.weight = userData.weight
        user.targetWeight = userData.targetWeight
        user.fitnessGoal = userData.goal.rawValue
        user.activityLevel = userData.activityLevel.rawValue
        user.lastUpdated = Date()
        user.isSynced = false
        
        save()
        print("✅ CoreData: User updated successfully")
    }
    
    func deleteUser(uid: String) {
        guard let user = fetchUser(uid: uid) else {
            print("❌ CoreData: User not found for deletion")
            return
        }
        
        context.delete(user)
        save()
    }
    
    func deleteAllUsers() {
        let request: NSFetchRequest<NSFetchRequestResult> = User.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        
        do {
            try context.execute(deleteRequest)
            save()
            print("✅ CoreData: All users deleted")
        } catch {
            print("❌ CoreData: Delete all users error: \(error)")
        }
    }
    
    // Kullanıcı verilerini UserRegistrationModel formatında döndür
    func getUser(uid: String) -> UserRegistrationModel? {
        guard let user = fetchUser(uid: uid) else {
            return nil
        }
        
        // User entity'den UserRegistrationModel'e çevir
        return UserRegistrationModel(
            name: user.name ?? "",
            email: user.email ?? "",
            password: "", // Password CoreData'da saklanmaz
            gender: Gender(rawValue: user.gender ?? "Erkek") ?? .male,
            birthDate: user.birthday ?? Date(),
            height: user.height,
            weight: user.weight,
            targetWeight: user.targetWeight,
            goal: FitnessGoal(rawValue: user.fitnessGoal ?? "Kilo Korumak") ?? .maintainWeight,
            activityLevel: ActivityLevel(rawValue: user.activityLevel ?? "Orta Hareketli") ?? .moderatelyActive
        )
    }
    
    func fetchAllUsers() -> [User] {
        let request: NSFetchRequest<User> = User.fetchRequest()
        
        do {
            return try context.fetch(request)
        } catch {
            print("❌ CoreData: Fetch all users error: \(error)")
            return []
        }
    }

    
    // MARK: - Meal Operations
    
    func saveMeal(userUID: String, foodName: String, calories: Double, protein: Double, carbs: Double, fat: Double, mealType: String, quantity: Double = 1.0, date: Date = Date()) -> MealEntry? {
        print("🔍 CoreData: Attempting to save meal for userUID: \(userUID)")
        
        guard let user = fetchUser(uid: userUID) else {
            print("❌ CoreData: User not found for meal save - userUID: \(userUID)")
            
            // Debug: Tüm kullanıcıları listele
            let allUsers = fetchAllUsers()
            print("🔍 CoreData: Total users in database: \(allUsers.count)")
            for user in allUsers {
                print("   - User: \(user.name ?? "Unknown"), UID: \(user.uid ?? "No UID"), Email: \(user.email ?? "No Email")")
            }
            
            return nil
        }
        
        print("✅ CoreData: User found, saving meal for: \(user.name ?? "Unknown")")
        
        let meal = MealEntry(context: context)
        meal.id = UUID()
        meal.userUID = userUID
        meal.foodName = foodName
        meal.calories = calories
        meal.protein = protein
        meal.carbs = carbs
        meal.fat = fat
        meal.mealType = mealType
        meal.quantity = quantity
        meal.dateAdded = date
        meal.createdAt = Date()
        meal.isSynced = false
        meal.user = user
        
        save()
        return meal
    }
    
    func fetchMeals(for userUID: String, date: Date? = nil) -> [MealEntry] {
        let request: NSFetchRequest<MealEntry> = MealEntry.fetchRequest()
        
        var predicates: [NSPredicate] = [NSPredicate(format: "userUID == %@", userUID)]
        
        if let date = date {
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            predicates.append(NSPredicate(format: "dateAdded >= %@ AND dateAdded < %@", startOfDay as NSDate, endOfDay as NSDate))
        }
        
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        request.sortDescriptors = [NSSortDescriptor(key: "dateAdded", ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("❌ CoreData: Fetch meals error: \(error)")
            return []
        }
    }
    
    func fetchUnsyncedMeals(for userUID: String) -> [MealEntry] {
        let request: NSFetchRequest<MealEntry> = MealEntry.fetchRequest()
        request.predicate = NSPredicate(format: "userUID == %@ AND isSynced == NO", userUID)
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("❌ CoreData: Fetch unsynced meals error: \(error)")
            return []
        }
    }
    
    func markMealAsSynced(meal: MealEntry, firestoreId: String) {
        meal.isSynced = true
        meal.firestoreId = firestoreId
        save()
    }
    
    func deleteMeal(meal: MealEntry) {
        context.delete(meal)
        save()
    }
    
    func deleteMeal(id: UUID) {
        let request: NSFetchRequest<MealEntry> = MealEntry.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        
        do {
            let meals = try context.fetch(request)
            if let meal = meals.first {
                context.delete(meal)
                save()
                print("✅ CoreData: Meal deleted successfully")
            } else {
                print("⚠️ CoreData: Meal not found for deletion")
            }
        } catch {
            print("❌ CoreData: Delete meal error: \(error)")
        }
    }
    
    // MARK: - Weight Entry Operations
    
    func saveWeightEntry(userUID: String, weight: Double, date: Date = Date()) -> WeightEntry? {
        guard let user = fetchUser(uid: userUID) else {
            print("❌ CoreData: User not found for weight save")
            return nil
        }
        
        let weightEntry = WeightEntry(context: context)
        weightEntry.id = UUID()
        weightEntry.userUID = userUID
        weightEntry.weight = weight
        weightEntry.date = date
        weightEntry.createdAt = Date()
        weightEntry.isSynced = false
        weightEntry.user = user
        
        save()
        return weightEntry
    }
    
    func fetchWeightEntries(for userUID: String, limit: Int = 30) -> [WeightEntry] {
        let request: NSFetchRequest<WeightEntry> = WeightEntry.fetchRequest()
        request.predicate = NSPredicate(format: "userUID == %@", userUID)
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        request.fetchLimit = limit
        
        do {
            return try context.fetch(request)
        } catch {
            print("❌ CoreData: Fetch weight entries error: \(error)")
            return []
        }
    }
    
    func fetchUnsyncedWeightEntries(for userUID: String) -> [WeightEntry] {
        let request: NSFetchRequest<WeightEntry> = WeightEntry.fetchRequest()
        request.predicate = NSPredicate(format: "userUID == %@ AND isSynced == NO", userUID)
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("❌ CoreData: Fetch unsynced weight entries error: \(error)")
            return []
        }
    }
    
    func markWeightEntryAsSynced(weightEntry: WeightEntry, firestoreId: String) {
        weightEntry.isSynced = true
        weightEntry.firestoreId = firestoreId
        save()
    }
    
    func deleteWeightEntry(weightEntry: WeightEntry) {
        context.delete(weightEntry)
        save()
    }
    
    // MARK: - Sync Status Operations
    
    func markUserAsSynced(uid: String) {
        guard let user = fetchUser(uid: uid) else {
            print("❌ CoreData: User not found for sync marking")
            return
        }
        
        user.isSynced = true
        user.lastSyncedAt = Date()
        save()
    }
    
    func fetchUnsyncedUsers() -> [User] {
        let request: NSFetchRequest<User> = User.fetchRequest()
        request.predicate = NSPredicate(format: "isSynced == NO")
        
        do {
            return try context.fetch(request)
        } catch {
            print("❌ CoreData: Fetch unsynced users error: \(error)")
            return []
        }
    }
} 