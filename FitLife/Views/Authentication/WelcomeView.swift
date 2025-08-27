import SwiftUI

struct WelcomeView: View {
    @State private var showSheet = false
    @State private var showLoginView = false
    @State private var goRegisterNameView = false

    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Spacer()
                
                // Logo ve App ismi
                VStack(spacing: 20) {
                    Image("ScreenLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width:200, height: 200)
                        .foregroundColor(.blue)
                    
                    Text("FitLife")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top,-30)
                }//VStack
                
                Spacer()
                
                //Buttonlar
                VStack(spacing: 16) {
                    Button(action:{ goRegisterNameView.toggle() }){
                        Text("Yeni bir kullanıcıyım")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.buttonGreen)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal, 20)
                    .fullScreenCover(isPresented: $goRegisterNameView, content: {
                        RegisterNameView()
                    })
                    Button(action: {
                        showSheet = true
                    }) {
                        Text("Zaten bir hesabım var")
                            .font(.headline)
                            .foregroundColor(.buttonlightGreen)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.buttonGreen, lineWidth: 2)
                            )
                    }
                    .padding(.horizontal, 20)
                }//VStack
                
                Spacer()
                
                // Şartlar ve koşullar metni
                HStack(spacing: 0) {
                    Text("Devam etmekle ")
                        .foregroundColor(.gray)
                    
                    Button(action: {}) {
                        Text("Şartlar ve Koşullar")
                            .underline()
                            .foregroundColor(.white)
                    }
                    
                    Text(" ve ")
                        .foregroundColor(.gray)
                    
                    Button(action: {}) {
                        Text("Gizlilik Politikası")
                            .underline()
                            .foregroundColor(.white)
                    }
                    
                    Text("'nı kabul etmiş olursun.")
                        .foregroundColor(.gray)
                }//HStack
                .font(.caption)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }//Vstack
            .background(Color.backgroundDarkBlue)
        }//NavigationView
        .sheet(isPresented: $showSheet) {
            LoginOptionsView(showLoginView: $showLoginView)
                .presentationDetents([.fraction(0.35)])
        }
        .fullScreenCover(isPresented: $showLoginView) {
            LoginView()
        }
    }//body
}//Struct

struct LoginOptionsView: View {
    @Binding var showLoginView: Bool
    @State private var showRegisterView: Bool = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            Text("Oturum Aç")
                .frame(maxWidth: .infinity)
                .padding(.top,30)
                .foregroundColor(.white)
                .font(.system(size: 20, weight: .bold))
            Spacer()
            
            VStack(spacing: 10){
                Button(action: {
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showLoginView = true
                    }
                }) {
                    Text("E-posta ile devam et")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.buttonGreen)
                        .cornerRadius(10)
                }
                
                Text("veya")
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.gray)
                
                Button(action: {}){
                    HStack {
                        Image(systemName: "apple.logo")
                            .font(.title2)
                        Text("Apple ile Devam Et")
                            .font(.headline)
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                }
            }//VStack
            .padding(20)
            HStack (spacing: 5) {
                Text("Üye değil misiniz?")
                    .foregroundColor(.white.opacity(0.8))
                
                Button(action: {
                    showRegisterView.toggle()
                }) {
                    Text("Hesap Oluşturun")
                        .foregroundColor(.buttonlightGreen)
                }
                .fullScreenCover(isPresented: $showRegisterView, content: {
                    RegisterNameView()
                })
            }
        }
        .background(Color.backgroundLightBlue)
        Spacer()
    }
}

#Preview {
    WelcomeView()
    
}

