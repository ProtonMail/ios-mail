// Copyright (c) 2022 Proton Technologies AG
//
// This file is part of Proton Technologies AG and Proton Calendar.
//
// Proton Calendar is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Calendar is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Calendar. If not, see https://www.gnu.org/licenses/.

import EventKit
import Foundation

public class ICalPropertyWriter: ICalPropertyWriterProtocol {
    public let property: OpaquePointer

    /// Stores the objects for they'll be deinit once we don't hold them
    private(set) var parameters: [ICalParameterWriterProtocol] = []
    private(set) var value: ICalValueWriterProtocol?

    private var deinited: Bool = false

    init(_ property: OpaquePointer) {
        self.property = property
    }

    deinit {
        guard deinited == false else { return }
        icalproperty_free(property)
        setDeinited()
    }

    public func setDeinited() {
        guard self.deinited == false else { return }

        self.deinited = true

        self.parameters.forEach {
            $0.setDeinited()
        }

        self.value?.setDeinited()
    }

    // MARK: Helper

    @discardableResult
    func addParameter(safe parameter: OpaquePointer) -> ICalParameterWriter {
        let object = ICalParameterWriter(parameter)
        parameters.append(object)
        icalproperty_add_parameter(self.property, parameter)
        return object
    }

    @discardableResult
    func setValue(safe value: OpaquePointer) -> ICalValueWriter {
        let object = ICalValueWriter(value)
        self.value = object
        icalproperty_set_value(self.property, value)
        return object
    }

    var isEmpty: Bool {
        self.parameters.isEmpty && self.value == nil
    }

    // MARK: Shared Parameter

    @discardableResult
    func addCN(_ cn: String) -> Self {
        addParameter(safe: icalparameter_new_cn(cn))
        return self
    }

    /// It adds `RSVP` set to `true`.
    /// Default value for this property is `false` (RFC: https://www.ietf.org/rfc/rfc2445.txt)
    @discardableResult
    func addRSVPTrue() -> Self {
        addParameter(safe: icalparameter_new_rsvp(ICAL_RSVP_TRUE))
        return self
    }

    /// It adds `ROLE` with `OPT-PARTICIPANT` value only, any other role will be skipped.
    /// Default value for this property is `REQ-PARTICIPANT` (RFC: https://www.ietf.org/rfc/rfc2445.txt)
    func addRole(_ role: EKParticipantRole) -> Self {
        switch role {
        case .optional:
            _ = addRole(ICAL_ROLE_OPTPARTICIPANT)
        default:
            break
        }
        return self
    }

    private func addRole(_ role: icalparameter_role) -> Self {
        addParameter(safe: icalparameter_new_role(role))
        return self
    }

    /// Only NEEDS_ACTION, ACCEPTED, DECLINED, TENTATIVE or DELEGATED.
    func addPartstat(_ state: icalparameter_partstat) -> Self {
        self.addParameter(safe: icalparameter_new_partstat(state))
        return self
    }

    /// Only NEEDS_ACTION, ACCEPTED, DECLINED, TENTATIVE or DELEGATED.
    func addPartstat(_ status: EKParticipantStatus) -> Self {
        switch status {
        case .pending:
            _ = self.addPartstat(ICAL_PARTSTAT_NEEDSACTION)
        case .accepted:
            _ = self.addPartstat(ICAL_PARTSTAT_ACCEPTED)
        case .declined:
            _ = self.addPartstat(ICAL_PARTSTAT_DECLINED)
        case .tentative:
            _ = self.addPartstat(ICAL_PARTSTAT_TENTATIVE)
        case .delegated:
            _ = self.addPartstat(ICAL_PARTSTAT_DELEGATED)
        case .unknown:
            // Not add this when it's unknown
            // Common case is organizer, for which shouldn't have this as in RFC.
            break
        default:
            break
        }
        return self
    }

    // MARK: Shared value

    @discardableResult
    func addMailTo(_ email: String) -> Self {
        let mailto = "mailto:" + email
        self.setValue(safe: icalvalue_new_caladdress(mailto))
        return self
    }

    @discardableResult
    func addToken(_ token: String) -> Self {
        let parameter = icalparameter_new_x(token)
        icalparameter_set_xname(parameter, "X-PM-TOKEN")
        self.addParameter(safe: parameter.unsafelyUnwrapped)
        return self
    }
}
