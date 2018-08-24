//
//  ContactGroupSelectColorViewModelImpl.swift
//  ProtonMail
//
//  Created by Chun-Hung Tseng on 2018/8/23.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation

class ContactGroupSelectColorViewModelImpl: ContactGroupSelectColorViewModel
{
    let colors = ColorManager.forLabel
    
    func getTotalColors() -> Int {
        return colors.count
    }
    
    func getColor(at indexPath: IndexPath) -> String
    {
        guard indexPath.row < colors.count else {
            // TODO: handle error
            PMLog.D("Collection view invalid request")
            fatalError("Collection view invalid request")
        }
        
        return colors[indexPath.row]
    }
}
