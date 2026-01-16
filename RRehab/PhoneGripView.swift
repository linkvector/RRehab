import SwiftUI

struct PhoneGripView: View {
    @StateObject var connectivity = ConnectivityManager.shared
    
    var body: some View {
        VStack(spacing: 30) {
            
            // 顶部图示
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 200, height: 200)
                
                Image(systemName: "hand.wave.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
            }
            .padding(.top, 50)
            
            VStack(spacing: 10) {
                Text("握力协同训练")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("请佩戴手表，点击下方按钮开始")
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // 调试信息：看看有没有收到手表的信号
            if !connectivity.lastMessage.isEmpty {
                Text("收到手表信号: \(connectivity.lastMessage)")
                    .font(.caption)
                    .padding()
                    .background(Color.black.opacity(0.05))
                    .cornerRadius(8)
            }
            
            // 核心按钮：远程遥控手表
            Button(action: {
                startWatchSession()
            }) {
                HStack {
                    Image(systemName: "play.fill")
                    Text("启动手表端训练")
                }
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .cornerRadius(15)
            }
            .padding(.horizontal)
            .padding(.bottom, 50)
        }
    }
    
    // 发送指令给手表
    func startWatchSession() {
        print("尝试启动手表...")
        connectivity.sendMessage(["command": "start_grip_training"])
    }
}

#Preview {
    PhoneGripView()
}
