import SwiftUI
import SwiftData // 1. 引入数据库框架

struct PhoneResultView: View {
    @StateObject var connectivity = ConnectivityManager.shared
    @Environment(\.dismiss) var dismiss
    
    // 2.以此获取数据库的操作权限
    @Environment(\.modelContext) var modelContext
    
    var body: some View {
        VStack(spacing: 30) {
            
            // 标题
            Text("\(connectivity.currentActivity.rawValue)报告")
                .font(.headline)
                .foregroundColor(.gray)
                .padding(.top, 50)
            
            // 动态内容展示
            switch connectivity.currentActivity {
            case .grip:
                GripResultContent(reps: connectivity.finalReps, warnings: connectivity.finalWarnings)
            case .armWakeup:
                Text("悬臂唤醒数据展示区").foregroundColor(.orange).frame(height: 200)
            case .wrist:
                Text("转腕训练数据展示区").foregroundColor(.blue).frame(height: 200)
            }
            
            Spacer()
            
            // 完成并保存按钮
            Button(action: {
                saveAndDismiss()
            }) {
                Text("完成并保存")
                    .font(.title3)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(15)
            }
            .padding(.horizontal)
            .padding(.bottom, 30)
        }
        .background(Color(UIColor.systemBackground))
    }
    
    // 3. 保存逻辑
    func saveAndDismiss() {
        print("💾 正在保存数据...")
        
        let record = TrainingRecord(
            typeName: connectivity.currentActivity.rawValue, // 例如 "握力训练"
            count: connectivity.finalReps,
            warningCount: connectivity.finalWarnings,
            duration: 43, // 目前固定，以后可动态传
            timestamp: Date()
        )
        
        // 插入数据库
        modelContext.insert(record)
        
        // 关闭页面
        dismiss()
    }
}

// 握力展示组件 (保持不变)
struct GripResultContent: View {
    let reps: Int
    let warnings: Int
    
    var body: some View {
        VStack(spacing: 30) {
            ZStack {
                Circle().stroke(Color.green.opacity(0.2), lineWidth: 20).frame(width: 200, height: 200)
                Circle().trim(from: 0, to: 1.0).stroke(Color.green, style: StrokeStyle(lineWidth: 20, lineCap: .round)).frame(width: 200, height: 200).rotationEffect(.degrees(-90))
                VStack {
                    Text("\(reps)").font(.system(size: 60, weight: .bold)).foregroundColor(.primary)
                    Text("次握力").font(.title3).foregroundColor(.secondary)
                }
            }
            HStack(spacing: 20) {
                ResultInfoCard(title: "被加油", value: "\(warnings)", unit: "次", color: .orange)
                ResultInfoCard(title: "总时长", value: "43", unit: "秒", color: .blue)
            }
            .padding(.horizontal)
        }
    }
}

struct ResultInfoCard: View {
    let title: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 10) {
            Text(title).font(.caption).foregroundColor(.gray)
            HStack(alignment: .lastTextBaseline) {
                Text(value).font(.title).fontWeight(.bold).foregroundColor(color)
                Text(unit).font(.caption).foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity).padding().background(Color(UIColor.secondarySystemBackground)).cornerRadius(12)
    }
}
