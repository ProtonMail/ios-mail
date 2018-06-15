//
//  LabelCreatingViewModelImple.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 3/2/17.
//  Copyright © 2017 ProtonMail. All rights reserved.
//

import Foundation

// label creating
final public class LabelCreatingViewModelImple : LabelEditViewModel {

    override public func title() -> String {
        return LocalString._labels_add_new_label_title
    }
    
    override public func placeHolder() -> String {
        return LocalString._labels_label_name_text
    }
    
    override public func rightButtonText() -> String {
        return LocalString._general_create_action
    }
    
    override public func apply(withName name: String, color: String, error: @escaping LabelEditViewModel.ErrorBlock, complete: @escaping LabelEditViewModel.OkBlock) {
        let api = CreateLabelRequest<CreateLabelRequestResponse>(name: name, color: color, exclusive: false)
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
