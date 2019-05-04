//
//  ContactGroupViewModel.swift
//  ProtonMail - Created on 2018/8/20.
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
import CoreData
import PromiseKit

//enum ContactGroupsViewModelState
//{
//    case ViewAllContactGroups
//    case MultiSelectContactGroupsForContactEmail
//}

protocol ContactGroupsViewModel {
    
    func initEditing() -> Bool
    
    func save()
    func isSelected(groupID: String) -> Bool
    
    func fetchLatestContactGroup() -> Promise<Void>
    func timerStart(_ run: Bool)
    func timerStop()
    
    func getSelectedCount() -> Int
    
    func addSelectedGroup(ID: String, indexPath: IndexPath)
    func removeSelectedGroup(ID: String, indexPath: IndexPath)
    func removeAllSelectedGroups()
    
    func setFetchResultController(delegate: NSFetchedResultsControllerDelegate?) -> NSFetchedResultsController<NSFetchRequestResult>? 
    // search
    func search(text: String?, searchActive: Bool)
    
    // contact groups deletion
    func deleteGroups() -> Promise<Void>
    
    // table count
    func searchingActive() -> Bool 
    func count() -> Int
    func dateForRow(at indexPath: IndexPath) -> (ID: String, name: String, color: String, count: Int, wasSelected: Bool, showEmailIcon: Bool)
}
