//
//  ContactGroupViewModel.swift
//  ProtonMail
//
//  Created by Chun-Hung Tseng on 2018/8/20.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation

protocol ContactGroupsViewModel {
    var contactGroupsViewControllerDelegate: ContactGroupsViewModelDelegate? { get set }
    
    func fetchContactGroups()
    
    func getNumberOfRowsInSection() -> Int
    func getContactGroupData(at indexPath: IndexPath) -> ContactGroup?
}
