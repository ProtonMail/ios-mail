//
//  ViewModelTimer.swift
//  ProtonMail
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


import Foundation

//Timer for view model could merge with Base
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
    
    func stopTimer() {
        fetchingStopped = true
        if let t = self.timer {
            t.invalidate()
            self.timer = nil
        }
    }
    
    @objc private func timerAction() {
        if !fetchingStopped {
            self.fireFetch()
        }
    }
    
    func fireFetch() {
        fatalError("This method must be overridden")
    }
}
