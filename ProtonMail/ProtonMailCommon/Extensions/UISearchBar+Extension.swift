//
//  UISearchBar+Extension.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 12/28/17.
//  Copyright © 2017 ProtonMail. All rights reserved.
//

import Foundation



import UIKit

extension UISearchBar {
    
    private func getViewElement<T>(type: T.Type) -> T? {
        
        let svs = subviews.flatMap { $0.subviews }
        guard let element = (svs.filter { $0 is T }).first as? T else { return nil }
        return element
    }
    
    func getSearchBarTextField() -> UITextField? {
        
        return getViewElement(type: UITextField.self)
    }
    
    func setTextColor(color: UIColor) {
        
        if let textField = getSearchBarTextField() {
            textField.textColor = color
        }
    }
    
    func setTextFieldColor(color: UIColor) {
        
        if let textField = getViewElement(type: UITextField.self) {
            switch searchBarStyle {
            case .minimal:
                textField.layer.backgroundColor = color.cgColor
                textField.layer.cornerRadius = 6
                
            case .prominent, .default:
                textField.backgroundColor = color
            }
        }
    }
    
    func setPlaceholderTextColor(color: UIColor) {
        if let textField = getSearchBarTextField() {
            textField.attributedPlaceholder = NSAttributedString(string: self.placeholder != nil ? self.placeholder! : "", attributes: [NSAttributedString.Key.foregroundColor: color])
        }
    }
    
    func setTextFieldClearButtonColor(color: UIColor) {

        if let textField = getSearchBarTextField() {

            let button = textField.value(forKey: "clearButton") as! UIButton
            if let _ = button.imageView?.image {
                button.setImage(UIImage.image(with: color),
                                for: .normal)
            }
        }
    }

    func setSearchImageColor(color: UIColor) {

        if let imageView = getSearchBarTextField()?.leftView as? UIImageView {
            imageView.image = UIImage.image(with: color)
        }
    }
    
    func contactSearchSetup(textfieldBG: UIColor, placeholderColor: UIColor, textColor: UIColor) {
        
        if let textField = getSearchBarTextField() {
            textField.backgroundColor = textfieldBG
            
            if let button = textField.value(forKey: "clearButton") as? UIButton {
                if let image = button.imageView?.image {
                    let newImage = image.withRenderingMode(.alwaysTemplate)
                    button.tintColor = placeholderColor
                    button.setImage(newImage, for: .normal)
                }
            }
            
            if let imageView = textField.leftView as? UIImageView {
                if let newImage = imageView.image?.withRenderingMode(.alwaysTemplate) {
                    
                    imageView.image = newImage
                    imageView.tintColor = placeholderColor
                }
            }
            
            textField.attributedPlaceholder = NSAttributedString(string: self.placeholder != nil ? self.placeholder! : "", attributes: [NSAttributedString.Key.foregroundColor: placeholderColor])
            
            textField.textColor = textColor
        }
    }
}
