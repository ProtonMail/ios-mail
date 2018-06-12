//
//  SettingsNotificationsSnoozeTableViewController.swift
//  ProtonMail
//
//  Created by Anatoly Rosencrantz on 10/06/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import UIKit

@available (iOS 10, *)
class SettingsNotificationsSnoozeTableViewController: UITableViewController {
    private lazy var notificationsSnoozer = UserNotificationsSnoozer()
    private lazy var scheduledRules: [CalendarIntervalRule]? = {
        let usersRules: [CalendarIntervalRule] = self.notificationsSnoozer.configs(ofCase: .scheduled).compactMap { config in
            guard case UserNotificationsSnoozer.Configuration.scheduled(rule: let rule) = config else {
                return nil
            }
            return rule
        }
        return usersRules.isEmpty ? nil : usersRules
    }()
    private lazy var defaultRules: [CalendarIntervalRule] = { // FIXME: extract to model object
        let weekdays: [Int] = [1,2,3,4,5]
        let rules: [CalendarIntervalRule] = weekdays.map {
            return CalendarIntervalRule(start: .init(hour: 22, minute: 00, weekday: $0),
                                        end: .init(hour: 8, minute: 00, weekday: $0 + 1))
        }
        return rules
    }()
    private var actualRules: [CalendarIntervalRule] {
        return self.scheduledRules ?? self.defaultRules
    }
    
    private lazy var timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }()
    
    private enum Model {
        case quickSettings
        
        case scheduledToggle
        case startTime
        case endTime
        case `repeat`
        
        static var cellsLayout: Dictionary<IndexPath, Model> = [
            .init(row: 0, section:0): .quickSettings,
            
            .init(row: 0, section:1): .scheduledToggle,
            .init(row: 1, section:1): .startTime,
            .init(row: 2, section:1): .endTime,
            .init(row: 3, section:1): .repeat
        ]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.tableFooterView = UIView()
        
        let cellTypesToRegister = [GeneralSettingViewCell.self, SwitchTableViewCell.self, DomainsTableViewCell.self]
        cellTypesToRegister.forEach {
            let nib = UINib(nibName: "\($0)", bundle: Bundle.main)
            self.tableView.register(nib, forCellReuseIdentifier: "\($0)")
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 1
        case 1:
            let isScheduledSetup = !self.notificationsSnoozer.configs(ofCase: .scheduled).isEmpty
            return isScheduledSetup ? 4 : 1
        default:
            fatalError()
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let model = Model.cellsLayout[indexPath] else {
            fatalError()
        }
        
        switch model {
        case .quickSettings:
            let cell = tableView.dequeueReusableCell(withIdentifier: "\(GeneralSettingViewCell.self)", for: indexPath) as! GeneralSettingViewCell
            cell.configCell("Snooze Notifications", right: self.notificationsSnoozer.overview(at: Date()))
            cell.accessoryType = .disclosureIndicator
            return cell
            
        case .scheduledToggle:
            let cell = tableView.dequeueReusableCell(withIdentifier: "\(SwitchTableViewCell.self)", for: indexPath) as! SwitchTableViewCell
            cell.accessoryType = .none
            cell.selectionStyle = .none
            let scheduledIsOn = !self.notificationsSnoozer.configs(ofCase: .scheduled).isEmpty
            cell.configCell("Scheduled", bottomLine: "", status: scheduledIsOn) { _, newStatus, _ in
                self.schedule(newStatus ? self.defaultRules : nil)
                self.tableView.reloadSections(IndexSet(integer: 1), with: .fade)
            }
            return cell
        
        case .startTime:
            let cell = tableView.dequeueReusableCell(withIdentifier: "\(DomainsTableViewCell.self)", for: indexPath) as! DomainsTableViewCell
            cell.domainText.text = "Start Time:"
            let start = actualRules.first!.startMatching
            let date = Calendar.current.date(bySettingHour: start.hour!, minute: start.minute!, second: 0, of: Date())!
            cell.defaultMark.text = self.timeFormatter.string(from: date)
            cell.accessoryType = .none
            return cell
 
        case .endTime:
            let cell = tableView.dequeueReusableCell(withIdentifier: "\(DomainsTableViewCell.self)", for: indexPath) as! DomainsTableViewCell
            cell.domainText.text = "End Time:"
            let end = actualRules.first!.endMatching
            let date = Calendar.current.date(bySettingHour: end.hour!, minute: end.minute!, second: 0, of: Date())!
            cell.defaultMark.text = self.timeFormatter.string(from: date)
            cell.accessoryType = .none
            return cell

        case .repeat:
            let cell = tableView.dequeueReusableCell(withIdentifier: "\(GeneralSettingViewCell.self)", for: indexPath) as! GeneralSettingViewCell
            let weekdays = self.actualRules.compactMap { Calendar.current.shortWeekdaySymbols[$0.startMatching.weekday!] }
            cell.configCell("Repeat", right: weekdays.joined(separator: ", "))
            cell.accessoryType = .disclosureIndicator
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let model = Model.cellsLayout[indexPath] else {
            fatalError()
        }
        
        switch model {
        case .quickSettings:
            let dialog = self.notificationsSnoozer.quickOptionsDialog(for: Date()){ _ in
                self.tableView.reloadSections(IndexSet(integer: 0), with: .fade)
            }
            self.present(dialog, animated: true) {
                self.tableView.selectRow(at: nil, animated: true, scrollPosition: .none)
            }
            
        case .scheduledToggle:
            break
            
        case .repeat:
            if let controller = self.storyboard?.instantiateViewController(withIdentifier: "\(SettingsWeekdaysTableViewController.self)") as? SettingsWeekdaysTableViewController
            {
                let weekdays = self.actualRules.compactMap { $0.startMatching.weekday }
                controller.markWeekdaysAsSelected(weekdays)
                self.navigationController?.pushViewController(controller, animated: true)
            }
            
        default:
            break
        }
    }
    
    private func schedule(_ rules: [CalendarIntervalRule]?) {
        self.notificationsSnoozer.unsnoozeRepeating()
        guard let rules = rules else {
            return
        }
        let configs = rules.map { UserNotificationsSnoozer.Configuration.scheduled(rule: $0) }
        self.notificationsSnoozer.add(configs)
    }
    
}
