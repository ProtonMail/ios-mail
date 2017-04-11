//
//  LabelEditingViewModelImpl.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 3/2/17.
//  Copyright © 2017 ProtonMail. All rights reserved.
//

import Foundation


// label editing
final class LabelEditingViewModelImple : LabelEditViewModel {
    var currentLabel : Label
    
    required init(label : Label) {
        self.currentLabel = label
    }
    
    override func title() -> String {
        return "Edit Label"
    }
    
    override func placeHolder() -> String {
        return "Label Name"
    }
    
    override func rightButtonText() -> String {
        return "Update"
    }
    
    override func name() -> String {
        return currentLabel.name
    }
    
    override func seletedIndex() -> IndexPath {
        let currentColor = currentLabel.color
        if let index = colors.index(of: currentColor) {
            return IndexPath(row: index, section: 0)
        } else {
            return super.seletedIndex()
        }
    }
    
    override func apply(withName name: String, color: String, error: @escaping LabelEditViewModel.ErrorBlock, complete: @escaping LabelEditViewModel.OkBlock) {
        let api = UpdateLabelRequest<CreateLabelRequestResponse>(id: currentLabel.labelID, name: name, color: color)
        api.call { (task, response, hasError) -> Void in
            if hasError {
                error(response?.code ?? 1000, response?.errorMessage ?? "");
            } else {
                self.currentLabel.name = name
                self.currentLabel.color = color
                let _ = self.currentLabel.managedObjectContext?.saveUpstreamIfNeeded()
                complete()
            }
        }
        
    }
}
