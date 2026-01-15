import SwiftUI

struct ArmWakeupView: View {
    var body: some View {
        VStack {
            Image(systemName: "figure.arms.open")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            Text("悬臂唤醒")
                .font(.title2)
            Text("开发中...")
                .foregroundColor(.gray)
        }
    }
}
