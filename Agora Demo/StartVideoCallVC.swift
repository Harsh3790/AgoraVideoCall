//
//  StartVideoCallVC.swift
//  Agora Demo
//
//  Created by iOS Team on 16/07/25.
//

import UIKit
import IBAnimatable

class StartVideoCallVC: UIViewController {

    @IBOutlet weak var startVCBtn: AnimatableButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
    }
    
    @IBAction func tapStartVideoCall(_ sender: Any) {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "VideoCallVC") as! VideoCallVC
        vc.modalTransitionStyle = .crossDissolve
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated: true)
    }
}

/*
 curl -v \
 --cert voip.pem \
 --key voip.pem \
 -H "apns-topic: com.rahulDemo.voip" \
 -H "apns-push-type: voip" \
 -d '{
 "aps": {
 "content-available": 1
 },
 "callerName": "Harsh",
 "channelName": "harsh_Demo",
 "status": "incoming" or "rejected"
 }' \
 --http2 \
 https://api.sandbox.push.apple.com:443/3/device/b9450d80ed8f81cb188259975146a8367bca89dc17e678f126b257b94bbebc3d
 */
