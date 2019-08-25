//
//  Attachment+StrippingExif.swift
//  ProtonMail - Created on 22/08/2019.
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
        
        if #available(iOS 11.0, *) {
            dict[kCGImagePropertyFileContentsDictionary] = nil
        }

        return dict as CFDictionary
    }
}
