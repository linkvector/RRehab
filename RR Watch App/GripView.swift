import SwiftUI

struct GripView: View {
    @StateObject var manager = GripManager()
    
    // 获取关闭页面的能力
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack {
            switch manager.state {
                
            case .idle:
                Text("准备中...")
                    .font(.caption)
                    .foregroundColor(.gray)
                
            case .preparing:
                VStack {
                    Text("准备")
                        .font(.headline)
                        .foregroundColor(.green)
                    Text("\(manager.countdown)")
                        .font(.system(size: 80, weight: .bold))
                        .foregroundColor(.yellow)
                        .contentTransition(.numericText())
                }
                
            case .training:
                VStack {
                    Text("听声握紧")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    HStack(alignment: .lastTextBaseline) {
                        Text("\(manager.count)")
                            .font(.system(size: 60, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.blue)
                            .contentTransition(.numericText())
                        
                        Text("/ \(manager.totalReps)")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    if manager.warningCount > 0 {
                        Text("加油: \(manager.warningCount)")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                
            case .finished:
                VStack(spacing: 15) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                        .symbolEffect(.bounce)
                    Text("训练完成")
                        .font(.title2)
                }
            }
        }
        .padding()
        .onAppear {
            manager.startSession()
        }
        // 【修正点】这里适配了 watchOS 10 的新语法
        // 以前是 { newValue in ... }
        // 现在是 { oldValue, newValue in ... }，我们用 _ 忽略掉 oldValue
        .onChange(of: manager.shouldDismiss) { _, newValue in
            if newValue {
                print("收到退出指令，返回首页")
                dismiss() // 执行返回操作
            }
        }
    }
}

#Preview {
    GripView()
}
