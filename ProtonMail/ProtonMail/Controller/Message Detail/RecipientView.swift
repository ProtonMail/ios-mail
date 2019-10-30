//
//  RecipientView.swift
//  ProtonMail - Created on 9/10/15.
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

protocol RecipientViewDelegate : RecipientCellDelegate {
    
}

class RecipientView: PMView {
    override func getNibName() -> String {
        return "RecipientView"
    }
    
    //@IBOutlet weak var fromLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    ///
    var promptString : String?
    var labelValue : String?
    
    var showLocker : Bool = true
    
    var labelSize : CGSize?
    
    var contacts : [ContactVO]?
    
    weak var delegate : RecipientViewDelegate?
    
    private let kContactCellIdentifier: String = "RecipientCell"
    
    override func setup() {
        self.tableView.register(UINib(nibName: "RecipientCell", bundle: Bundle.main), forCellReuseIdentifier: kContactCellIdentifier)
        self.tableView.alwaysBounceVertical = false
        self.tableView.separatorStyle = .none
        self.tableView.allowsSelection = false

    }
    
    var prompt : String {
        get {
            return promptString ?? ""
        }
        set (t) {
            promptString = t
        }
    }
    
    var label : String? {
        get {
            return labelValue;
        }
        set (t) {
            labelValue = t;
        }
    }
    
    func showLock(isShow: Bool) {
        showLocker = isShow
    }
    
    func getContentSize() -> CGSize{
        tableView.reloadData()
        tableView.layoutIfNeeded();
        let s = tableView!.contentSize
        return s;
    }
}

extension RecipientView: UITableViewDataSource {
    
    @objc func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: kContactCellIdentifier, for: indexPath) as! RecipientCell
        
        if let c = contacts?[indexPath.row] {
            cell.delegate = self.delegate
            cell.showLock(isShow: showLocker)
            cell.model = c
        }
        return cell;
    }
    
    @objc func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contacts?.count ?? 0
    }
    
    @objc func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 30;
    }
}

extension RecipientView: UITableViewDelegate {
    
    @objc func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
    }
}
