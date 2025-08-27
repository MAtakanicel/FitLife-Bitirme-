import SwiftUI

struct ExerciseDetailView: View {
    let program: ExerciseProgram
    @ObservedObject private var exerciseTrackingService = ExerciseTrackingService.shared
    @State private var isWorkoutActive = false
    @State private var currentExerciseIndex = 0
    @State private var timeRemaining = 0
    @State private var timer: Timer?
    @State private var isWorkoutCompleted = false
    @State private var workoutStartTime: Date?
    @State private var showCompletionAlert = false
    
    private var currentExercise: Exercise? {
        guard currentExerciseIndex < program.exercises.count else { return nil }
        return program.exercises[currentExerciseIndex]
    }
    
    private var isCurrentExerciseTimeBased: Bool {
        guard let exercise = currentExercise else { return false }
        return exercise.reps.contains("sn") || exercise.reps.contains("saniye")
    }
    
    private var isLastExercise: Bool {
        return currentExerciseIndex >= program.exercises.count - 1
    }
    
    private var nextExercise: Exercise? {
        let nextIndex = currentExerciseIndex + 1
        guard nextIndex < program.exercises.count else { return nil }
        return program.exercises[nextIndex]
    }
    
    var body: some View {
        ZStack {
            Color.backgroundDarkBlue.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Program Bilgileri
                    programInfoSection
                    
                    // Egzersiz Listesi veya Aktif Antrenman
                    if isWorkoutActive {
                        activeWorkoutSection
                    } else {
                        exerciseListSection
                    }
                    
                    // Başlat/Durdur Butonu
                    workoutControlSection
                }
                .padding()
            }
        }
        .navigationTitle(program.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(Color.backgroundDarkBlue, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .onAppear {
            // Navigation bar text color'ını soluk beyaz yap
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(Color.backgroundDarkBlue)
            appearance.titleTextAttributes = [.foregroundColor: UIColor.white.withAlphaComponent(0.8)]
            appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white.withAlphaComponent(0.8)]
            
            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().compactAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
        }
        .onDisappear {
            stopWorkout()
        }
        .alert("Antrenman Tamamlandı! 🎉", isPresented: $showCompletionAlert) {
            Button("Harika!") { }
        } message: {
            Text("Tebrikler! \(program.estimated_calories) kalori yaktınız ve bu veriler ana sayfanıza eklendi.")
        }
    }
    
    private var programInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(program.description)
                .font(.body)
                .foregroundColor(.white.opacity(0.9))
            
            HStack(spacing: 20) {
                Label("\(program.exercises.count) Egzersiz", systemImage: "list.bullet")
                    .foregroundColor(.buttonlightGreen)
                
                let totalDuration = program.exercises.reduce(0) { $0 + $1.duration_sec }
                Label("\(totalDuration/60) dk", systemImage: "clock")
                    .foregroundColor(.buttonlightGreen)
                
                Label("\(program.estimated_calories) kcal", systemImage: "flame")
                    .foregroundColor(.buttonlightGreen)
            }
            .font(.subheadline)
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var exerciseListSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Egzersizler")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            ForEach(Array(program.exercises.enumerated()), id: \.offset) { index, exercise in
                ExerciseRowView(
                    exercise: exercise,
                    isActive: isWorkoutActive && currentExerciseIndex == index,
                    isCompleted: isWorkoutActive && currentExerciseIndex > index
                )
            }
        }
    }
    
    private var activeWorkoutSection: some View {
        VStack(spacing: 20) {
            if isWorkoutCompleted {
                workoutCompletedView
            } else if let exercise = currentExercise {
                activeExerciseView(exercise: exercise)
            }
        }
    }
    
    private func activeExerciseView(exercise: Exercise) -> some View {
        VStack(spacing: 20) {
            // İlerleme
            HStack {
                Text("Egzersiz \(currentExerciseIndex + 1)/\(program.exercises.count)")
                    .font(.caption)
                    .foregroundColor(.buttonlightGreen)
                
                Spacer()
                
                Text("Kalan: \(program.exercises.count - currentExerciseIndex - 1)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            // Progress Bar
            ProgressView(value: Double(currentExerciseIndex), total: Double(program.exercises.count))
                .progressViewStyle(LinearProgressViewStyle(tint: .buttonlightGreen))
                .scaleEffect(y: 2)
            
            // Mevcut Egzersiz
            VStack(spacing: 16) {
                Text(exercise.name)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text(exercise.reps)
                    .font(.title2)
                    .foregroundColor(.buttonlightGreen)
                
                // Timer veya Manuel Tamamlama
                if isCurrentExerciseTimeBased {
                    // Süre bazlı egzersizler için timer
                    if timeRemaining > 0 {
                        VStack(spacing: 8) {
                            Text("Süre")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Text("\(timeRemaining)")
                                .font(.system(size: 48, weight: .bold, design: .monospaced))
                                .foregroundColor(.buttonlightGreen)
                            
                            // Progress Circle
                            ZStack {
                                Circle()
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                                    .frame(width: 100, height: 100)
                                
                                Circle()
                                    .trim(from: 0, to: CGFloat(exercise.duration_sec - timeRemaining) / CGFloat(exercise.duration_sec))
                                    .stroke(Color.buttonlightGreen, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                                    .frame(width: 100, height: 100)
                                    .rotationEffect(.degrees(-90))
                                    .animation(.linear(duration: 1), value: timeRemaining)
                            }
                        }
                    }
                } else {
                    // Tekrar bazlı egzersizler için manuel tamamlama
                    VStack(spacing: 16) {
                        Text("Egzersizi tamamladığınızda butona basın")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                        
                        Button("Tamamladım") {
                            moveToNextExercise()
                        }
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(width: 200, height: 60)
                        .background(Color.buttonlightGreen)
                        .cornerRadius(30)
                    }
                }
            }
            .padding()
            .background(Color.white.opacity(0.1))
            .cornerRadius(16)
            
            // Sıradaki Egzersiz
            if let next = nextExercise {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Sıradaki:")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    HStack {
                        Text(next.name)
                            .font(.subheadline)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text(next.reps)
                            .font(.caption)
                            .foregroundColor(.buttonlightGreen)
                    }
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
            }
            
            // Sıradaki Harekete Geç Butonu (sadece timer bazlı egzersizler için)
            if nextExercise != nil && isCurrentExerciseTimeBased {
                Button("Sıradaki Harekete Geç") {
                    skipToNextExercise()
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.buttonlightGreen)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
    }
    
    private var workoutCompletedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            Text("Tebrikler!")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Antrenmanı başarıyla tamamladınız!")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 8) {
                Text("Yakılan Tahmini Kalori")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text("\(program.estimated_calories) kcal")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.buttonlightGreen)
            }
            .padding()
            .background(Color.white.opacity(0.1))
            .cornerRadius(12)
        }
    }
    
    private var workoutControlSection: some View {
        VStack(spacing: 12) {
            if !isWorkoutCompleted {
                Button(action: {
                    if isWorkoutActive {
                        // Son egzersizde "Antremanı Bitir" işlevi
                        if isLastExercise {
                            completeWorkout()
                        } else {
                            stopWorkout()
                        }
                    } else {
                        startWorkout()
                    }
                }) {
                    HStack {
                        Image(systemName: getButtonIcon())
                        Text(getButtonText())
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(getButtonColor())
                    .cornerRadius(12)
                }
            } else {
                Button("Yeniden Başlat") {
                    resetWorkout()
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.buttonlightGreen)
                .cornerRadius(12)
            }
        }
    }
    
    private func startWorkout() {
        isWorkoutActive = true
        isWorkoutCompleted = false
        currentExerciseIndex = 0
        workoutStartTime = Date()
        startExerciseTimer()
    }
    
    private func stopWorkout() {
        isWorkoutActive = false
        timer?.invalidate()
        timer = nil
        timeRemaining = 0
    }
    
    private func resetWorkout() {
        stopWorkout()
        isWorkoutCompleted = false
        currentExerciseIndex = 0
    }
    
    private func startExerciseTimer() {
        guard let exercise = currentExercise else { return }
        
        // Sadece süre bazlı egzersizler için timer başlat
        if isCurrentExerciseTimeBased {
            timeRemaining = exercise.duration_sec
            
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                if timeRemaining > 0 {
                    timeRemaining -= 1
                } else {
                    moveToNextExercise()
                }
            }
        } else {
            // Tekrar bazlı egzersizler için timer'ı durdur
            timeRemaining = 0
            timer?.invalidate()
            timer = nil
        }
    }
    
    private func skipToNextExercise() {
        timer?.invalidate()
        moveToNextExercise()
    }
    
    private func moveToNextExercise() {
        timer?.invalidate()
        
        if currentExerciseIndex < program.exercises.count - 1 {
            currentExerciseIndex += 1
            startExerciseTimer()
        } else {
            // Antrenman tamamlandı
            completeWorkout()
        }
    }
    
    private func completeWorkout() {
        timer?.invalidate()
        isWorkoutCompleted = true
        isWorkoutActive = false
        timeRemaining = 0
        
        // Antrenman süresini hesapla
        let workoutDuration = calculateWorkoutDuration()
        
        // ExerciseTrackingService'e kalori ekle
        exerciseTrackingService.addExerciseSession(
            exerciseName: "Tam Antrenman",
            programTitle: program.title,
            caloriesBurned: Double(program.estimated_calories),
            duration: workoutDuration
        )
        
        // Başarı alert'i göster
        showCompletionAlert = true
    }
    
    private func calculateWorkoutDuration() -> Int {
        guard let startTime = workoutStartTime else {
            // Eğer başlangıç zamanı yoksa tahmini süreyi kullan
            return program.exercises.reduce(0) { $0 + $1.duration_sec }
        }
        return Int(Date().timeIntervalSince(startTime))
    }
    
    // MARK: - Button Helper Methods
    
    private func getButtonText() -> String {
        if isWorkoutActive {
            return isLastExercise ? "Antremanı Bitir" : "Antrenmanı Durdur"
        } else {
            return "Antrenmanı Başlat"
        }
    }
    
    private func getButtonIcon() -> String {
        if isWorkoutActive {
            return isLastExercise ? "checkmark.circle.fill" : "stop.fill"
        } else {
            return "play.fill"
        }
    }
    
    private func getButtonColor() -> Color {
        if isWorkoutActive {
            return isLastExercise ? Color.green : Color.red
        } else {
            return Color.buttonlightGreen
        }
    }
}

