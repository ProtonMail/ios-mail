//
//  ViewModelProtocal.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 3/12/18.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation



protocol ViewModelProtocolNew {
    associatedtype argType
    func setViewModel(_ vm: argType) -> Void
    func inactiveViewModel() -> Void
}


