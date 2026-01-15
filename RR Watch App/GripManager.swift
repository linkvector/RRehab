import Foundation
import SwiftUI
import Combine
import CoreMotion
import WatchKit
import AVFoundation

enum GripSessionState {
    case idle
    case preparing
    case training
    case finished
}

class GripManager: ObservableObject {
    
    // UI 状态
    @Published var state: GripSessionState = .idle
    @Published var count: Int = 0
    @Published var countdown: Int = 3
    @Published var warningCount: Int = 0
    
    // 【新增】通知 View 关闭页面的信号
    @Published var shouldDismiss: Bool = false
    
    // 私有变量
    private var timer: Timer?
    private let motionManager = CMMotionManager()
    private var lastMotionTime: Date = Date()
    
    // 【新增】记录上一次的加速度数据，用于对比微动
    private var lastAcceleration: CMAcceleration?
    
    // 配置
    let totalReps = 20
    let interval = 2.0
    
    // MARK: - 1. 开始流程
    func startSession() {
        reset()
        DispatchQueue.main.async {
            self.state = .preparing
            self.countdown = 3
        }
        
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
    
    // MARK: - 2. 训练主循环
    private func beginTraining() {
        DispatchQueue.main.async {
            self.state = .training
            self.count = 0
            // 每次开始前，更新一下最后动作时间，给用户一点缓冲
            self.lastMotionTime = Date()
        }
        startMotionMonitoring()
        
        playRhythmSound()
        
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { t in
            DispatchQueue.main.async {
                self.count += 1
                
                // 检查动作
                self.checkMotionStatus()
                
                if self.count >= self.totalReps {
                    t.invalidate()
                    self.finishSession()
                } else {
                    self.playRhythmSound()
                }
            }
        }
    }
    
    // MARK: - 3. 【核心升级】微动作监测逻辑
    private func startMotionMonitoring() {
        guard motionManager.isAccelerometerAvailable else { return }
        // 采样率提高到 20Hz (0.05秒一次)，捕捉更细腻的震动
        motionManager.accelerometerUpdateInterval = 0.05
        
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] (data, error) in
            guard let self = self, let data = data else { return }
            
            let currentAcc = data.acceleration
            
            if let lastAcc = self.lastAcceleration {
                // 算法：计算 X/Y/Z 三轴变化的绝对值之和 (Delta)
                // 这种方式不依赖手表的角度，只看“变没变”
                let deltaX = abs(currentAcc.x - lastAcc.x)
                let deltaY = abs(currentAcc.y - lastAcc.y)
                let deltaZ = abs(currentAcc.z - lastAcc.z)
                let totalDelta = deltaX + deltaY + deltaZ
                
                // 【灵敏度调节】
                // 0.05 是一个非常敏感的阈值。
                // 握紧拳头时，肌肉震颤通常会产生 > 0.05 ~ 0.1 的瞬间变化
                if totalDelta > 0.05 {
                    self.lastMotionTime = Date()
                    // print("动了: \(totalDelta)") // 调试用
                }
            }
            
            // 保存这次的数据，供下一次对比
            self.lastAcceleration = currentAcc
        }
    }
    
    private func checkMotionStatus() {
        let timeSinceLastMove = Date().timeIntervalSince(lastMotionTime)
        // 稍微放宽一点判定时间，给到 2.2个周期
        if timeSinceLastMove > (interval * 2.2) {
            triggerWarning()
        }
    }
    
    // MARK: - 4. 反馈与结束
    private func playRhythmSound() {
        WKInterfaceDevice.current().play(.directionUp)
    }
    
    private func triggerWarning() {
        warningCount += 1
        lastMotionTime = Date() // 重置，避免立刻再次报警
        WKInterfaceDevice.current().play(.failure) // 失败音效更明显
        print("发送给手机：加油！")
    }
    
    private func finishSession() {
        DispatchQueue.main.async {
            self.state = .finished
        }
        motionManager.stopAccelerometerUpdates()
        WKInterfaceDevice.current().play(.success)
        
        // 【关键逻辑】2秒后，通知 View 退出
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.shouldDismiss = true
        }
    }
    
    private func reset() {
        DispatchQueue.main.async {
            self.count = 0
            self.warningCount = 0
            self.lastMotionTime = Date()
            self.shouldDismiss = false
            self.lastAcceleration = nil
        }
    }
}
