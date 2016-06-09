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
    
    private var timerAutoDismiss : NSTimer?
    var delegate : TopMessageViewDelegate?
    
    override func getNibName() -> String {
        return "TopMessageView";
    }
    
    override func setup() {
    }
    
    func updateMessage(newMessage message: String) {
        messageLabel.text = message
        messageLabel.textColor = UIColor.whiteColor()
        backgroundView.backgroundColor = UIColor(RRGGBB: UInt(0x9199CB))
        backgroundView.alpha = 0.9
        closeButton.hidden = true
        self.timerAutoDismiss?.invalidate()
        self.timerAutoDismiss = nil
        self.timerAutoDismiss = NSTimer.scheduledTimerWithTimeInterval(2, target: self, selector: #selector(TopMessageView.timerTriggered), userInfo: nil, repeats: false)
    }
    
    func timerTriggered() {
        self.timerAutoDismiss?.invalidate()
        self.timerAutoDismiss = nil
        delegate?.close()
    }
    
    func updateMessage(timeOut message: String) {
        messageLabel.text = message
        messageLabel.textColor = UIColor.whiteColor()
        backgroundView.backgroundColor = UIColor.redColor()
        backgroundView.alpha = 0.9
        closeButton.hidden = false
    }
    
    func updateMessage(noInternet message : String) {
        messageLabel.text = message
        messageLabel.textColor = UIColor.whiteColor()
        backgroundView.backgroundColor = UIColor.redColor()
        backgroundView.alpha = 0.9
        closeButton.hidden = false
    }
    
    func updateMessage(errorMsg message : String) {
        messageLabel.text = message
        messageLabel.textColor = UIColor.whiteColor()
        backgroundView.backgroundColor = UIColor.lightGrayColor()
        backgroundView.alpha = 0.9
        closeButton.hidden = true
    }
    
    func updateMessage(error error : NSError) {
        messageLabel.text = error.localizedDescription
        messageLabel.textColor = UIColor.whiteColor()
        backgroundView.backgroundColor = UIColor.lightGrayColor()
        backgroundView.alpha = 0.9
        closeButton.hidden = true
    }
    
    @IBAction func closeAction(sender: UIButton) {
        delegate?.retry()
        //delegate?.close()
    }

}