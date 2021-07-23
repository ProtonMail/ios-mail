//
//  MailPlansViewModel.swift
//  ProtonCore_PaymentsUI - Created on 01/06/2021.
//
//  Copyright (c) 2021 Proton Technologies AG
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

import ProtonCore_Payments

final class MailPlansViewModel: PaymentsUIViewModelProtocol {
    var plansToShow: [AccountPlan] = [AccountPlan.free, AccountPlan.mailPlus]
    var allPaidPlans: [AccountPlan] = [AccountPlan.mailPlus, AccountPlan.pro, AccountPlan.visionary]
}

final class VPNPlansViewModel: PaymentsUIViewModelProtocol {
    var plansToShow: [AccountPlan] = [AccountPlan.free, AccountPlan.vpnBasic, AccountPlan.vpnPlus]
    var allPaidPlans: [AccountPlan] = [AccountPlan.vpnBasic, AccountPlan.vpnPlus, AccountPlan.visionary]
}
