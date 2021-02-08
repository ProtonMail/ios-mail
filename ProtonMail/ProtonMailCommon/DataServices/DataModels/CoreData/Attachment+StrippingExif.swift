//
//  Attachment+StrippingExif.swift
//  ProtonMail - Created on 22/08/2019.
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

extension URL {
    func strippingExif() -> URL {
        guard let source = CGImageSourceCreateWithURL(self as CFURL, nil),
            let type = CGImageSourceGetType(source),
            case let count = CGImageSourceGetCount(source) else
        {
            // this happens when data is not an image, which is okay
            return self
        }
        
        let stripped = self
        guard let destination = CGImageDestinationCreateWithURL(stripped as CFURL, type, count, nil) else {
            assert(false, "Failed to strip EXIF from URL: could not create destination")
            return self
        }
        
        let properties = Attachment.propertiesToStrip()
        for index in 0 ..< count {
            CGImageDestinationAddImageFromSource(destination, source, index, properties)
        }
        
        guard CGImageDestinationFinalize(destination) else {
            assert(false, "Failed to strip EXIF from URL: could not finalize")
            return self
        }
        
        return stripped as URL
    }
}

extension Data {
    func strippingExif() -> Data {
        guard let source = CGImageSourceCreateWithData(self as CFData, nil),
            let type = CGImageSourceGetType(source),
            case let count = CGImageSourceGetCount(source) else
        {
            // this happens when data is not an image, which is okay
            return self
        }
        
        let stripped = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(stripped as CFMutableData, type, count, nil) else {
            assert(false, "Failed to strip EXIF from Data: could not create destination")
            return self
        }
        
        let properties = Attachment.propertiesToStrip()
        for index in 0 ..< count {
            CGImageDestinationAddImageFromSource(destination, source, index, properties)
        }
        
        guard CGImageDestinationFinalize(destination) else {
            assert(false, "Failed to strip EXIF from Data: could not finalize")
            return self
        }
        
        return stripped as Data
    }
}


extension Attachment {
    static func propertiesToStrip() -> CFDictionary {
        /* See full list: https://developer.apple.com/documentation/imageio/cgimageproperties */
        
        var dict: Dictionary<CFString, Any?> = [
            // format-specific
            kCGImagePropertyExifDictionary: nil,
            kCGImagePropertyGPSDictionary: nil,
            kCGImagePropertyIPTCDictionary: nil,
            kCGImagePropertyIPTCCreatorContactInfo: nil,
            kCGImagePropertyCIFFDictionary: nil,
            kCGImageProperty8BIMDictionary: nil,
            kCGImagePropertyDNGDictionary: nil,
            kCGImagePropertyExifAuxDictionary: nil,
        
            kCGImagePropertyTIFFDictionary: [
                kCGImagePropertyTIFFDocumentName: nil,
                kCGImagePropertyTIFFImageDescription: nil,
                kCGImagePropertyTIFFMake: nil,
                kCGImagePropertyTIFFModel: nil,
                kCGImagePropertyTIFFDateTime: nil,
                kCGImagePropertyTIFFHostComputer: nil,
                kCGImagePropertyTIFFArtist: nil,
                kCGImagePropertyTIFFCopyright: nil,
                kCGImagePropertyTIFFSoftware: nil
            ],

            kCGImagePropertyPNGDictionary : [
                kCGImagePropertyPNGAuthor: nil,
                kCGImagePropertyPNGCopyright: nil,
                kCGImagePropertyPNGSoftware: nil,
                kCGImagePropertyPNGCreationTime: nil,
                kCGImagePropertyPNGDescription: nil,
                kCGImagePropertyPNGModificationTime: nil,
                kCGImagePropertyPNGTitle: nil,
            ],

            // camera makers
            kCGImagePropertyMakerCanonDictionary: nil,
            kCGImagePropertyMakerNikonDictionary: nil,
            kCGImagePropertyMakerMinoltaDictionary: nil,
            kCGImagePropertyMakerFujiDictionary: nil,
            kCGImagePropertyMakerOlympusDictionary: nil,
            kCGImagePropertyMakerPentaxDictionary: nil
        ]

        dict[kCGImagePropertyFileContentsDictionary] = nil

        return dict as CFDictionary
    }
}
