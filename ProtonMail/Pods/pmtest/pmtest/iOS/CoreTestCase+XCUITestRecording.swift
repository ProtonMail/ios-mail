//
//  CoreTestCase+XCUITestRecording.swift
//
//  ProtonMail - Created on 29.01.22.
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

import XCTest

/**
 * Extension for  CoreTestCase to adopt the XCUITestCaseRecording protocol.
 */
extension CoreTestCase: XCUITestCaseRecording {

    /**
     Set the interval between the testrecorder's screenshots.
     */
    public func setRecorderTimeInterval(timeInterval: TimeInterval) {
        testRecorder.timeInterval = timeInterval
    }

    /**
     Start/resume test recording.
     */
    public func resumeRecording() {
        testRecorder.resumeRecording()
    }

    /**
     Pause test recording.
     */
    public func pauseRecording() {
        testRecorder.pauseRecording()
    }

    /**
     Add recorded test as a gif attachment. Will be available in the .xcresult file.
     */
    public func addGifAttachment() {
        if let gifAttachment = testRecorder.generateGifAttachment() {
            add(gifAttachment)
        }
    }

    /**
     Add recorded test as a video attachment. Will be available in the .xcresult file. Returns after video is added.
     */
    public func addVideoAttachment() {
        let expectation = XCTestExpectation(description: "\(XCUITestCaseRecording.self).video")
        testRecorder.generateVideoAttachment { videoAttachment in
            if let videoAttachment = videoAttachment {
                self.add(videoAttachment)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 50)
    }
}
