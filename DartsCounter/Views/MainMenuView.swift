import SwiftUI

struct MainMenuView: View {
    @EnvironmentObject var gameManager: GameManager
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Title
            VStack(spacing: 10) {
                Image(systemName: "target")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.red, .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("DARTS")
                    .font(.system(size: 60, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                
                Text("COUNTER")
                    .font(.system(size: 30, weight: .medium, design: .rounded))
                    .foregroundColor(.gray)
                    .tracking(10)
            }
            
            Spacer()
            
            // Play Button
            Button(action: {
                gameManager.goToModeSelection()
            }) {
                HStack(spacing: 15) {
                    Image(systemName: "play.fill")
                        .font(.title2)
                    Text("PLAY")
                        .font(.title2.bold())
                }
                .foregroundColor(.white)
                .frame(width: 250, height: 60)
                .background(
                    LinearGradient(
                        colors: [.red, .orange],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 15))
                .shadow(color: .red.opacity(0.5), radius: 10, y: 5)
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            // Footer
            Text("v1.0")
                .font(.caption)
                .foregroundColor(.gray.opacity(0.5))
                .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    MainMenuView()
        .environmentObject(GameManager())
        .frame(width: 800, height: 600)
        .background(Color(red: 0.1, green: 0.12, blue: 0.15))
}
