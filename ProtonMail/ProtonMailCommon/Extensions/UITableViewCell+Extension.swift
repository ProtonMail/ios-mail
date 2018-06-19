//
//  UITableViewCll+Extension.swift
//  ProtonMail
//
import Foundation

extension UITableViewCell {
    /**
     reset table view cell inset and margins to .zero
     **/
    func zeroMargin() {
        if (self.responds(to: #selector(setter: UITableViewCell.separatorInset))) {
            self.separatorInset = .zero
        }
        if (self.responds(to: #selector(setter: UIView.layoutMargins))) {
            self.layoutMargins = .zero
        }
    }
}


