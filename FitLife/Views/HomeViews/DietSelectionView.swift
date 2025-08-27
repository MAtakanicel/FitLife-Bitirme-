import SwiftUI

struct DietSelectionView: View {
    @Binding var selectedDiet: String
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var dietService = DietService.shared
    
    private let dietTypes = [
        ("Akdeniz Diyeti", "Akdeniz"),
        ("Ketojenik Diyet", "Keto"),
        ("Paleo Diyet", "paleo"),
        ("Vegan Diyet", "vegan"),
        ("Yüksek Protein Diyeti", "high_protein"),
        ("Aralıklı Oruç", "intermittent_fasting")
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.backgroundDarkBlue.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    headerSection
                    
                    // Diet List
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(dietTypes, id: \.0) { dietInfo in
                                dietRow(dietName: dietInfo.0, fileName: dietInfo.1)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    private var headerSection: some View {
        HStack {
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "xmark")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
            
            Spacer()
            
            Text("Diyet Seçimi")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Spacer()
            
            Color.clear
                .frame(width: 44, height: 44)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
    
    private func dietRow(dietName: String, fileName: String) -> some View {
        Button(action: {
            selectedDiet = dietName
            dismiss()
        }) {
            HStack(spacing: 16) {
                // Diet Icon
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: getDietIcon(for: dietName))
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(dietName)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                    
                    Text(dietService.getDietDescription(fileName: fileName))
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)
                }
                
                Spacer()
                
                if selectedDiet == dietName {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.green)
                } else {
                    Image(systemName: "circle")
                        .font(.system(size: 24))
                        .foregroundColor(.white.opacity(0.3))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(
                selectedDiet == dietName ? 
                Color.white.opacity(0.1) : Color.white.opacity(0.05)
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        selectedDiet == dietName ? 
                        Color.white.opacity(0.3) : Color.white.opacity(0.1),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func getDietIcon(for diet: String) -> String {
        switch diet {
        case "Akdeniz Diyeti":
            return "leaf.fill"
        case "Ketojenik Diyet":
            return "bolt.fill"
        case "Paleo Diyet":
            return "flame.fill"
        case "Vegan Diyet":
            return "leaf.circle.fill"
        case "Yüksek Protein Diyeti":
            return "dumbbell.fill"
        case "Aralıklı Oruç":
            return "clock.fill"
        default:
            return "fork.knife"
        }
    }
}

#Preview {
    DietSelectionView(selectedDiet: .constant("Akdeniz Diyeti"))
} 