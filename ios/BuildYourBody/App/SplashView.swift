import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [.green700, .green900], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            Text("Build Your Body")
                .font(.serifDisplay(28))
                .foregroundStyle(.white)
        }
    }
}
