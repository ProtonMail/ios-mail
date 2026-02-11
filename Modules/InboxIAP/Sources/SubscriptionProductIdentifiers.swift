// Copyright (c) 2024 Proton Technologies AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

public enum SubscriptionPlanVariant {
    public static let plus = "mail2022"
    public static let unlimited = "bundle2022"
}

public enum FullSubscriptionProductID {
    public static let unlimitedYear = "iosmail_\(SubscriptionPlanVariant.unlimited)_12_usd_auto_renewing"
    public static let unlimitedMonth = "iosmail_\(SubscriptionPlanVariant.unlimited)_1_usd_auto_renewing"
    public static let plusYear = "iosmail_\(SubscriptionPlanVariant.plus)_12_usd_auto_renewing"
    public static let plusMonth = "iosmail_\(SubscriptionPlanVariant.plus)_1_usd_auto_renewing"
}
