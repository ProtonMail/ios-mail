//
// Copyright 2015 ArcTouch, Inc.
// All rights reserved.
//
// This file, its contents, concepts, methods, behavior, and operation
// (collectively the "Software") are protected by trade secret, patent,
// and copyright laws. The use of the Software is governed by a license
// agreement. Disclosure of the Software to third parties, in any form,
// in whole or in part, is expressly prohibited except as authorized by
// the license agreement.
//

import UIKit

class SettingsViewController: ProtonMailViewController {
    
    @IBOutlet var notificationContainerView: UIView!
    @IBOutlet var loginPasswordContainerView: UIView!
    @IBOutlet var mailboxPasswordContainerView: UIView!
    @IBOutlet var displayNameContainerView: UIView!
    @IBOutlet var signatureContainerView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        includeBorderOnView(notificationContainerView)
        includeBorderOnView(loginPasswordContainerView)
        includeBorderOnView(mailboxPasswordContainerView)
        includeBorderOnView(displayNameContainerView)
        includeBorderOnView(signatureContainerView)
    }
    
    private func includeBorderOnView(view: UIView) {
        view.layer.borderWidth = 0.5
        view.layer.borderColor = UIColor.ProtonMail.Gray_E8EBED.CGColor
    }
}