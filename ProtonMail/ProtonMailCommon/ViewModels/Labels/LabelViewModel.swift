//
//  LabelViewModel.swift
//  ProtonMail - Created on 8/17/15.
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
import CoreData
import PMCommon
import PromiseKit


class LabelMessageModel {
    var label : Label!
    var totalMessages : [Message] = []
    var originalSelected : [Message] = []
    var origStatus : Int = 0
    var currentStatus : Int = 0
}

class LabelViewModel {
    internal let apiService: APIService
    internal let labelService: LabelsDataService
    internal let coreDataService: CoreDataService
    
    public typealias OkBlock = () -> Void
    public typealias ErrorBlock = (_ code : Int, _ errorMessage : String) -> Void
    
    internal init(apiService: APIService, labelService: LabelsDataService, coreDataService: CoreDataService) {
        self.apiService = apiService
        self.labelService = labelService
        self.coreDataService = coreDataService
    }
    
    func getFetchType() -> LabelFetchType {
        fatalError("This method must be overridden")
    }
    
    func apply (archiveMessage : Bool) -> Promise<Bool> {
        fatalError("This method must be overridden")
    }
    
    func cancel () {
        fatalError("This method must be overridden")
    }
    
    func getLabelMessage(_ label : Label!) -> LabelMessageModel! {
        fatalError("This method must be overridden")
    }
    
    func cellClicked(_ label : Label!) {
        fatalError("This method must be overridden")
    }
    
    func singleSelectLabel() {
        
    }
    
    func getTitle() -> String {
        fatalError("This method must be overridden")
    }
    
    func showArchiveOption() -> Bool {
        fatalError("This method must be overridden")
    }
    
    func getApplyButtonText() -> String {
        fatalError("This method must be overridden")
    }
    
    func getCancelButtonText() -> String {
        fatalError("This method must be overridden")
    }
    
    func fetchController() -> NSFetchedResultsController<NSFetchRequestResult>? {
        fatalError("This method must be overridden")
    }
}