struct ExerciseRowView: View {
    let exercise: Exercise
    let isActive: Bool
    let isCompleted: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Durum İkonu
            ZStack {
                Circle()
                    .fill(backgroundColor)
                    .frame(width: 32, height: 32)
                
                Image(systemName: iconName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(iconColor)
            }
            
            // Egzersiz Bilgileri
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.subheadline)
                    .fontWeight(isActive ? .bold : .medium)
                    .foregroundColor(.white)
                
                HStack {
                    Text(exercise.reps)
                        .font(.caption)
                        .foregroundColor(.buttonlightGreen)
                    
                    Spacer()
                    
                    // Sadece süre bazlı egzersizler için süreyi göster
                    if exercise.reps.contains("sn") || exercise.reps.contains("saniye") {
                        Text("\(exercise.duration_sec)s")
                            .font(.caption)
                            .foregroundColor(.gray)
                    } else {
                        Text("Manuel")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            
            // Aktif İndikatörü
            if isActive {
                Text("Aktif")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.buttonlightGreen)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.buttonlightGreen.opacity(0.2))
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(backgroundColor.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isActive ? Color.buttonlightGreen : Color.clear, lineWidth: 2)
        )
    }
    
    private var backgroundColor: Color {
        if isCompleted {
            return .green
        } else if isActive {
            return .buttonlightGreen
        } else {
            return .gray
        }
    }
    
    private var iconName: String {
        if isCompleted {
            return "checkmark"
        } else if isActive {
            return "play.fill"
        } else {
            return "circle"
        }
    }
    
    private var iconColor: Color {
        if isCompleted {
            return .white
        } else if isActive {
            return .white
        } else {
            return .gray
        }
    }
}

#Preview {
    NavigationView {
        ExerciseDetailView(program: ExerciseProgram(
            title: "Örnek Egzersiz",
            description: "Test egzersizi",
            estimated_calories: 100,
            exercises: [
                Exercise(name: "Test", reps: "10 tekrar", duration_sec: 30)
            ]
        ))
    }
}
