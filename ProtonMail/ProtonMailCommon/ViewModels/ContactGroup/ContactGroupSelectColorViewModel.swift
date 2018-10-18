//
//  ContactGroupSelectColorViewModel.swift
//  ProtonMail
//
//  Created by Chun-Hung Tseng on 2018/8/23.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation

protocol ContactGroupSelectColorViewModel {
    func isSelectedColor(at indexPath: IndexPath) -> Bool
    func getTotalColors() -> Int
    func getColor(at indexPath: IndexPath) -> String
    func getCurrentColorIndex() -> Int
    func updateCurrentColor(to indexPath: IndexPath) 
    
    func save()
}
