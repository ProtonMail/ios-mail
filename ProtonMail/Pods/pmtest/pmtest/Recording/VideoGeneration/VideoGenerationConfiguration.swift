//
//  VideoGenerationConfiguration.swift
//
//  ProtonMail - Created on 26.01.22.
//
//  The MIT License
//
//  Copyright (c) 2020 Proton Technologies AG
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

import AVFoundation
import UIKit
import Photos

struct VideoGenerationConfiguration {

    var outputUrl: URL
    var fileType: AVFileType
    var size: CGSize = UIScreen.main.bounds.size
    var fps: Int32 = 60
    var avCodecKey: AVVideoCodecType = .h264
    var timescale: Int32 = 600
    var frameDurationInSeconds: Float64 = 0.3

    var avOutputSettings: [String: Any] {
        [ AVVideoCodecKey: avCodecKey,
          AVVideoWidthKey: NSNumber(value: Float(size.width)),
          AVVideoHeightKey: NSNumber(value: Float(size.height)) ]
    }
}
