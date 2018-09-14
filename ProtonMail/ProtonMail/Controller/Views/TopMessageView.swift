//
//  TopMessageView.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 6/3/16.
//  Copyright © 2016 ProtonMail. All rights reserved.
//

import Foundation




protocol TopMessageViewDelegate {
    func retry()
    func close()
}

class TopMessageView : PMView {

    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet var backgroundView: UIView!
    @IBOutlet weak var messageLabel: UILabel!
    
    fileprivate var timerAutoDismiss : Timer?
    var delegate : TopMessageViewDelegate?
    
    override func getNibName() -> String {
        return "TopMessageView";
    }
    
    override func setup() {
        closeButton.setTitle(LocalString._retry, for: .normal)
    }
    
    func message(string message: String) -> CGFloat {
        messageLabel.text = message
        messageLabel.textColor = UIColor.white
        backgroundView.backgroundColor = UIColor(RRGGBB: UInt(0x9199CB))
        backgroundView.alpha = 0.9
        messageLabel.sizeToFit()
        closeButton.isHidden = true
        self.timerAutoDismiss?.invalidate()
        self.timerAutoDismiss = nil
        self.timerAutoDismiss = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(TopMessageView.timerTriggered), userInfo: nil, repeats: false)
        return (messageLabel.frame.height + 16)
    }
    
    @objc func timerTriggered() {
        self.timerAutoDismiss?.invalidate()
        self.timerAutoDismiss = nil
        delegate?.close()
    }
    
    func message(timeOut message: String) -> CGFloat {
        messageLabel.text = message
        messageLabel.textColor = UIColor.white
        backgroundView.backgroundColor = UIColor.red
        backgroundView.alpha = 0.9
        messageLabel.sizeToFit()
        closeButton.isHidden = false
        return (messageLabel.frame.height + 16)
    }
    
    func message(noInternet message : String) -> CGFloat {
        messageLabel.text = message
        messageLabel.textColor = UIColor.white
        backgroundView.backgroundColor = UIColor.red
        backgroundView.alpha = 0.9
        messageLabel.sizeToFit()
        closeButton.isHidden = false
        return (messageLabel.frame.height + 16)
    }
    
    func message(errorMsg message : String) -> CGFloat {
        messageLabel.text = message
        messageLabel.textColor = UIColor.white
        backgroundView.backgroundColor = UIColor.lightGray
        backgroundView.alpha = 0.9
        messageLabel.sizeToFit()
        closeButton.isHidden = true
        return (messageLabel.frame.height + 16)
    }
    
    func message(error : NSError) -> CGFloat {
        messageLabel.text = error.localizedDescription
        messageLabel.textColor = UIColor.white
        backgroundView.backgroundColor = UIColor.lightGray
        backgroundView.alpha = 0.9
        messageLabel.sizeToFit()
        closeButton.isHidden = true
        return (messageLabel.frame.height + 16)
    }
    
    @IBAction func closeAction(_ sender: UIButton) {
        delegate?.retry()
        //delegate?.close()
    }

}
