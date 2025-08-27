import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @ObservedObject private var localizationService = LocalizationService.shared
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView(selectedTab: $selectedTab)
            }
            .tabItem {
                Image(systemName: "house.fill")
                Text("home".localized)
            }
            .tag(0)
            
            NavigationStack {
                DietListView()
            }
            .tabItem {
                Image(systemName: "fork.knife")
                Text("diet".localized)
            }
            .tag(1)
            
            NavigationStack {
                ExerciseView()
            }
            .tabItem {
                Image(systemName: "dumbbell.fill")
                Text("exercise".localized)
            }
            .tag(2)
            
            NavigationStack {
                AIAssistantView()
            }
            .tabItem {
                Image(systemName: "brain.head.profile")
                Text("ai_assistant".localized)
            }
            .tag(3)
            
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Image(systemName: "gearshape.fill")
                Text("settings".localized)
            }
            .tag(4)
        }
        .accentColor(.buttonGreen)
        .onAppear {
            // Tab bar görünümünü özelleştir
            let appearance = UITabBarAppearance()
            appearance.backgroundColor = UIColor(Color.backgroundDarkBlue)
            
            // Seçili olmayan tab'ların rengini ayarla
            appearance.stackedLayoutAppearance.normal.iconColor = UIColor.gray
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.gray]
            
            // Seçili tab'ın rengini ayarla
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color.buttonGreen)
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(Color.buttonGreen)]
            
            UITabBar.appearance().standardAppearance = appearance
            if #available(iOS 15.0, *) {
                UITabBar.appearance().scrollEdgeAppearance = appearance
            }
        }
        .onChange(of: localizationService.currentLanguage) { _, _ in
            // Dil değiştiğinde tab bar'ı yenile
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                selectedTab = selectedTab
            }
        }
    }
}

#Preview {
    MainTabView()
} 
