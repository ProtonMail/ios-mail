//
//  ContactGroupSelectEmailViewModel.swift
//  ProtonMail
//
//  Created by Chun-Hung Tseng on 2018/8/27.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation

protocol ContactGroupSelectEmailViewModel
{
    func getSelectionStatus(at indexPath: IndexPath) -> Bool
    
    func getTotalEmailCount() -> Int
    func getCellData(at indexPath: IndexPath) -> (name: String, email: String, isSelected: Bool)
    func save(indexPaths: [IndexPath]?)
}
