//
//  ContactGroupEditViewModelImpl.swift
//  ProtonMail
//
//  Created by Chun-Hung Tseng on 2018/8/21.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation

class ContactGroupEditViewModelImpl: ContactGroupEditViewModel {
    var state: ContactGroupEditViewControllerState
    
    init(state: ContactGroupEditViewControllerState = .create)
    {
        self.state = state
    }
}
