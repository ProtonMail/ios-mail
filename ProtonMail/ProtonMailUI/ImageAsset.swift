// Copyright (c) 2023 Proton Technologies AG
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

import UIKit

public class ImageAsset {
    static var autoImportContactsSpotlight: UIImage {
        UIImage(named: "auto_import_contacts_spotlight", in: Bundle(for: LocalImage.self), with: nil)!
    }

    static var autoImportContactsNoContact: UIImage {
        UIImage(named: "auto_import_contacts_no_contact", in: Bundle(for: LocalImage.self), with: nil)!
    }

    static var jumpToNextSpotlight: UIImage {
        UIImage(named: "jumpToNext_spotlight", in: Bundle(for: LocalImage.self), with: nil)!
    }

    static var rsvpSpotlight: UIImage {
        UIImage(named: "rsvp_spotlight", in: Bundle(for: LocalImage.self), with: nil)!
    }

    static var contactSync: UIImage {
        UIImage(named: "contact_sync", in: Bundle(for: LocalImage.self), with: nil)!
    }
}

private class LocalImage {
    // only to provide a Bundle reference
}
