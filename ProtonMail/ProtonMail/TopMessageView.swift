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
    }
    
    func updateMessage(timeOut message: String) {
        messageLabel.text = message
        messageLabel.textColor = UIColor.whiteColor()
        backgroundView.backgroundColor = UIColor.lightGrayColor()
    }
    
    func updateMessage(noInternet message : String) {
        messageLabel.text = message
        messageLabel.textColor = UIColor.whiteColor()
        backgroundView.backgroundColor = UIColor.lightGrayColor()
    }
    
    func updateMessage(errorMsg message : String) {
        messageLabel.text = message
        messageLabel.textColor = UIColor.whiteColor()
        backgroundView.backgroundColor = UIColor.lightGrayColor()
    }
    
    func updateMessage(error error : NSError) {
        messageLabel.text = error.localizedDescription
        messageLabel.textColor = UIColor.whiteColor()
        backgroundView.backgroundColor = UIColor.lightGrayColor()
    }
    
    @IBAction func closeAction(sender: UIButton) {
        delegate?.close()
    }

}