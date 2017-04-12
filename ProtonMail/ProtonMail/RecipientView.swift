//
//  RecipientView.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 9/10/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import UIKit

class RecipientView: PMView {
    override func getNibName() -> String {
        return "RecipientView"
    }
    var promptString : String?
    var labelValue : String?
    
    var labelSize : CGSize?
    
    var contacts : [ContactVO]?
    
    //@IBOutlet weak var fromLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    fileprivate let kContactCellIdentifier: String = "RecipientCell"
    
    
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
    
    func getContentSize() -> CGSize{
        tableView.reloadData()
        tableView.layoutIfNeeded();
        let s = tableView!.contentSize
        return s;
    }
}

extension RecipientView: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: kContactCellIdentifier, for: indexPath) as! RecipientCell
        
        let c = contacts?[indexPath.row]
        let n = (c?.name ?? "")
        let e = (c?.email ?? "")
        cell.senderName.text = n.isEmpty ? e : n
        cell.email.text = "<" + e + ">"
        return cell;
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contacts?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 30;
    }
}

extension RecipientView: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
    }
}
