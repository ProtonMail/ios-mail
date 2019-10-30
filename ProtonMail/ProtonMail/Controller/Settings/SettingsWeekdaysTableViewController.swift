//
//  SettingsWeekdaysTableViewController.swift
//  ProtonMail - Created on 12/06/2018.
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
        self.title = LocalString._repeat
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
