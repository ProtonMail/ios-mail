//
//  ViewModelProtocal.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 3/12/18.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation


@available(*, deprecated, message: "double check if ok to remove")
protocol ViewModelProtocol {
    func setViewModel(_ vm: Any)
    func inactiveViewModel()
}
