//
//  SplashScreenViewControllerFactory.swift
//  ProtonCore-UIFoundations - Created on 04.04.2022.
//
//  Copyright (c) 2022 Proton Technologies AG
//
//  This file is part of Proton Technologies AG and ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore.  If not, see <https://www.gnu.org/licenses/>.

public enum SplashScreenIBVariant: Int {
    case mail = 1
    case calendar = 2
    case drive = 3
    case vpn = 4
}

public enum SplashScreenViewControllerFactory {
    
    public static func instantiate(for variant: SplashScreenIBVariant) -> UIViewController {
        let storyboardName: String
        switch variant {
        case .mail:
            storyboardName = "MailLaunchScreen"
        case .drive:
            storyboardName = "DriveLaunchScreen"
        case .calendar:
            storyboardName = "CalendarLaunchScreen"
        case .vpn:
            storyboardName = "VPNLaunchScreen"
        }
        let storyboard = UIStoryboard(name: storyboardName, bundle: .main)
        guard let splash = storyboard.instantiateInitialViewController() else {
            assertionFailure("Cannot instantiate launch screen view controller")
            return UIViewController(nibName: nil, bundle: nil)
        }
        return splash
    }
    
}
