import SwiftUI
import SwiftData // <--- 1. 引入

@main
struct RRehabApp: App {
    var body: some Scene {
        WindowGroup {
            PhoneHomeView()
        }
        // 2. 注入容器
        .modelContainer(for: TrainingRecord.self)
    }
}
