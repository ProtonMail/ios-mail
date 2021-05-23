//
//  LabelEditViewModel.swift
//  ProtonMail - Created on 3/2/17.
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.


import Foundation
import ProtonCore_Services

public class LabelEditViewModel {
    let apiService: APIService
    let labelService : LabelsDataService
    let messageService: MessageDataService
    
    public typealias OkBlock = () -> Void
    public typealias ErrorBlock = (_ code: Int, _ errorMessage: String) -> Void
    
    let colors: [String] = ColorManager.forLabel
    
    internal init(apiService: APIService, labelService : LabelsDataService, messageService: MessageDataService) {
        self.apiService = apiService
        self.labelService = labelService
        self.messageService = messageService
    }
    
    public func colorCount() -> Int {
        return colors.count
    }
    
    public func color(at index : Int) -> String {
        return colors[index]
    }

    public func title() -> String {
        fatalError("This method must be overridden")
    }
    
    public func seletedIndex() -> IndexPath {
        let count = UInt32(colors.count)
        let rand = Int(arc4random_uniform(count))
        return IndexPath(row: rand, section: 0)
    }
    
    public func name() -> String {
        return ""
    }
    
    public func placeHolder() -> String {
        fatalError("This method must be overridden")
    }
    
    public func rightButtonText() -> String {
        fatalError("This method must be overridden")
    }
    
    public func apply(withName name: String, color: String, errorBlock: @escaping ErrorBlock, completion: @escaping OkBlock) {
        fatalError("This method must be overridden")
    }
}
