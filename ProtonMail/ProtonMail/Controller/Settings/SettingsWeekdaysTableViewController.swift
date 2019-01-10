//
//  SettingsWeekdaysTableViewController.swift
//  ProtonMail - Created on 12/06/2018.
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
