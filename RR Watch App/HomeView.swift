import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 15) {
                    
                    // 1. 握力训练入口 (已完成)
                    NavigationLink(destination: GripView()) {
                        MenuCard(title: "握力训练", icon: "hand.wave.fill", color: .green)
                    }
                    .buttonStyle(.plain) // 去掉默认样式，用我们自定义的
                    
                    // 2. 悬臂唤醒入口 (新建占位)
                    NavigationLink(destination: ArmWakeupView()) {
                        MenuCard(title: "悬臂唤醒", icon: "figure.arms.open", color: .orange)
                    }
                    .buttonStyle(.plain)
                    
                    // 3. 转腕训练入口 (新建占位)
                    NavigationLink(destination: WristRotationView()) {
                        MenuCard(title: "转腕训练", icon: "arrow.triangle.2.circlepath", color: .blue)
                    }
                    .buttonStyle(.plain)
                }
                .padding()
            }
            .navigationTitle("康复训练")
        }
    }
}

// MARK: - 自定义的大按钮组件
struct MenuCard: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .frame(width: 30)
            
            Text(title)
                .font(.headline)
                .fontWeight(.bold)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.white.opacity(0.5))
        }
        .padding()
        .frame(height: 70) // 按钮高度，大一点好点
        .background(color)
        .cornerRadius(15) // 圆角
    }
}

#Preview {
    HomeView()
}
