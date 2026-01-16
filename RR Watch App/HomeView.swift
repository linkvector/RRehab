import SwiftUI

struct HomeView: View {
    // 【修改点】改为 ObservedObject，更适合监听单例的变化
    @ObservedObject var connectivity = ConnectivityManager.shared
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 15) {
                    
                    // 握力训练入口
                    NavigationLink(destination: GripView()) {
                        MenuCard(title: "握力训练", icon: "hand.wave.fill", color: .green)
                    }
                    .buttonStyle(.plain)
                    
                    // 悬臂唤醒入口
                    NavigationLink(destination: ArmWakeupView()) {
                        MenuCard(title: "悬臂唤醒", icon: "figure.arms.open", color: .orange)
                    }
                    .buttonStyle(.plain)
                    
                    // 转腕训练入口
                    NavigationLink(destination: WristRotationView()) {
                        MenuCard(title: "转腕训练", icon: "arrow.triangle.2.circlepath", color: .blue)
                    }
                    .buttonStyle(.plain)
                    
                    // 调试信息：显示当前开关状态，方便你排查
                    if connectivity.lastMessage.contains("start_grip") {
                        Text("跳转信号: \(connectivity.showGripTraining ? "ON" : "OFF")")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
                .padding()
            }
            .navigationTitle("康复训练")
            // 自动跳转逻辑
            .navigationDestination(isPresented: $connectivity.showGripTraining) {
                GripView()
            }
            // 【核心修复】每次回到首页，立刻把开关关掉
            // 这样下次收到信号时，才能从 false 变成 true，触发跳转
            .onAppear {
                print("🏠 手表回到首页，重置跳转开关")
                connectivity.showGripTraining = false
            }
        }
    }
}

struct MenuCard: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon).font(.title2).frame(width: 30)
            Text(title).font(.headline).fontWeight(.bold)
            Spacer()
            Image(systemName: "chevron.right").font(.caption).foregroundColor(.white.opacity(0.5))
        }
        .padding()
        .frame(height: 70)
        .background(color)
        .cornerRadius(15)
    }
}

#Preview {
    HomeView()
}
