import SwiftUI
import UIKit

// MARK: - Keyboard Dismiss View

struct KeyboardDismissView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject {
        @objc func dismissKeyboard() {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}

// MARK: - View Extensions

extension View {
    // Klavyeyi gizleme methodu
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    // En etkili klavye kapatma yöntemi - UIKit tabanlı
    func dismissKeyboard() -> some View {
        self.background(
            KeyboardDismissView()
        )
    }
    
    // Görünümlere standart bir padding uygulamar.
    func standardPadding() -> some View {
        self.padding(AppConstants.UI.standardPadding)
    }
    
    // Klasik background (Tema diyebiliriz.)
    func fitLifeBackground() -> some View {
        self.background(Color.backgroundDarkBlue.ignoresSafeArea())
    }
    
    // TextField style
    func fitLifeTextField() -> some View {
        self.textFieldStyle(CustomTextFieldStyle())
            .autocapitalization(.none)
            .disableAutocorrection(true)
    }
    
    // MARK: - Button Temam
    func primaryButton() -> some View {
        self.foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.buttonGreen)
            .cornerRadius(AppConstants.UI.buttonCornerRadius)
    }
    
    func secondaryButton() -> some View {
        self.foregroundColor(.buttonlightGreen)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.white.opacity(0.1))
            .cornerRadius(AppConstants.UI.buttonCornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppConstants.UI.buttonCornerRadius)
                    .stroke(Color.buttonGreen, lineWidth: 2)
            )
    }
}

// MARK: - Text Field Extension (Login ekranı)

extension TextField {
    func fitLifeStyle() -> some View {
        self.textFieldStyle(CustomTextFieldStyle())
            .autocapitalization(.none)
            .disableAutocorrection(true)
            .padding(.bottom, 5)
            .frame(height: 50)
            .background(
                ZStack {
                    // Gölge
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.black.opacity(0.2))
                        .offset(y: 2)
                    
                    // Arkaplan
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.15))
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
    }
}

// MARK: - SecureField Extension (Şifreler için)
extension SecureField {
    func fitLifeStyle() -> some View {
        self.textFieldStyle(CustomTextFieldStyle())
            .padding(.bottom, 5)
            .frame(height: 50)
            .background(
                ZStack {
                    // Gölge
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.black.opacity(0.2))
                        .offset(y: 2)
                    
                    // Arkaplan
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.15))
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
    }
} 
 