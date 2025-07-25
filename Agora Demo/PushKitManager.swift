//
//  PushKitManager.swift
//  Agora Demo
//
//  Created by iOS Team on 17/07/25.
//

import Foundation
import PushKit
import CallKit

class PushKitManager: NSObject {
    static let shared = PushKitManager()
    
    private let pushRegistry: PKPushRegistry
    var callManager = CallManager.shared
    var voipToken: String = ""
    var onTokenReceived: ((String) -> ())?
    
    override init() {
        pushRegistry = PKPushRegistry(queue: .main)
        super.init()
        pushRegistry.delegate = self
        pushRegistry.desiredPushTypes = [.voIP]
    }
}

extension PushKitManager: PKPushRegistryDelegate {
    func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
        let tokenString = pushCredentials.token.map { String(format: "%02x", $0) }.joined()
        voipToken = tokenString
        print("✅ VoIP Token: \(tokenString)")
        // Upload token to your backend here!
        onTokenReceived?(tokenString)
    }
    func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
        print("fail :\(type)")
    }
    func pushRegistry(_ registry: PKPushRegistry,
                      didReceiveIncomingPushWith payload: PKPushPayload,
                      for type: PKPushType,
                      completion: @escaping () -> Void) {
        print("📲 VoIP Push received: \(payload.dictionaryPayload)")
        guard let caller = payload.dictionaryPayload["callerName"] as? String,
              let channelName = payload.dictionaryPayload["channelName"] as? String,
              let status = payload.dictionaryPayload["status"] as? String else { return }
        UserDefaults.standard.set(2, forKey: "localUserID")
        if status == "rejected"{
            self.callManager.endCall()
        }else {
            self.callManager.reportIncomingCall(from: caller, channelName: channelName)
        }
        completion()
    }
}
