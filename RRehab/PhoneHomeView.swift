import SwiftUI

struct PhoneHomeView: View {
    // 监听全局状态和联络官
    @EnvironmentObject var appState: AppState // 确保在 App 入口处已注入
    @StateObject var connectivity = ConnectivityManager.shared
    
    var body: some View {
        TabView(selection: $appState.selectedTab) {
            // --- 标签页 1：训练 ---
            TrainingTab(connectivity: connectivity)
                .tag(0)
                .tabItem {
                    Label("训练", systemImage: "figure.mind.and.body")
                }
            
            // --- 标签页 2：统计 (引用独立的 StatisticsTab.swift) ---
            StatisticsTab()
                .tag(1)
                .tabItem {
                    Label("统计", systemImage: "chart.bar.xaxis")
                }
        }
        .tint(.green)
        
        // 1. 全屏监控页 (收到训练开始信号时弹出)
        .fullScreenCover(isPresented: $connectivity.isMonitoring) {
            PhoneTrainingMonitorView()
        }
        
        // --- 核心改进：删除了原本在这里的 .sheet(isPresented: $connectivity.showResultPage) ---
        // 这样即使收到数据，手机也不会弹出结果弹窗，减少悟空的参与
        
        // 监听自动跳转通知
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("AutoSwitchToStats"))) { _ in
            withAnimation {
                appState.selectedTab = 1 // 收到信号后，自动切换到统计标签页
            }
        }
    }
}

// MARK: - 训练主页面 (保持不变)
struct TrainingTab: View {
    @ObservedObject var connectivity: ConnectivityManager
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Image(systemName: "applewatch")
                            .foregroundColor(connectivity.isReachable ? .green : .gray)
                        Text(connectivity.isReachable ? "手表已连接" : "等待手表响应...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding([.horizontal, .top])
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text("早安，悟空")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("今天的康复任务已准备就绪")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                        Button {
                            startTraining(type: .grip)
                        } label: {
                            FeatureCard(title: "握力训练", icon: "hand.wave.fill", color: .green)
                        }
                        
                        Button {
                            startTraining(type: .armWakeup)
                        } label: {
                            FeatureCard(title: "悬臂唤醒", icon: "figure.arms.open", color: .orange)
                        }
                        
                        FeatureCard(title: "转腕训练", icon: "arrow.triangle.2.circlepath", color: .blue)
                            .opacity(0.6)
                    }
                    .padding()
                }
            }
            .navigationTitle("RhythmRehab")
            .background(Color(UIColor.systemGroupedBackground))
        }
    }
    
    private func startTraining(type: ActivityType) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        connectivity.currentActivity = type
        let command = type == .grip ? "start_grip_training" : "start_arm_wakeup"
        connectivity.sendMessage(["command": command])
    }
}

// MARK: - 监控中转页 (已移除强制结束按钮)
struct PhoneTrainingMonitorView: View {
    @StateObject var connectivity = ConnectivityManager.shared
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 40) {
                Text("训练进行中")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
                
                Image(systemName: connectivity.currentActivity == .grip ? "hand.wave.fill" : "figure.arms.open")
                    .font(.system(size: 100))
                    .foregroundColor(.white)
                    .symbolEffect(.bounce, options: .repeating)
                
                Text("请关注手表端的提示和震动")
                    .foregroundColor(.gray)
            }
        }
        .interactiveDismissDisabled()
    }
}

// MARK: - 通用 UI 组件 (保持不变)
struct FeatureCard: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Circle()
                .fill(color.opacity(0.2))
                .frame(width: 44, height: 44)
                .overlay(Image(systemName: icon).foregroundColor(color))
            
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("点击开始")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}
