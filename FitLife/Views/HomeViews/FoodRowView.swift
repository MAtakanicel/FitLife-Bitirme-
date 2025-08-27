import SwiftUI

struct FoodRowView: View {
    let food: Food
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Food Icon
                Image(systemName: "fork.knife.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.white.opacity(0.7))
                
                // Food Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(food.foodName ?? "Bilinmeyen Yiyecek")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    if let description = food.foodDescription {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                    
                    // Brand info if available
                    if let brand = food.brandName {
                        HStack {
                            Image(systemName: "building.2")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.5))
                            
                            Text(brand)
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                }
                
                Spacer()
                
                // Arrow
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .background(Color.white.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ZStack {
        Color.backgroundDarkBlue.ignoresSafeArea()
        
        VStack {
            // Preview content - using mock data
            Text("Food Row Preview")
                .foregroundColor(.white)
        }
        .padding()
    }
} 