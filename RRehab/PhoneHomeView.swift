import SwiftUI
import Combine // 【修复点】必须引入 Combine 才能使用 timer 的 autoconnect()

struct PhoneHomeView: View {
    // 监听联络官
    @StateObject var connectivity = ConnectivityManager.shared
    
    // 控制未连接时的弹窗
    @State private var showConnectionAlert = false
    
    var body: some View {
        TabView {
            // --- 第一个标签页：训练 ---
            TrainingTab(connectivity: connectivity, showAlert: $showConnectionAlert)
                .tabItem {
                    Label("训练", systemImage: "figure.mind.and.body")
                }
            
            // --- 第二个标签页：统计 ---
            StatisticsTab()
                .tabItem {
                    Label("统计", systemImage: "chart.bar.xaxis")
                }
        }
        .tint(.green)
        
        // 1. 全屏监控页 (收到训练开始信号弹出)
        .fullScreenCover(isPresented: $connectivity.isMonitoring) {
            PhoneTrainingMonitorView()
        }
        
        // 2. 结果统计页 (收到训练结束信号弹出)
        .sheet(isPresented: $connectivity.showResultPage) {
            PhoneResultView()
        }
    }
}

// MARK: - 1. 训练主页面
struct TrainingTab: View {
    @ObservedObject var connectivity: ConnectivityManager
    @Binding var showAlert: Bool
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    // 状态栏
                    HStack {
                        Image(systemName: "applewatch")
                            .foregroundColor(connectivity.isReachable ? .green : .gray)
                        Text(connectivity.isReachable ? "手表已连接" : "手表未连接 (可尝试点击)")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
                    // 标题区
                    VStack(alignment: .leading, spacing: 5) {
                        Text("早安，悟空")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("今天的康复目标完成了吗？")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    
                    // 宫格菜单
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                        
                        // 握力训练按钮
                        Button(action: {
                            handleGripStart()
                        }) {
                            FeatureCard(title: "握力训练", icon: "hand.wave.fill", color: .green)
                        }
                        
                        NavigationLink(destination: Text("悬臂唤醒开发中...")) {
                            FeatureCard(title: "悬臂唤醒", icon: "figure.arms.open", color: .orange)
                        }
                        
                        NavigationLink(destination: Text("转腕训练开发中...")) {
                            FeatureCard(title: "转腕训练", icon: "arrow.triangle.2.circlepath", color: .blue)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("RyhthmRehab")
            .navigationBarHidden(true)
            .background(Color(UIColor.systemGroupedBackground))
            
            .alert("尝试连接...", isPresented: $showAlert) {
                Button("好", role: .cancel) { }
            } message: {
                Text("正在尝试呼叫手表，请确保手表屏幕点亮。")
            }
        }
    }
    
    func handleGripStart() {
        print("👆 触发握力训练远程启动")
        connectivity.currentActivity = .grip
        connectivity.sendMessage(["command": "start_grip_training"])
        
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
}

// MARK: - 2. 统计页面占位
struct StatisticsTab: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "chart.xyaxis.line")
                    .font(.system(size: 60))
                    .foregroundColor(.purple)
                
                Text("数据分析中心")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("正在准备您的康复曲线...")
                    .foregroundColor(.gray)
                
                Spacer()
            }
            .padding(.top, 50)
            .navigationTitle("统计")
            .background(Color(UIColor.systemGroupedBackground))
        }
    }
}

// MARK: - 3. 训练监控页 (包含机制二：隐形倒计时保护)
struct PhoneTrainingMonitorView: View {
    @StateObject var connectivity = ConnectivityManager.shared
    
    // 设置最大等待时间（例如 180 秒，超过一般训练时长）
    @State private var timeOutSeconds: Int = 180
    
    // 定时器每秒发布一次
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            Color.green.opacity(0.1).ignoresSafeArea()
            
            VStack(spacing: 50) {
                
                Text("正在训练中...")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
                    .padding(.top, 80)
                
                // 图标修改为“手”
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 220, height: 220)
                        .shadow(color: Color.green.opacity(0.3), radius: 20, x: 0, y: 10)
                    
                    Image(systemName: "hand.wave.fill")
                        .font(.system(size: 100))
                        .foregroundColor(.green)
                }
                
                VStack(spacing: 15) {
                    Text("保持节奏，悟空加油！")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text("请跟随手表的节奏进行动作\n训练将自动结束")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
                
                // 机制二的隐形保护倒计时（极淡显示，用于开发者观察）
                Text("安全保护倒计时: \(timeOutSeconds)")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.gray.opacity(0.2))
                    .padding(.bottom, 20)
            }
        }
        // 监听定时器，处理倒计时逻辑
        .onReceive(timer) { _ in
            if timeOutSeconds > 0 {
                timeOutSeconds -= 1
            } else {
                // 超时强制退出，防止页面锁死
                print("🚨 监控超时，执行主动安全退出")
                connectivity.isMonitoring = false
            }
        }
    }
}

// MARK: - 4. 通用卡片组件
struct FeatureCard: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Circle()
                .fill(color.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(.title2)
                )
            
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("点击开始")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    PhoneHomeView()
}
