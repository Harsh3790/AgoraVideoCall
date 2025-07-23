//
//  VideoCallVC.swift
//  Agora Demo
//
//  Created by iOS Team on 15/07/25.
//

import UIKit
import IBAnimatable
import AgoraRtcKit
import CallKit

class VideoCallVC: UIViewController {
    
    //MARK: OUTLETS
    @IBOutlet weak var localView: AnimatableView!
    @IBOutlet weak var remoteView: AnimatableView!
    @IBOutlet weak var localImage: AnimatableImageView!
    @IBOutlet weak var remoteImage: AnimatableImageView!
    @IBOutlet weak var lblTimer: UILabel!
    private let agora =  AgoraManager.shared
    private let callManager = CallManager.shared
    var callTimer: Timer?
    var totalSeconds = 0
    
    //MARK: VIEW LIFE CYCLE METHOD
    override func viewDidLoad() {
        super.viewDidLoad()
        self.remoteImage.isHidden = false
        self.lblTimer.text = "Calling..."
        agora.joinChannel(channelName: "harsh_Demo")
        setupLocalVideo(isLocalView: false)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        setupAgoraClosures()
    }
    
    deinit {
        print("❌ VideoCallVC deinitialized")
        clearAgoraClosures()
    }
    
    func setupAgoraClosures() {
        agora.closureRemoteView = { [weak self] uid in
            guard let self = self else { return }
            let videoCanvas = AgoraRtcVideoCanvas()
            videoCanvas.uid = uid
            videoCanvas.view = self.remoteView
            videoCanvas.renderMode = .hidden
            agora.agoraKit.setupRemoteVideo(videoCanvas)
            self.remoteImage.isHidden = true
            startCallTimer()
        }
        agora.closureRemoteViewOnOff = { [weak self] muted in
            guard let self = self else { return }
            let videoCanvas = AgoraRtcVideoCanvas()
            videoCanvas.view = muted ? nil : self.remoteView
            videoCanvas.renderMode = .hidden
            if !muted{
                agora.agoraKit.setupRemoteVideo(videoCanvas)
            }
            self.remoteImage.isHidden = muted ? false : true
            self.remoteView.isHidden = muted ? true : false
            self.remoteView.backgroundColor = muted ? .systemGray3 : .clear
            print(self.remoteImage.isHidden)
        }
        agora.closureCallLeft = { [weak self] in
            guard let self = self else { return }
            leftCall()
        }
    }
    
    func startCallTimer() {
        totalSeconds = 0
        self.lblTimer.text = "00:00:00"
        callTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.totalSeconds += 1
            let hours = self.totalSeconds / 3600
            let minutes = (self.totalSeconds % 3600) / 60
            let seconds = self.totalSeconds % 60
            self.lblTimer.text = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        }
    }
    
    func leftCall() {
        agora.leaveChannel()
        callManager.endCall()
        callTimer?.invalidate()
        callTimer = nil
        self.dismiss(animated: true)
    }
    
    private func clearAgoraClosures() {
        agora.closureRemoteView = { _ in }
        agora.closureRemoteViewOnOff = { _ in }
        agora.closureCallLeft = nil
    }
    
    func setupLocalVideo(isLocalView: Bool) {
        let videoCanvas = AgoraRtcVideoCanvas()
        videoCanvas.uid = 0
        videoCanvas.view = isLocalView ? nil : localView
        videoCanvas.renderMode = .hidden
        agora.agoraKit.setupLocalVideo(videoCanvas)
        agora.agoraKit.startPreview()
        localView.backgroundColor = isLocalView ? UIColor.systemGray3 : .clear
        localImage.isHidden = !isLocalView
    }
        
//    func requestAgoraToken(userId: Int, channel: String, completion: @escaping (String, Int, String) -> Void) {
//        let url = URL(string: "https://yourserver.com/agora/token")!
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        
//        let payload: [String: Any] = [
//            "channelName": channel,
//            "uid": userId,
//            "role": "publisher"
//        ]
//        
//        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//
//        URLSession.shared.dataTask(with: request) { data, response, error in
//            if let data = data,
//               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
//               let token = json["token"] as? String,
//               let uid = json["uid"] as? Int,
//               let channelName = json["channelName"] as? String{
//                completion(token, uid, channelName)
//            } else {
//                print("❌ Failed to get token")
//            }
//        }.resume()
//    }
    
    @IBAction func tapChangeCameraBtn(_ sender: UIButton) {
        agora.agoraKit.switchCamera()
    }
    @IBAction func tapCallEndBtn(_ sender: UIButton) {
        leftCall()
    }
    @IBAction func tapMicrophoneBtn(_ sender: UIButton) {
        sender.isSelected.toggle()
        let isMuted = sender.isSelected
        agora.agoraKit.muteLocalAudioStream(isMuted)
        sender.setImage(UIImage(systemName: isMuted ? "microphone.slash.fill" : "microphone.fill"), for: .normal)
    }
    @IBAction func tapCameraOnOffBtn(_ sender: UIButton) {
        sender.isSelected.toggle()
        let isCameraOff = sender.isSelected
        agora.agoraKit.muteLocalVideoStream(isCameraOff)
        setupLocalVideo(isLocalView: isCameraOff)
        sender.setImage(UIImage(systemName: isCameraOff ? "camera.badge.clock.fill" : "camera.shutter.button.fill"), for: .normal)
    }
    @IBAction func tapSpeakerBtn(_ sender: UIButton) {
        sender.isSelected.toggle()
        let isSpeakerOff = sender.isSelected
        agora.agoraKit.setEnableSpeakerphone(isSpeakerOff)
        sender.setImage(UIImage(systemName: isSpeakerOff ? "speaker.slash.fill" : "speaker.fill"), for: .normal)
    }
}
