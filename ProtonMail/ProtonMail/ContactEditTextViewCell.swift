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
}

final class ContactEditTextViewCell: UITableViewCell {
    
    fileprivate var note : ContactEditNote!
    fileprivate var delegate : ContactEditTextViewCellDelegate?
    
    @IBOutlet weak var textView: UITextView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        //self.valueField.delegate = self
        self.textView.delegate = self
    }
    
    func configCell(obj : ContactEditNote, callback : ContactEditTextViewCellDelegate?) {
        self.note = obj
        
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
        delegate?.beginEditing(textView: textView)
    }
    func textViewDidChange(_ textView: UITextView) {
         note.newNote = textView.text!
        self.delegate?.didChanged(textView: textView)
    }
}
