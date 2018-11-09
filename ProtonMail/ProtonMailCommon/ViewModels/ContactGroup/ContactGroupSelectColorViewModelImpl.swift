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
    var currentColor: String
    let colors = ColorManager.forLabel
    let refreshHandler: (String) -> Void
    
    init(currentColor: String, refreshHandler: @escaping (String) -> Void) {
        self.currentColor = currentColor
        self.refreshHandler = refreshHandler
    }
    
    func isSelectedColor(at indexPath: IndexPath) -> Bool
    {
        guard indexPath.row < colors.count else {
            return false
        }
        
        return colors[indexPath.row] == currentColor
    }
    
    func getCurrentColorIndex() -> Int
    {
        for (i, color) in colors.enumerated() {
            if color == currentColor {
                return i
            }
        }
        
        // This should not happen
        PMLog.D("Color not in the list!")
        currentColor = ColorManager.defaultColor
        return 0
    }
    
    func updateCurrentColor(to indexPath: IndexPath)
    {
        guard indexPath.row < colors.count else {
            currentColor = ColorManager.getRandomColor()
            return 
        }
        
        currentColor = colors[indexPath.row]
    }
    
    func getTotalColors() -> Int
    {
        return colors.count
    }
    
    func getColor(at indexPath: IndexPath) -> String
    {
        guard indexPath.row < colors.count else {
            // TODO: handle error
            PMLog.D("FatalError: Collection view invalid request")
            return ColorManager.defaultColor
        }
        
        return colors[indexPath.row]
    }
    
    func save() {
        refreshHandler(currentColor)
    }
}
