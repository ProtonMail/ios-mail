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
    var currentColor: String?
    let colors = ColorManager.forLabel
    let refreshHandler: (String?) -> Void
    
    init(currentColor: String?, refreshHandler: @escaping (String?) -> Void) {
        self.currentColor = currentColor
        self.refreshHandler = refreshHandler
    }
    
    func isSelectedColor(at indexPath: IndexPath) -> Bool
    {
        guard indexPath.row < colors.count else {
            return false
        }
        
        if let current = currentColor {
            return colors[indexPath.row] == current
        }
        return false
    }
    
    func getCurrentColor() -> String?
    {
        return currentColor
    }
    
    func getCurrentColorIndex() -> Int?
    {
        if let c = currentColor {
            for (i, color) in colors.enumerated() {
                if color == c {
                    return i
                }
            }
        }
        
        return nil
    }
    
    func updateCurrentColor(to indexPath: IndexPath)
    {
        guard indexPath.row < colors.count else {
            currentColor = nil
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
            PMLog.D("Collection view invalid request")
            fatalError("Collection view invalid request")
        }
        
        return colors[indexPath.row]
    }
    
    func save() {
        refreshHandler(currentColor)
    }
}
