//
//  ContactGroupSelectColorViewModelImpl.swift
//  ProtonMail - Created on 2018/8/23.
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


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
