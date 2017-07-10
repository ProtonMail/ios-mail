//
//  FolderCreatingViewModelImpl.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 3/2/17.
//  Copyright © 2017 ProtonMail. All rights reserved.
//

import Foundation

// label creating
final class FolderCreatingViewModelImple : LabelEditViewModel {
    
    override func title() -> String {
        return NSLocalizedString("Add New Folder", comment: "Title")
    }
    
    override func placeHolder() -> String {
        return NSLocalizedString("Folder Name", comment: "place holder")
    }
    
    override func rightButtonText() -> String {
        return NSLocalizedString("Create", comment: "top right action text")
    }
    
    override func apply(withName name: String, color: String, error: @escaping LabelEditViewModel.ErrorBlock, complete: @escaping LabelEditViewModel.OkBlock) {
        let api = CreateLabelRequest<CreateLabelRequestResponse>(name: name, color: color, exclusive: true)
        api.call { (task, response, hasError) -> Void in
            if hasError {
                error(response?.code ?? 1000, response?.errorMessage ?? "");
            } else {
                sharedLabelsDataService.addNewLabel(response?.label);
                complete()
            }
        }
    }
}
