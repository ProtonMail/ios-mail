//
//  JailCommands.swift
//  ProtonCore-QuarkCommands - Created on 08.12.2023.
//
// Copyright (c) 2023. Proton Technologies AG
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

import Foundation

private let seedSubscriber = "quark/raw::payments:seed-subscriber"
private let seedPaymentMethod = "quark/raw::payments:seed-payment-method"
private let makeDelinquent = "quark/raw::payments:make-delinquent"

public extension Quark {

    enum DelinquentState: Int {
        case paid = 0
        /// unpaid invoice available for 7 days or less
        case availableLessThan7Days
        /// unpaid invoice with payment overdue for more than 7 days
        case overdueMoreThan7Days
        /// unpaid invoice with payment overdue for more than 14 days, the user is considered Delinquent
        case overdueMoreThan14Days
        /// unpaid invoice with payment not received for more than 30 days, the user is considered Delinquent
        case overdueMoreThan30Days
    }

    @discardableResult
    func seedNewSubscriber(user: User, plan: UserPlan, state: DelinquentState = .paid) throws -> User {

        let args = [
            "username=\(user.name)",
            "password=\(user.password)",
            "plan=\(plan)",
            "state=\(state)"
        ]

        let request = try route(seedSubscriber)
            .args(args)
            .build()

        do {
            let (textData, urlResponse) = try executeQuarkRequest(request)
            guard let responseHTML = String(data: textData, encoding: .utf8) else {
                throw QuarkError(urlResponse: urlResponse, message: "Unable to decode response")
            }

            let startPattern = "(ID "
            let endPattern = ")"

            guard let rangeStart = responseHTML.range(of: startPattern),
                  let rangeEnd = responseHTML[rangeStart.upperBound...].range(of: endPattern) else {
                throw QuarkError(urlResponse: urlResponse, message: "Unable to parse User ID")
            }

            let idStartIndex = rangeStart.upperBound
            let idEndIndex = rangeEnd.lowerBound

            let idString = String(responseHTML[idStartIndex..<idEndIndex])

            guard let id = Int(idString) else {
                throw QuarkError(urlResponse: urlResponse, message: "Parsed User ID is not a valid number")
            }

            var newUser = user
            newUser.id = id
            return newUser
        } catch {
            throw error
        }
    }

    @discardableResult
    func seedNewSubscriberWithCycle(user: User, plan: UserPlan, cycleDurationMonths: Int) throws -> (data: Data, response: URLResponse) {

        let args = [
            "username=\(user.name)",
            "password=\(user.password)",
            "plan=\(plan)",
            "cycle=\(cycleDurationMonths)"
        ]

        let request = try route(seedSubscriber)
            .args(args)
            .build()

        return try executeQuarkRequest(request)
    }

    @discardableResult
    func seedUserWithCreditCard(user: User) throws -> (data: Data, response: URLResponse) {

        let args = [
            "-u=\(user.name)",
            "-p=\(user.password)",
            "-t=card"
        ]

        let request = try route(seedPaymentMethod)
            .args(args)
            .build()

        return try executeQuarkRequest(request)
    }

    func updateDelinquentState(state: DelinquentState, for username: String) throws {
        let args = [
            "username=\(username)&&--delinquentState=\(state.rawValue)"
        ]

        let request = try route(makeDelinquent)
            .args(args)
            .build()

        do {
            let (textData, urlResponse) = try executeQuarkRequest(request)
            guard
                let responseHTML = String(data: textData, encoding: .utf8),
                responseHTML.contains("Done")
            else {
                throw QuarkError(urlResponse: urlResponse, message: "Update delinquent state failed")
            }
        } catch {
            throw error
        }
    }
}
