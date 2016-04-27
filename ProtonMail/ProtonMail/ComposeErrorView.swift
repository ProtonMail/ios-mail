//
//  ComposeErrorView.swift
//  
//
//  Created by Yanfeng Zhang on 3/14/16.
//
//

import UIKit

class ComposeErrorView: PMView {

    
    @IBOutlet weak var errorLabel: UILabel!
    override func getNibName() -> String {
        return "ComposeErrorView"
    }
    
    func setError(msg : String, withShake : Bool) {
        errorLabel.text = msg
        self.layoutIfNeeded()
        if withShake {
            errorLabel.shake(3, offset: 10)
        }
        
    }

}
