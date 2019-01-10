//
//  ContactEditTextViewCell.swift
//  ProtonMail - Created on 12/28/17.
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
        self.textView.delegate = self
    }
    @IBAction func notesClicked(_ sender: Any) {
        
        self.textView.becomeFirstResponder()
    }
    
    func configCell(obj : ContactEditNote, paid: Bool, callback : ContactEditTextViewCellDelegate?) {
        self.note = obj
        self.isPaid = paid
        self.delegate = callback
        
        self.textView.text = self.note.newNote
        self.textView.sizeToFit()
        self.delegate?.didChanged(textView: textView)
    }
}

extension ContactEditTextViewCell: UITextViewDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return true
    }
    
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        guard self.isPaid else {
            self.delegate?.featureBlocked(textView: textView)
            return false
        }
        return true
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        self.delegate?.beginEditing(textView: textView)
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
