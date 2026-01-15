import SwiftUI

struct GripView: View {
    // 引用逻辑
    @StateObject var manager = GripManager()

    var body: some View {
        VStack {
            switch manager.state {
                
            case .idle:
                // 1. 进场瞬间的状态（极短）
                // 因为马上会自动开始，这里只需要显示个标题或者空着
                Text("准备中...")
                    .font(.caption)
                    .foregroundColor(.gray)
                
            case .preparing:
                // 2. 倒计时 (3-2-1)
                VStack {
                    Text("准备")
                        .font(.headline)
                        .foregroundColor(.green)
                    
                    Text("\(manager.countdown)")
                        .font(.system(size: 80, weight: .bold))
                        .foregroundColor(.yellow)
                        .contentTransition(.numericText()) // 数字滚动动画
                }
                
            case .training:
                // 3. 训练进行中
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
                // 4. 结束
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
            // 【关键修改】页面一显示，立刻开始，无需点击
            manager.startSession()
        }
    }
}

#Preview {
    GripView()
}
