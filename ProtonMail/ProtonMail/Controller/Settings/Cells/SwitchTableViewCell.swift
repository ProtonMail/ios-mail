//
//  SwitchTableViewCell.swift
//  ProtonMail - Created on 3/17/15.
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.


import UIKit

@IBDesignable class SwitchTableViewCell: UITableViewCell {

    typealias ActionStatus = (_ isOK: Bool) -> Void
    typealias switchActionBlock = (_ cell: SwitchTableViewCell?, _ newStatus: Bool, _ feedback: @escaping ActionStatus) -> Void

    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        if #available(iOS 10, *) {
            topLineLabel.font = UIFont.preferredFont(forTextStyle: .footnote)
            topLineLabel.adjustsFontForContentSizeCategory = true
            
            bottomLineLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
            bottomLineLabel.adjustsFontForContentSizeCategory = true
        }
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(SwitchTableViewCell.handleTapOnLabel))
        bottomLineLabel.isUserInteractionEnabled = true
        bottomLineLabel.addGestureRecognizer(tap)
    }
    
    var callback : switchActionBlock?
    
    @IBOutlet weak var topLineBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var centerConstraint: NSLayoutConstraint!
    @IBOutlet weak var topLineLabel: UILabel!
    @IBOutlet weak var bottomLineLabel: UILabel!
    
    @IBOutlet weak var switchView: UISwitch!
    @IBAction func switchAction(_ sender: UISwitch) {
        let status = sender.isOn
        callback?(self, status, { (isOK ) -> Void in
            if isOK == false {
                self.switchView.setOn(false, animated: true)
                self.layoutIfNeeded()
            }
        })
    }
    
    fileprivate var layoutManager = NSLayoutManager()
    fileprivate var textContainer = NSTextContainer(size: CGSize.zero)
    fileprivate var textStorage: NSTextStorage?
//
    @objc func handleTapOnLabel(tapGesture:UITapGestureRecognizer){
        guard let attributedText = self.bottomLineLabel.attributedText else {
            return
        }
        
        
        let locationOfTouchInLabel = tapGesture.location(in: tapGesture.view)
        guard let labelSize = tapGesture.view?.bounds.size else {
            return
        }
        let textBoundingBox = self.layoutManager.usedRect(for: self.textContainer)
        let textContainerOffset = CGPoint(x: (labelSize.width - textBoundingBox.size.width) * 0.5 - textBoundingBox.origin.x, y: (labelSize.height - textBoundingBox.size.height) * 0.5 - textBoundingBox.origin.y)

        let locationOfTouchInTextContainer = CGPoint(x: locationOfTouchInLabel.x - textContainerOffset.x, y: locationOfTouchInLabel.y - textContainerOffset.y)
        let indexOfCharacter = self.layoutManager.characterIndex(for: locationOfTouchInTextContainer,
                                                                 in: self.textContainer,
                                                                 fractionOfDistanceBetweenInsertionPoints: nil)
        attributedText.enumerateAttribute(.link, in: NSMakeRange(0,attributedText.length),
                                          options: NSAttributedString.EnumerationOptions(rawValue: UInt(0)),
                                          using: { (attrs: Any?, range: NSRange, stop: UnsafeMutablePointer<ObjCBool>) in
            if NSLocationInRange(indexOfCharacter, range){
                if let _attrs = attrs as? String, let url = URL(string:_attrs) {
                    UIApplication.shared.openURL(url)
                }
            }
        })
    }
    
    func configCell(_ topline : String, bottomLine : String, status : Bool, complete : switchActionBlock?) {
        layoutManager = NSLayoutManager()
        textContainer = NSTextContainer(size: CGSize.zero)
        textStorage = nil
        topLineLabel.text = topline
        bottomLineLabel.text = bottomLine
        switchView.isOn = status
        callback = complete
        self.bottomLineLabel.isUserInteractionEnabled = false
        self.accessibilityLabel = topline
        self.accessibilityElements = [switchView as Any]
        self.switchView.accessibilityLabel = (topLineLabel.text ?? "") + (bottomLineLabel.text ?? "")
        
        if bottomLine.isEmpty {
            topLineBottomConstraint.priority = UILayoutPriority(999.0)
            centerConstraint.priority = UILayoutPriority(rawValue: 750.0);
            bottomLineLabel.isHidden = true
            
        } else {
            topLineBottomConstraint.priority = UILayoutPriority(250.0)
            centerConstraint.priority = UILayoutPriority(rawValue: 1.0);
            bottomLineLabel.isHidden = false
        }
        self.layoutIfNeeded()
    }
    
    
    func configCell(_ topline : String, bottomLine : NSMutableAttributedString, showSwitcher : Bool, status : Bool, complete : switchActionBlock?) {
        layoutManager = NSLayoutManager()
        textContainer = NSTextContainer(size: CGSize.zero)
        textStorage = nil
        if #available(iOS 10, *) {
            topLineLabel.font = UIFont.preferredFont(forTextStyle: .title3)
            topLineLabel.adjustsFontForContentSizeCategory = true
//            bottomLineLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
//            bottomLineLabel.adjustsFontForContentSizeCategory = true
        }
        topLineLabel.text = topline
        bottomLineLabel.attributedText = bottomLine
        self.bottomLineLabel.isUserInteractionEnabled = true
        if let _attributedText = bottomLineLabel.attributedText{
            self.textStorage = NSTextStorage(attributedString: _attributedText)
            self.layoutManager.addTextContainer(self.textContainer)
            self.textStorage?.addLayoutManager(self.layoutManager)
            
//            self.textContainer.lineFragmentPadding = 0.0
            self.textContainer.lineBreakMode = self.bottomLineLabel.lineBreakMode
            self.textContainer.maximumNumberOfLines = self.bottomLineLabel.numberOfLines
        }
        
        switchView.isOn = status
        callback = complete
        
        self.accessibilityLabel = topline
        self.accessibilityElements = [switchView as Any]
        self.switchView.accessibilityLabel = (topLineLabel.text ?? "") + (bottomLineLabel.text ?? "")
        
        switchView.isHidden = !showSwitcher
        
        self.layoutIfNeeded()
    }
}

extension SwitchTableViewCell: IBDesignableLabeled {
    override func prepareForInterfaceBuilder() {
        self.labelAtInterfaceBuilder()
    }
}
