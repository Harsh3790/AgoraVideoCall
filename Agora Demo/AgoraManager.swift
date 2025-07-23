//
//  AgoraManager.swift
//  Agora Demo
//
//  Created by iOS Team on 16/07/25.
//

import Foundation
import AgoraRtcKit
import UIKit

class AgoraManager: NSObject {
    static let shared = AgoraManager()

    var agoraKit: AgoraRtcEngineKit!
    let appID = "ba67a60a8b3d4ab8b226d58433f14887"
    let token: String = "007eJxTYDCcba9jvHhPiNL0O3dXXDvL6fkh8Y45j96Z6ui4uvm6gtcVGIyMjU0TLVItjIyMzU2Mjc0tzI2NjA1SLc1NjRJTTUwTuVMaMhoCGRlS3nxnYWSAQBCfiyEjsag4I94lNTefgQEAnEQgMA=="
    var channelName: String = "harsh_Demo"
    var closureRemoteView: ((UInt) -> ()) = {_ in}
    var closureRemoteViewOnOff: ((Bool) -> ()) = {_ in}
    var closureCallLeft: (() -> ())?
    
    override init() {
        super.init()
        initializeAgora()
    }

    func initializeAgora() {
        agoraKit = AgoraRtcEngineKit.sharedEngine(withAppId: appID, delegate: self)
    }
    
    func joinChannel(channelName: String) {
        agoraKit.setAudioSessionOperationRestriction(.all)
        agoraKit.enableAudio()
        agoraKit.enableVideo()
        agoraKit.muteLocalVideoStream(false)
        agoraKit.muteAllRemoteVideoStreams(false)
        agoraKit.setChannelProfile(.communication)
        agoraKit.joinChannel(byToken: token, channelId: channelName, info: nil, uid: 2) { [weak self] _, _, _ in
            guard let self = self else{ return }
            print("✅ Joined channel: \(self.channelName)")
        }
    }

    func leaveChannel() {
        agoraKit.leaveChannel(nil)
        agoraKit.stopPreview()
        print("✅ Left channel")
    }
}

extension AgoraManager: AgoraRtcEngineDelegate {
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinChannel channel: String, withUid uid: UInt, elapsed: Int) {
        print("Successfully joined channel: \(channel) with UID: \(uid)")
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
        print("👤 Remote user joined with uid: \(uid)")
        closureRemoteView(uid)
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOfflineOfUid uid: UInt, reason: AgoraUserOfflineReason) {
        print("❌ Remote user left")
        self.closureCallLeft?()
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didVideoMuted muted: Bool, byUid uid: UInt) {
        print("🎥 Remote video \(muted ? "stopped" : "resumed") by uid: \(uid)")
        self.closureRemoteViewOnOff(muted)
    }
}
