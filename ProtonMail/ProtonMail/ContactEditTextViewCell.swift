//
//  ContactEditTextViewCell.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 12/28/17.
//  Copyright © 2017 ProtonMail. All rights reserved.
//

import Foundation

protocol ContactEditTextViewCellDelegate {
    func beginEditing(textView: UITextView)
    func didChanged(textView: UITextView)
    func featureBlocked(textView: UITextView)
}

final class ContactEditTextViewCell: UITableViewCell {
    
    fileprivate var note : ContactEditNote!
    fileprivate var delegate : ContactEditTextViewCellDelegate?
    
    @IBOutlet weak var textView: UITextView!
    
    fileprivate var isPaid : Bool = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        //self.valueField.delegate = self
        self.textView.delegate = self
    }
    
    func configCell(obj : ContactEditNote, paid: Bool, callback : ContactEditTextViewCellDelegate?) {
        self.note = obj
        self.isPaid = paid
        self.textView.text = self.note.newNote
        self.textView.sizeToFit()
        self.delegate = callback
        
        self.delegate?.didChanged(textView: textView)
    }
}

extension ContactEditTextViewCell: UITextViewDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return true
    }
    func textViewDidBeginEditing(_ textView: UITextView) {
        self.delegate?.beginEditing(textView: textView)
        guard self.isPaid else {
            self.delegate?.featureBlocked(textView: textView)
            return
        }
    }
    func textViewDidChange(_ textView: UITextView) {
        guard self.isPaid else {
            self.delegate?.featureBlocked(textView: textView)
            return
        }
        if let text = textView.text, text != note.newNote {
            note.newNote = text
            self.delegate?.didChanged(textView: textView)
        }
    }
}
