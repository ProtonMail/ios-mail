//
//  ContactEditTextViewCell.swift
//  Proton Mail - Created on 12/28/17.
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import ProtonCoreUIFoundations
import UIKit

protocol ContactEditTextViewCellDelegate: AnyObject {
    func beginEditing(textView: UITextView)
    func didChanged()
}

final class ContactEditTextViewCell: UITableViewCell {

    fileprivate var note: ContactEditNote!
    fileprivate weak var delegate: ContactEditTextViewCellDelegate?

    @IBOutlet weak var textView: UITextView!

    override func awakeFromNib() {
        super.awakeFromNib()
        self.textView.delegate = self
        self.textView.tintColor = ColorProvider.TextHint
        self.textView.textColor = ColorProvider.TextNorm
        self.textView.backgroundColor = ColorProvider.BackgroundNorm
        backgroundColor = ColorProvider.BackgroundNorm
    }

    @IBAction func notesClicked(_ sender: Any) {
        self.textView.becomeFirstResponder()
    }

    func configCell(obj: ContactEditNote, callback: ContactEditTextViewCellDelegate?) {
        self.note = obj
        self.delegate = callback

        self.textView.text = self.note.newNote
        self.textView.sizeToFit()
        self.delegate?.didChanged()
    }
}

extension ContactEditTextViewCell: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        self.delegate?.beginEditing(textView: textView)
    }

    func textViewDidChange(_ textView: UITextView) {
        if let text = textView.text, text != note.newNote {
            note.newNote = text
            self.delegate?.didChanged()
        }
    }
}
