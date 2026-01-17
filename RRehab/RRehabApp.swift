import SwiftUI
import SwiftData

@main
struct RRehabApp: App {
    // 1. 在 App 顶层创建唯一的 AppState 实例
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            // 2. 将实例注入到根视图 PhoneHomeView 中
            PhoneHomeView()
                .environmentObject(appState)
                // 同时确保 SwiftData 容器也在此注入
                .modelContainer(for: TrainingRecord.self)
        }
    }
}
