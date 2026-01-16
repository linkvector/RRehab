import Foundation
import SwiftUI
import Combine
import CoreMotion
import WatchKit
import WatchConnectivity

// 1. 定义状态
enum GripSessionState {
    case idle, preparing, training, finished
}

class GripManager: NSObject, ObservableObject {
    
    // 必须使用 @Published 才能让 UI 感知变化
    @Published var state: GripSessionState = .idle
    @Published var count: Int = 0
    @Published var countdown: Int = 3
    @Published var warningCount: Int = 0
    @Published var shouldDismiss: Bool = false
    
    // 引用单例联络官
    private let connectivity = ConnectivityManager.shared
    
    private var timer: Timer?
    private let motionManager = CMMotionManager()
    private var lastMotionTime: Date = Date()
    private var lastAcceleration: CMAcceleration?
    
    // 训练配置
    let totalReps = 20
    let interval = 2.0 // 动作间隔
    
    // MARK: - 启动训练流程
    func startSession() {
        reset()
        DispatchQueue.main.async {
            self.state = .preparing
            self.countdown = 3
        }
        
        // 机制一补丁：即使熄屏，也要更新上下文状态
        try? WCSession.default.updateApplicationContext(["command": "training_started"])
        connectivity.sendMessage(["command": "training_started"])
        
        // 3-2-1 倒计时逻辑
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { t in
            DispatchQueue.main.async {
                if self.countdown > 1 {
                    self.countdown -= 1
                    WKInterfaceDevice.current().play(.click)
                } else {
                    t.invalidate()
                    self.beginTraining()
                }
            }
        }
    }
    
    // MARK: - 正式进入训练
    private func beginTraining() {
        DispatchQueue.main.async {
            self.state = .training
            self.count = 0
            self.lastMotionTime = Date()
        }
        startMotionMonitoring()
        
        // 训练节奏计时器
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { t in
            DispatchQueue.main.async {
                self.count += 1
                self.checkMotionStatus() // 检查是否偷懒
                
                if self.count >= self.totalReps {
                    t.invalidate()
                    self.finishSession()
                } else {
                    WKInterfaceDevice.current().play(.directionUp) // 每下节奏震动
                }
            }
        }
    }
    
    // MARK: - 传感器监控 (核心算法)
    private func startMotionMonitoring() {
        guard motionManager.isAccelerometerAvailable else { return }
        motionManager.accelerometerUpdateInterval = 0.1
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] (data, error) in
            guard let self = self, let data = data else { return }
            let currentAcc = data.acceleration
            
            if let lastAcc = self.lastAcceleration {
                // 计算三个轴的变化量
                let delta = abs(currentAcc.x - lastAcc.x) +
                            abs(currentAcc.y - lastAcc.y) +
                            abs(currentAcc.z - lastAcc.z)
                
                // 如果动作幅度超过阈值，更新最后动作时间
                if delta > 0.1 {
                    self.lastMotionTime = Date()
                }
            }
            self.lastAcceleration = currentAcc
        }
    }
    
    // 检查是否长期未动
    private func checkMotionStatus() {
        let timeSinceLastMove = Date().timeIntervalSince(lastMotionTime)
        if timeSinceLastMove > (interval * 2.1) {
            triggerWarning()
        }
    }
    
    private func triggerWarning() {
        warningCount += 1
        lastMotionTime = Date() // 重置，防止连续报警太频繁
        WKInterfaceDevice.current().play(.failure)
        
        // 发送加油信号到手机
        connectivity.sendMessage(["command": "play_jiayou"])
    }
    
    // MARK: - 结束训练
    private func finishSession() {
        DispatchQueue.main.async { self.state = .finished }
        motionManager.stopAccelerometerUpdates()
        
        // 强震动提示
        WKInterfaceDevice.current().play(.success)
        
        let resultData: [String: Any] = [
            "command": "training_finished",
            "totalReps": self.count,
            "warnings": self.warningCount
        ]
        
        // 核心补丁：双通道发送数据
        try? WCSession.default.updateApplicationContext(resultData)
        connectivity.sendMessage(resultData)
        
        // 2秒后自动退出界面
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.shouldDismiss = true
        }
    }
    
    private func reset() {
        self.count = 0
        self.warningCount = 0
        self.shouldDismiss = false
        self.lastAcceleration = nil
        self.lastMotionTime = Date()
    }
}
