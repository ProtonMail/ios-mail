//
//  ContactEditNotesCell.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 5/24/17.
//  Copyright © 2017 ProtonMail. All rights reserved.
//

import Foundation



protocol ContactEditNotesCellDelegate {
    func beginEditing(textField: UITextField)
}

final class ContactEditNotesCell: UITableViewCell {
    
    fileprivate var note : ContactEditNote!
    fileprivate var delegate : ContactEditNotesCellDelegate?
    
    @IBOutlet weak var valueField: UITextField!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.valueField.delegate = self
    }
    
    func configCell(obj : ContactEditNote, callback : ContactEditNotesCellDelegate?) {
        self.note = obj
        
        valueField.text = self.note.newNote
        
        self.delegate = callback
    }
}

extension ContactEditNotesCell: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        delegate?.beginEditing(textField: textField)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField)  {
        note.newNote = valueField.text!
    }
}
