//
//  UITableView+Extension.swift
//  ProtonMail
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


import ProtonCore_UIFoundations

extension UITableView {
    
    fileprivate struct Constant {
        static let animationDuration: TimeInterval = 1
    }
    
    func hideLoadingFooter(replaceWithView view: UIView? = UIView(frame: CGRect.zero)) {
        UIView.animate(withDuration: Constant.animationDuration, animations: { () -> Void in
            self.tableFooterView?.alpha = 0
            return
        }, completion: { (finished) -> Void in
            UIView.animate(withDuration: Constant.animationDuration, animations: { () -> Void in
                self.tableFooterView = view
            })
        })
    }
    func noSeparatorsBelowFooter() {
        tableFooterView = UIView(frame: CGRect.zero)
    }
    
    func showLoadingFooter() {
        tableFooterView = makeLoadingFooterView()
    }

    func makeLoadingFooterView() -> UIView {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: 72))
        let loadingActivityView: UIActivityIndicatorView
        if #available(iOS 13.0, *) {
            loadingActivityView = UIActivityIndicatorView(style: .medium)
        } else {
            loadingActivityView = UIActivityIndicatorView(style: .white)
        }
        loadingActivityView.color = UIColorManager.BrandNorm
        view.addSubview(loadingActivityView)

        [
            loadingActivityView.heightAnchor.constraint(equalToConstant: 32),
            loadingActivityView.widthAnchor.constraint(equalToConstant: 32),
            loadingActivityView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            loadingActivityView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
            loadingActivityView.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ].activate()
        loadingActivityView.startAnimating()
        return view
    }
    
    /**
     reset table view inset and margins to .zero
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

extension UITableView {
    
    func RegisterCell(_ cellID : String) {
        self.register(UINib(nibName: cellID, bundle: nil), forCellReuseIdentifier: cellID)
    }


    func dequeue<T: UITableViewCell>(cellType: T.Type) -> T {
        guard let cell = dequeueReusableCell(withIdentifier: cellType.reuseIdentifier) as? T else {
            fatalError("Could not dequeue cell with reuse identifier: \(cellType.reuseIdentifier)")
        }

        return cell
    }

    func register<T: UITableViewCell>(cellType: T.Type) {
        register(cellType, forCellReuseIdentifier: cellType.reuseIdentifier)
    }

}
