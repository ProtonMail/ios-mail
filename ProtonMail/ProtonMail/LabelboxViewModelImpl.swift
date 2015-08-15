//
//  LabelboxViewModelImpl.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 8/15/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation



public class LabelboxViewModelImpl : MailboxViewModel {
    
    private let label : Label!
    
    init(label : Label) {
        
        self.label = label
        
        super.init()
    }
    
    override public func getNavigationTitle() -> String {
        return self.label.name
    }
}