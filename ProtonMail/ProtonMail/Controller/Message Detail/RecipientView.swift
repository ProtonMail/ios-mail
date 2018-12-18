//
//  RecipientView.swift
//  ProtonMail - Created on 9/10/15.
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
