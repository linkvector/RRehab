import Foundation
import SwiftData

@Model
class TrainingRecord {
    // 训练类型 (存字符串即可，方便以后扩展)
    var typeName: String
    
    // 核心数据
    var count: Int          // 次数
    var warningCount: Int   // 加油次数
    var duration: Int       // 时长(秒)
    
    // 时间戳
    var timestamp: Date
    
    init(typeName: String, count: Int, warningCount: Int, duration: Int, timestamp: Date = Date()) {
        self.typeName = typeName
        self.count = count
        self.warningCount = warningCount
        self.duration = duration
        self.timestamp = timestamp
    }
}
