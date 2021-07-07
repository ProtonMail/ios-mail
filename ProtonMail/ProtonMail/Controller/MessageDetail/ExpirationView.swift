//
//  ExpirationView.swift
//  ProtonMail - Created on 3/22/16.
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

import Foundation

//@IBDesignable
class ExpirationView: PMView {
    
    @IBOutlet weak var expirationLabel: UILabel!
    
    override func getNibName() -> String {
        return "ExpirationView"
    }
    
    func setExpirationTime(_ offset : Int) {
        let (d,h,m,s) = durationsBySecond(seconds: offset)
        if offset <= 0 {
            expirationLabel.text = LocalString._message_expired
        } else {
            expirationLabel.text = String(format: LocalString._expires_in_days_hours_mins_seconds, d, h, m, s)
        }
    }
    
    func durationsBySecond(seconds s: Int) -> (days:Int,hours:Int,minutes:Int,seconds:Int) {
        return (s / (24 * 3600),(s % (24 * 3600)) / 3600, s % 3600 / 60, s % 60)
    }
}

class ExpirationCell: UITableViewCell {
    @IBOutlet weak var expirationView: ExpirationView!
    private var timer : Timer!
    private var expiration: Date = .distantFuture
    var handleExpired: (() -> Void)?
    
    private func autoTimer() {
        let offset = Int(self.expiration.timeIntervalSince(Date()))
        if offset <= 0 {
            handleExpired?()
        }
        self.expirationView.setExpirationTime(offset)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.expiration = .distantFuture
        self.timer = nil
    }
    
    internal func set(expiration: Date) {
        self.expiration = expiration
        self.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.autoTimer()
        }
        self.timer.fire()
    }
}
