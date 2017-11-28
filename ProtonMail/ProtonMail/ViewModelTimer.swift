//
//  ViewModelTimer.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 11/28/17.
//  Copyright © 2017 ProtonMail. All rights reserved.
//

import Foundation

class ViewModelTimer {
    
    private var timer : Timer?
    private var fetchingStopped : Bool = true
    
    // MARK: - Private methods
    func setupTimer(_ run : Bool = true, timerInterval: TimeInterval = 30) {
        self.timer = Timer.scheduledTimer(timeInterval: timerInterval,
                                          target: self,
                                          selector: #selector(timerAction),
                                          userInfo: nil,
                                          repeats: true)
        fetchingStopped = false
        if run {
            self.timer?.fire()
        }
    }
    
    func stopTimer()
    {
        fetchingStopped = true
        if let t = self.timer {
            t.invalidate()
            self.timer = nil
        }
    }
    
    @objc private func timerAction()
    {
        if !fetchingStopped {
            self.fireFetch()
        }
    }
    
    func fireFetch() {
        fatalError("This method must be overridden")
    }
}
