//
//  SettingsWeekdaysTableViewController.swift
//  ProtonMail
//
//  Created by Anatoly Rosencrantz on 12/06/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import UIKit

class SettingsWeekdaysTableViewController: UITableViewController {
    private lazy var allWeekdays = Calendar.current.weekdaySymbols
    private var selectedWeekdays = [Int]()
    
    internal func markWeekdaysAsSelected(_ weekdays: [Int]) {
        self.selectedWeekdays = weekdays
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let nib = UINib(nibName: "\(GeneralSettingViewCell.self)", bundle: Bundle.main)
        self.tableView.register(nib, forCellReuseIdentifier: "\(GeneralSettingViewCell.self)")
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.allWeekdays.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "\(GeneralSettingViewCell.self)", for: indexPath) as! GeneralSettingViewCell
        
        cell.configCell(allWeekdays[indexPath.row], right: "")
        cell.accessoryType = self.selectedWeekdays.contains(indexPath.row) ? .checkmark : .none
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = self.tableView.cellForRow(at: indexPath) {
            cell.accessoryType = cell.accessoryType == .none ? .checkmark : .none
        }
        self.tableView.deselectRow(at: indexPath, animated: true)
    }
}
