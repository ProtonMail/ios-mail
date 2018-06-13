//
//  UserNotificationsSnoozer.swift
//  ProtonMail
//
//  Created by Anatoly Rosencrantz on 13/06/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation

// controller
@available(iOS 10.0, *)
final class NotificationsSnoozer: NotificationsSnoozerCore {
    
    internal func overview(at date: Date,
                           ofCase type: NotificationsSnoozerCore.Configuration.CodingKeys? = nil) -> String
    {
        guard case let activeConfigs = self.activeConfigurations(at: date, ofCase: type), !activeConfigs.isEmpty else {
            return "Notification Snooze".localized
        }
        let descriptions: [String] = activeConfigs.compactMap { $0.localizedDescription(at: date) }
        return descriptions.joined(separator: ", ")
    }
    
    internal func quickOptionsDialog(for date: Date,
                                     toPresentOn presenter: UIViewController,
                                     onStateChangedTo: ((Bool)->Void)? = nil) -> UIViewController
    {
        // time-based options
        let minutes = [30].map { (unit: Measurement<UnitDuration>(value: Double($0), unit: .minutes),
                                  component: DateComponents(minute: $0)) }
        let hours = [1, 2, 4, 8].map { (unit: Measurement<UnitDuration>(value: Double($0), unit: .hours),
                                        component: DateComponents(hour: $0)) }
        var timeBasedOptions = minutes
        timeBasedOptions.append(contentsOf: hours)
        
        // Measurement has plural nouns localization out of the box
        let formatter = MeasurementFormatter()
        formatter.unitStyle = .long
        
        let timeBasedActions = timeBasedOptions.map { time in
            UIAlertAction(title: formatter.string(from: time.unit), style: .default) { _ in
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                self.unsnoozeNonRepeating()
                let dateWhenUserActivatedSnooze = Date() // here we need date of tap, not creation!
                self.add(.quick(rule: .init(duration: time.component, since: dateWhenUserActivatedSnooze)))
                onStateChangedTo?(true)
            }
        }
        
        let dialog = UIAlertController(title: nil, message: self.overview(at: date), preferredStyle: .actionSheet)
        
        // other actions
        let turnOff = UIAlertAction(title: "Turn Off".localized, style: .destructive) { _ in
            self.unsnoozeNonRepeating()
            onStateChangedTo?(false)
        }
        let custom = UIAlertAction(title: "Custom".localized, style: .default) { _ in
            let configs = self.activeConfigurations(at: date)
            
            var defaultSelection: (Int, Int) = (0, 0)
            if let activeQuickRule = configs.first(where: { $0.belongs(to: .quick) })?.rule,
                let soonestEnd = activeQuickRule.soonestEnd(from: date),
                case let components = Calendar.current.dateComponents([.hour, .minute], from: date, to: soonestEnd),
                let hour = components.hour, let minute = components.minute
            {
                defaultSelection = (hour, minute)
            }
            
            let picker = DurationPickerViewController(select: defaultSelection) { (hour, minute) in
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                self.unsnoozeNonRepeating()
                let dateWhenUserActivatedSnooze = Date() // since tap, not creation
                self.add(.quick(rule: CalendarIntervalRule(duration: .init(hour: hour, minute: minute), since: dateWhenUserActivatedSnooze)))
                onStateChangedTo?(true)
            }
            presenter.present(picker, animated: true, completion: nil)
        }
        let scheduled = UIAlertAction(title: "Scheduled".localized, style: .default) { _ in
            onStateChangedTo?(self.isSnoozeActive(at: Date()))
            guard let menu = presenter as? MenuViewController else { return }
            menu.performSegue(withIdentifier: menu.kSegueToSettings, sender: self)
        }
        let cancel = UIAlertAction(title: "Cancel".localized, style: .cancel) { _ in dialog.dismiss(animated: true, completion: nil) }
        
        // bring everything together
        
        if self.isNonRepeatingSnoozeActive(at: date) {
            [turnOff].forEach( dialog.addAction )
        }
        timeBasedActions.forEach( dialog.addAction )
        [custom, scheduled, cancel].forEach( dialog.addAction )
        
        return dialog
    }
}


@available(iOS 10.0, *)
extension NotificationsSnoozer.Configuration {
    private static var durationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowsFractionalUnits = false
        formatter.allowedUnits = [.hour, .minute]
        formatter.formattingContext = .middleOfSentence
        formatter.unitsStyle = .short
        return formatter
    }()
    private static var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
    
    fileprivate func localizedDescription(at date: Date) -> String? {
        switch self {
        case .quick(rule: let rule):
            guard let soonestEnd = rule.soonestEnd(from: date),
                let formattedString = NotificationsSnoozer.Configuration.durationFormatter.string(from: Date(), to: soonestEnd) else
            {
                return nil
            }
            
            return "Snoozed for".localized + " " + formattedString
            
        case .scheduled(rule: let rule):
            guard let soonestEnd = rule.soonestEnd(from: date) else {
                return nil
            }
            
            return "Snoozed till".localized + " " + NotificationsSnoozer.Configuration.dateFormatter.string(from: soonestEnd)
        }
    }
}
