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
    let token: String = "007eJxTYJC4227I2OV3+RXb6i8it69Nb2/b/3LBlx5lQ7a4+1r5XqcUGJISzcwTzQwSLZKMU0wSkyySjIzMUkwtTIyN0wxNLCzMOZ43ZjQEMjJsPc7IxMgAgSA+F0NGYlFxRrxLam4+AwMAUZwiMg=="
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
        agoraKit.joinChannel(byToken: token, channelId: channelName, info: nil, uid: 0) { [weak self] _, _, _ in
            guard let self = self else{ return }
            presentVideoCallScreen()
        }
    }
    func presentVideoCallScreen() {
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
            rootVC.present(videoCallVC, animated: true, completion: nil)
        }
    }
    
    func leaveChannel() {
        agoraKit.leaveChannel(nil)
        agoraKit.stopPreview()
        print("✅ Left channel")
    }
    
    func switchCamera(){
        agoraKit.switchCamera()
    }
    
    func muteCall(isMute: Bool){
        agoraKit.muteLocalAudioStream(isMute)
    }
    
    func muteLocalVideoStream(isCameraOff: Bool){
        agoraKit.muteLocalVideoStream(isCameraOff)
    }
    
    func setEnableSpeakerphone(isSpeakerOff: Bool){
        agoraKit.setEnableSpeakerphone(isSpeakerOff)
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
        leaveChannel()
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didVideoMuted muted: Bool, byUid uid: UInt) {
        print("🎥 Remote video \(muted ? "stopped" : "resumed") by uid: \(uid)")
        self.closureRemoteViewOnOff(muted)
    }
}
