import Foundation
import SwiftUI

struct AppColors {
    
    //Light Mode
    static let backgroundLight = Color(red: 0.96, green: 0.98, blue: 0.96) // #F5F9F6
    static let cardLight = Color.white
    static let textLight = Color.black
    static let secondaryTextLight = Color.gray.opacity(0.7)

    //Dark Mode
    static let backgroundDark = Color(red: 0.10, green: 0.15, blue: 0.20) // #1A2634
    static let cardDark = Color(red: 0.18, green: 0.24, blue: 0.31) // #2E3C4C
    static let textDark = Color.white
    static let secondaryTextDark = Color.gray.opacity(0.6)
    

    static let primaryGreen = Color(red: 0.30, green: 0.69, blue: 0.31) // #4CAF50
    static let warningRed = Color(red: 1.0, green: 0.38, blue: 0.30) // #FF6150
    static let accentYellow = Color(red: 1.0, green: 0.76, blue: 0.03) // #FFC107
}

extension Color {
    static let backgroundDarkBlue = Color(red: 0.17, green: 0.17, blue: 0.22)
    static let backgroundLightBlue = Color(red: 0.15, green: 0.15, blue: 0.25)
    static let buttonlightGreen = Color(red: 30/255, green: 250/255, blue: 85/255)
    static let buttonGreen = Color(red: 39/255, green: 174/255, blue: 96/255)
}
