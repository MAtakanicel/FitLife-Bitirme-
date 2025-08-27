import SwiftUI

struct CustomTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
            
            if isSecure {
                SecureField(placeholder, text: $text)
                    .textFieldStyle(CustomTextFieldStyle())
            } else {
                TextField(placeholder, text: $text)
                    .keyboardType(keyboardType)
                    .textFieldStyle(CustomTextFieldStyle())
            }
        }
    }
}

struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color.white.opacity(0.1))
            .cornerRadius(10)
            .foregroundColor(.white)
    }
}

struct StepIndicator: View {
    var currentStep: Int
    var totalSteps: Int = 7
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...totalSteps, id: \.self) { step in
                Circle()
                    .frame(width: 8, height: 8)
                    .foregroundColor(step <= currentStep ? Color.buttonlightGreen : Color.gray.opacity(0.5))
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        TextField("Test Field", text: .constant(""))
            .textFieldStyle(CustomTextFieldStyle())
        
        StepIndicator(currentStep: 3)
    }
    .padding()
    .background(Color.backgroundDarkBlue)
} 