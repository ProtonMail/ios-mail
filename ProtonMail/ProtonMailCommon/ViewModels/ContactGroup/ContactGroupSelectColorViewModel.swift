//
//  ContactGroupSelectColorViewModel.swift
//  ProtonMail
//
//  Created by Chun-Hung Tseng on 2018/8/23.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation

protocol ContactGroupSelectColorViewModel {
    func getTotalColors() -> Int
    func getColor(at indexPath: IndexPath) -> String
}
