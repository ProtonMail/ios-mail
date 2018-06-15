//
//  SettingsWeekdaysTableViewController.swift
//  ProtonMail
//
//  Created by Anatoly Rosencrantz on 12/06/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import UIKit

final class SettingsWeekdaysTableViewController: UITableViewController {
    typealias Weekday = Int
    typealias HandleSelection = (Array<Weekday>)->Void
    
    private lazy var allWeekdays = Calendar.current.weekdaySymbols
    private var selectedWeekdays = Set<Weekday>()
    private var handler: HandleSelection?
    
    // methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.tableFooterView = UIView()
        
        let nib = UINib(nibName: "\(GeneralSettingViewCell.self)", bundle: Bundle.main)
        self.tableView.register(nib, forCellReuseIdentifier: "\(GeneralSettingViewCell.self)")
        
        self.title = self.title?.localized.uppercased()
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
            if cell.accessoryType == .none {
                self.selectedWeekdays.insert(indexPath.row)
                cell.accessoryType = .checkmark
            } else {
                self.selectedWeekdays.remove(indexPath.row)
                cell.accessoryType = .none
            }
        }
        self.tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.handler?(self.selectedWeekdays.sorted(by: <))
    }
    
    // custom
    internal func set(handler: @escaping HandleSelection) {
        self.handler = handler
    }
    
    internal func markWeekdaysAsSelected(_ weekdays: Set<Weekday>) {
        self.selectedWeekdays = weekdays
    }
}
