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
    
    // nested types
    
    private struct RawRulesModel {
        var weekdays: Array<Int> = [1,2,3,4,5]
        var startHour: Int = 22
        var startMinute: Int = 00
        var endHour: Int = 08
        var endMinute: Int = 00
        
        fileprivate mutating func setStart(hour: Int, minute: Int) {
            self.startHour = hour
            self.startMinute = minute
        }
        fileprivate mutating func setEnd(hour: Int, minute: Int) {
            self.endHour = hour
            self.endMinute = minute
        }
    }
    private enum ViewModel {
        case quickSettings
        
        case scheduledToggle
        case startTime
        case endTime
        case `repeat`
        
        static var cellsLayout: Dictionary<IndexPath, ViewModel> = [
            .init(row: 0, section:0): .quickSettings,
            
            .init(row: 0, section:1): .scheduledToggle,
            .init(row: 1, section:1): .startTime,
            .init(row: 2, section:1): .endTime,
            .init(row: 3, section:1): .repeat
        ]
    }
    
    
    // properties
    
    private lazy var notificationsSnoozer = UserNotificationsSnoozer()
    private var scheduledRules: [CalendarIntervalRule]? {
        didSet {
            self.schedule(self.scheduledRules)
            self.tableView.reloadSections(IndexSet(integer: 1), with: .fade)
        }
    }
    private var rawRulesModel: RawRulesModel? {
        didSet {
            self.scheduledRules = self.rulesAccodingToRawRules()
        }
    }
    
    private lazy var timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }()
    
    
    // methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.tableFooterView = UIView()
        
        let cellTypesToRegister = [GeneralSettingViewCell.self, SwitchTableViewCell.self, DomainsTableViewCell.self]
        cellTypesToRegister.forEach {
            let nib = UINib(nibName: "\($0)", bundle: Bundle.main)
            self.tableView.register(nib, forCellReuseIdentifier: "\($0)")
        }
        
        self.loadRawRulesFromSnoozer()
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
        guard let model = ViewModel.cellsLayout[indexPath] else {
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
                self.rawRulesModel = newStatus ? RawRulesModel() : nil
            }
            return cell
        
        case .startTime:
            let cell = tableView.dequeueReusableCell(withIdentifier: "\(DomainsTableViewCell.self)", for: indexPath) as! DomainsTableViewCell
            cell.domainText.text = "Start Time:"
            let start = self.scheduledRules!.first!.startMatching
            let date = Calendar.current.date(bySettingHour: start.hour!, minute: start.minute!, second: 0, of: Date())!
            cell.defaultMark.text = self.timeFormatter.string(from: date)
            cell.accessoryType = .none
            return cell
 
        case .endTime:
            let cell = tableView.dequeueReusableCell(withIdentifier: "\(DomainsTableViewCell.self)", for: indexPath) as! DomainsTableViewCell
            cell.domainText.text = "End Time:"
            let end = self.scheduledRules!.first!.endMatching
            let date = Calendar.current.date(bySettingHour: end.hour!, minute: end.minute!, second: 0, of: Date())!
            cell.defaultMark.text = self.timeFormatter.string(from: date)
            cell.accessoryType = .none
            return cell

        case .repeat:
            let cell = tableView.dequeueReusableCell(withIdentifier: "\(GeneralSettingViewCell.self)", for: indexPath) as! GeneralSettingViewCell
            let weekdays = self.scheduledRules!.compactMap { Calendar.current.shortWeekdaySymbols[$0.startMatching.weekday!] }
            cell.configCell("Repeat", right: weekdays.joined(separator: ", "))
            cell.accessoryType = .disclosureIndicator
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let model = ViewModel.cellsLayout[indexPath] else {
            fatalError()
        }
        
        switch model {
        case .quickSettings:
            let dialog = self.notificationsSnoozer.quickOptionsDialog(for: Date()) { _ in
                self.tableView.reloadSections(IndexSet(integer: 0), with: .fade)
            }
            self.present(dialog, animated: true) {
                self.tableView.selectRow(at: nil, animated: true, scrollPosition: .none)
            }
            
        case .scheduledToggle:
            break
        
        case .startTime:
            guard let anyRule = self.scheduledRules?.first else { return }
            let picker = TimePickerViewController.init(select: anyRule.startMatching) { [weak self] newStart in
                self?.rawRulesModel?.setStart(hour: newStart.hour!, minute: newStart.minute!)
            }
            self.present(picker, animated: true, completion: nil)
            
        case .endTime:
            guard let anyRule = self.scheduledRules?.first else { return }
            let picker = TimePickerViewController.init(select: anyRule.endMatching) { [weak self] newEnd in
                self?.rawRulesModel?.setEnd(hour: newEnd.hour!, minute: newEnd.minute!)
            }
            self.present(picker, animated: true, completion: nil)
            
        case .repeat:
            if let controller = self.storyboard?.instantiateViewController(withIdentifier: "\(SettingsWeekdaysTableViewController.self)") as? SettingsWeekdaysTableViewController {
                controller.set(handler: { [weak self] weekdays in
                    self?.rawRulesModel?.weekdays = weekdays
                })
                controller.markWeekdaysAsSelected(Set(self.scheduledRules!.compactMap { $0.startMatching.weekday }))
                self.navigationController?.pushViewController(controller, animated: true)
            }
        }
    }
    
    
    // custom methods
    
    private func schedule(_ rules: [CalendarIntervalRule]?) {
        self.notificationsSnoozer.unsnoozeRepeating()
        guard let rules = rules else {
            return
        }
        let configs = rules.map { UserNotificationsSnoozer.Configuration.scheduled(rule: $0) }
        self.notificationsSnoozer.add(configs)
    }
    
    private func rulesAccodingToRawRules() -> [CalendarIntervalRule]? {
        guard let rawRules = self.rawRulesModel else {
            return nil
        }
        
        let endTimeOveflows = (rawRules.startHour > rawRules.endHour) ||
                              (rawRules.startHour == rawRules.endHour && rawRules.startMinute > rawRules.endMinute)
        let rules = rawRules.weekdays.map {
            CalendarIntervalRule(start: .init(hour: rawRules.startHour, minute: rawRules.startMinute, weekday: $0),
                                 end: .init(hour: rawRules.endHour, minute: rawRules.endMinute, weekday: $0 + (endTimeOveflows ? 1 : 0)))
        }
        return rules
    }
    
    private func loadRawRulesFromSnoozer() {
        let usersRules: [CalendarIntervalRule] = self.notificationsSnoozer.configs(ofCase: .scheduled).compactMap { config in
            guard case UserNotificationsSnoozer.Configuration.scheduled(rule: let rule) = config else {
                return nil
            }
            return rule
        }
        
        guard let anyRule = usersRules.first else {
            self.rawRulesModel = RawRulesModel()
            return
        }
        
        self.rawRulesModel = RawRulesModel(weekdays: usersRules.compactMap { $0.startMatching.weekday },
                                           startHour: anyRule.startMatching.hour!,
                                           startMinute: anyRule.startMatching.minute!,
                                           endHour: anyRule.endMatching.hour!,
                                           endMinute: anyRule.endMatching.minute!)
    }
}
