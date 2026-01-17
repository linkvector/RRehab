import Foundation
import SwiftUI
import Combine
import WatchConnectivity
import AVFoundation

enum ActivityType: String {
    case grip = "握力训练"
    case armWakeup = "悬臂唤醒"
    case wrist = "转腕训练"
}

class ConnectivityManager: NSObject, ObservableObject, WCSessionDelegate {
    
    static let shared = ConnectivityManager()
    
    @Published var isReachable: Bool = false
    @Published var lastMessage: String = ""
    
    // 流程控制
    @Published var isMonitoring: Bool = false
    @Published var showResultPage: Bool = false
    @Published var showGripTraining: Bool = false
    
    // 当前训练类型
    @Published var currentActivity: ActivityType = .grip
    
    // 结果数据
    @Published var finalReps: Int = 0
    @Published var finalWarnings: Int = 0
    
    private let synthesizer = AVSpeechSynthesizer()
    
    override private init() {
        super.init()
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
        
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .voicePrompt)
        try? AVAudioSession.sharedInstance().setActive(true)
    }
    
    // MARK: - 发送功能
    func sendMessage(_ data: [String: Any]) {
        print("📤 准备发送数据: \(data)")
        WCSession.default.sendMessage(data, replyHandler: nil) { error in
            print("❌ 发送失败: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 接收功能 (实时消息)
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        processIncomingData(message)
    }
    
    // MARK: - 接收功能 (数据补丁：机制一实现)
    // 当手表熄屏后数据被挂起，一旦亮屏或后台同步，此方法会被触发
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        print("📦 收到 ApplicationContext 补丁数据")
        processIncomingData(applicationContext)
    }
    
    private func processIncomingData(_ data: [String: Any]) {
        DispatchQueue.main.async {
            print("📩 处理数据内容: \(data)")
            self.lastMessage = data.description
            
            if let command = data["command"] as? String {
                self.handleCommand(command, data: data)
            }
        }
    }
    
    private func handleCommand(_ command: String, data: [String: Any]) {
        switch command {
        case "training_started":
            print("💪 确认：手表已开始训练")
            self.isMonitoring = true
            self.showResultPage = false
            
            // 在 ConnectivityManager.swift 的 didReceiveMessage 中
            case "training_finished":
                self.isMonitoring = false   // 关闭监控全屏页
                self.showResultPage = false // 确保不显示结果页弹窗
                
                // 发送跳转通知给 PhoneHomeView
                NotificationCenter.default.post(name: NSNotification.Name("AutoSwitchToStats"), object: nil)
            
            
            if let reps = data["totalReps"] as? Int,
               let warns = data["warnings"] as? Int {
                self.finalReps = reps
                self.finalWarnings = warns
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.showResultPage = true
            }
            
        case "play_jiayou":
            self.speak("加油，加油，别放弃！")
            
        case "start_grip_training":
            // 针对手机遥控手表的跳转逻辑优化
            self.showGripTraining = false
            self.currentActivity = .grip
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.showGripTraining = true
            }
            
        default: break
        }
    }
    
    private func speak(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "zh-CN")
        synthesizer.speak(utterance)
    }
    
    // MARK: - WCSession 生命周期
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
        }
    }
    
    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
    #endif
}
