//
//  CallManager.swift
//  Agora Demo
//
//  Created by iOS Team on 16/07/25.
//


import Foundation
import CallKit
import AVFoundation
import UIKit

class CallManager: NSObject {
    static let shared = CallManager()
    
    private var provider: CXProvider!
    private var callController = CXCallController()
    var agoraManager: AgoraManager?
    var currentChannelName: String?
    var callUUID: UUID?
    
    override init() {
        let config = CXProviderConfiguration(localizedName: "Agora VideoCall")
        config.supportsVideo = true
        config.includesCallsInRecents = true
        config.supportedHandleTypes = [.generic]
        config.maximumCallsPerCallGroup = 1
        config.iconTemplateImageData = UIImage(systemName: "phone")?.pngData()
        provider = CXProvider(configuration: config)
        super.init()
        provider.setDelegate(self, queue: nil)
    }

//    func startCall(channelName: String) {
//        let handle = CXHandle(type: .generic, value: channelName)
//        let uuid = UUID()
//        self.callUUID = uuid 
//        let action = CXStartCallAction(call: uuid, handle: handle)
//        let transaction = CXTransaction(action: action)
//        requestTransaction(transaction)
//    }

    func endCall() {
        print("✅ callUUID: \(String(describing: callUUID))")
        guard let uuid = callUUID else {
            print("❌ No active call UUID to end.")
            return
        }
        let action = CXEndCallAction(call: uuid)
        let transaction = CXTransaction(action: action)
        requestTransaction(transaction)
    }
    
    func reportIncomingCall(from caller: String, channelName: String) {
        try? AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .videoChat, options: [.allowBluetooth,.defaultToSpeaker])
        try? AVAudioSession.sharedInstance().setActive(true)
        currentChannelName = channelName
        let update = CXCallUpdate()
        update.localizedCallerName = caller
        update.hasVideo = true
        let uuid = UUID()
        self.callUUID = uuid
        print("✅ callUUID: \(String(describing: callUUID))")
        provider.reportNewIncomingCall(with: self.callUUID! , update: update) { error in
            if let error = error {
                print("❌ CallKit report error: \(error)")
            } else {
                print("✅ Incoming call reported")
            }
        }
    }
    
    private func requestTransaction(_ transaction: CXTransaction) {
        callController.request(transaction) { error in
            if let error = error {
                print("❌ CallKit transaction error: \(error)")
            } else {
                print("✅ CallKit transaction requested.")
            }
        }
    }
    
    func presentVideoCallScreen(completion: (() -> Void)? = nil) {
        guard let rootVC = UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            print("❌ Couldn't get root view controller")
            return
        }
        if rootVC.presentedViewController is VideoCallVC {
            print("ℹ️ VideoCallVC is already presented")
            return
        }
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let videoCallVC = storyboard.instantiateViewController(withIdentifier: "VideoCallVC") as? VideoCallVC {
            videoCallVC.modalPresentationStyle = .fullScreen
            videoCallVC.modalTransitionStyle = .crossDissolve
            rootVC.present(videoCallVC, animated: true, completion: {
                completion?()
            })
        }
    }
    
    func dismissVideoCallScreen() {
        guard let rootVC = UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            print("❌ Couldn't get root view controller")
            return
        }

        if let presented = rootVC.presentedViewController as? VideoCallVC {
            self.agoraManager?.leaveChannel()
            presented.dismiss(animated: true, completion: {
                print("✅ VideoCallVC dismissed")
            })
        } else {
            print("ℹ️ No VideoCallVC to dismiss")
        }
    }
}

extension CallManager: CXProviderDelegate{
    func providerDidReset(_ provider: CXProvider) {
        print("🔄 CallKit provider reset")
    }
    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        print("📞 CXAnswerCallAction")
        action.fulfill()
    }
    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        print("📞 CXStartCallAction")
        currentChannelName = action.handle.value
        action.fulfill()
    }
    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        print("📞 CXEndCallAction")
        action.fulfill()
    }
    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        print("✅ didActivate: video session active")
        try? AVAudioSession.sharedInstance().setCategory(.playAndRecord,
                                                         mode: .videoChat,
                                                         options: [.allowBluetooth, .defaultToSpeaker])
        try? AVAudioSession.sharedInstance().setActive(true)
        
        DispatchQueue.main.async {
            self.presentVideoCallScreen { [weak self] in
                // ✅ Only end CallKit after UI is on screen
                guard let uuid = self?.callUUID else { return }
                let callObserver = CXCallObserver()
                let activeCalls = callObserver.calls
                print("✅ callUUID: \(String(describing: self?.callUUID))")
                print("📞 Active calls:", activeCalls.map { $0.uuid })
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    let endAction = CXEndCallAction(call: uuid)
                    let transaction = CXTransaction(action: endAction)
                    self?.callController.request(transaction) { error in
                        if let error = error {
                            print("❌ Failed to end CallKit: \(error)")
                        } else {
                            print("✅ CallKit call ended to hide system UI")
                        }
                    }
                }
            }
        }
    }
    func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        print("✅ didDeactivate: video session inactive")
        dismissVideoCallScreen()
    }
}
