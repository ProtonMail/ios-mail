//
//  ContactGroupViewModelImpl.swift
//  ProtonMail
//
//  Created by Chun-Hung Tseng on 2018/8/20.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation

class ContactGroupsViewModelImpl: ContactGroupsViewModel
{
    func fetchAllContactGroup()
    {
        sharedLabelsDataService.fetchLabels(type: 2)
    }
}
