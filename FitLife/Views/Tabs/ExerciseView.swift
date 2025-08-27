import SwiftUI

struct ExerciseView: View {
    @ObservedObject private var exerciseService = ExerciseService.shared
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        ZStack {
            Color.backgroundDarkBlue.ignoresSafeArea()
            
            VStack {
                // Başlık
                VStack(alignment: .leading, spacing: 15) {
                    Text("Egzersizler")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Hedeflerinize uygun, uzmanlar tarafından hazırlanmış antrenman programları")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.horizontal)
                .frame(maxWidth: .infinity, alignment: .leading)
                
                if exerciseService.isLoading {
                    Spacer()
                    VStack {
                        ProgressView()
                            .scaleEffect(1.5)
                            .progressViewStyle(CircularProgressViewStyle(tint: .buttonlightGreen))
                        
                        Text("Egzersizler yükleniyor...")
                            .foregroundColor(.white)
                            .padding(.top)
                    }
                    Spacer()
                } else if let errorMessage = exerciseService.errorMessage {
                    Spacer()
                    VStack {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.buttonlightGreen)
                        
                        Text("Hata")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.top)
                        
                        Text(errorMessage)
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button("Tekrar Dene") {
                            exerciseService.loadExercisePrograms()
                        }
                        .padding()
                        .background(Color.buttonlightGreen)
                        .foregroundColor(.black)
                        .cornerRadius(10)
                        .padding(.top)
                    }
                    Spacer()
                } else {
                    // Egzersiz programları grid görünümü
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(exerciseService.exercisePrograms) { program in
                                NavigationLink(destination: ExerciseDetailView(program: program)) {
                                    ExerciseProgramCardView(program: program)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                    }
                }
            }
            .padding(.top, 20)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    exerciseService.loadExercisePrograms()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.white)
                }
            }
        }
    }
}

struct ExerciseProgramCardView: View {
    let program: ExerciseProgram
    
    private var cardColor: Color {
        switch program.title {
        case let title where title.contains("Tüm Vücut"):
            return .blue.opacity(0.8)
        case let title where title.contains("Üst Vücut"):
            return .green.opacity(0.8)
        case let title where title.contains("HIIT"):
            return .red.opacity(0.8)
        case let title where title.contains("Kol"):
            return .purple.opacity(0.8)
        case let title where title.contains("Bacak"):
            return .orange.opacity(0.8)
        case let title where title.contains("Karın") || title.contains("Core"):
            return .cyan.opacity(0.8)
        default:
            return .gray.opacity(0.8)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Görsel
            Rectangle()
                .fill(cardColor)
                .frame(height: 100)
                .cornerRadius(12)
                .overlay(
                    VStack {
                        Image(systemName: getIcon())
                            .font(.system(size: 30, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text("\(program.estimated_calories) kcal")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white.opacity(0.9))
                    }
                )
            
            // İçerik
            VStack(alignment: .leading, spacing: 8) {
                Text(program.title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                Text(program.description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(2)
                
                // Alt bilgiler
                HStack(spacing: 15) {
                    HStack(spacing: 4) {
                        Image(systemName: "list.bullet")
                            .font(.caption)
                            .foregroundColor(.buttonlightGreen)
                        Text("\(program.exercises.count)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption)
                            .foregroundColor(.buttonlightGreen)
                        let totalDuration = program.exercises.reduce(0) { $0 + $1.duration_sec }
                        Text("\(totalDuration/60) dk")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                }
            }
            .padding(.horizontal, 5)
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
    
    private func getIcon() -> String {
        switch program.title {
        case let title where title.contains("Tüm Vücut"):
            return "figure.mixed.cardio"
        case let title where title.contains("Üst Vücut"):
            return "figure.strengthtraining.traditional"
        case let title where title.contains("HIIT"):
            return "flame.fill"
        case let title where title.contains("Kol"):
            return "figure.arms.open"
        case let title where title.contains("Bacak"):
            return "figure.walk"
        case let title where title.contains("Karın") || title.contains("Core"):
            return "figure.core.training"
        default:
            return "figure.flexibility"
        }
    }
}

#Preview {
    ExerciseView()
}
