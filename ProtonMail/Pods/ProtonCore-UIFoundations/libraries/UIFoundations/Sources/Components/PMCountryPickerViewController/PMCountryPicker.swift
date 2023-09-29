//
//  PMCountryPicker.swift
//  ProtonCore-UIFoundations - Created on 12.03.21.
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

#if os(iOS)

import UIKit

public class PMCountryPicker {

    let countryCodeViewModel: CountryCodeViewModel

    public init(searchBarPlaceholderText: String) {
        countryCodeViewModel = CountryCodeViewModel(searchBarPlaceholderText: searchBarPlaceholderText)
    }

    public func getCountryPickerViewController(inAppTheme: () -> InAppTheme) -> CountryPickerViewController {
        let countryPickerViewController = instantiateVC(method: CountryPickerViewController.self, identifier: "CountryPickerViewController", inAppTheme: inAppTheme)
        countryPickerViewController.viewModel = countryCodeViewModel
        return countryPickerViewController
    }

    public func getInitialCode() -> Int {
        return countryCodeViewModel.getPhoneCodeFromName(NSLocale.current.regionCode)
    }
}

extension PMCountryPicker {
    private func instantiateVC<T: UIViewController>(
        method: T.Type, identifier: String, inAppTheme: () -> InAppTheme
    ) -> T {
        let storyboard = UIStoryboard.init(name: "CountryPicker", bundle: PMUIFoundations.bundle)
        let customViewController = storyboard.instantiateViewController(withIdentifier: identifier) as! T
        customViewController.overrideUserInterfaceStyle = inAppTheme().userInterfaceStyle
        return customViewController
    }
}

#endif
