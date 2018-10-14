//
//  ContactGroupSubSelectionViewModel.swift
//  ProtonMail
//
//  Created by Chun-Hung Tseng on 2018/10/13.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation

protocol ContactGroupSubSelectionViewModelDelegate
{
    func reloadTable()
}

protocol ContactGroupSubSelectionViewModelEmailCellDelegate
{
    func select(email: String)
    func deselect(email: String)
    func setIsEncrypted(email: String, isEncrypted: UIImage?)
}

protocol ContactGroupSubSelectionViewModelHeaderCellDelegate
{
    func selectAll()
    func deSelectAll()
    func isAllSelected() -> Bool
}

struct ContactGroupSubSelectionViewModelEmailInfomation
{
    let email: String
    let name: String
    var isSelected: Bool
    var isEncrypted: UIImage?
    
    init(email: String, name: String, isSelected: Bool = false, isEncrypted: UIImage? = nil) {
        self.email = email
        self.name = name
        self.isSelected = isSelected
        self.isEncrypted = isEncrypted
    }
    
    func getEmailDescription() -> String
    {
        return "\(self.name) <\(self.email)>"
    }
}

protocol ContactGroupSubSelectionViewModel: ContactGroupSubSelectionViewModelEmailCellDelegate,
    ContactGroupSubSelectionViewModelHeaderCellDelegate
{
    func getCurrentlySelectedEmails() -> [String]
    
    func getGroupName() -> String
    func getGroupColor() -> String?
    func getTotalRows() -> Int
    func cellForRow(at indexPath: IndexPath) -> ContactGroupSubSelectionViewModelEmailInfomation
}
