//
//  CryptoGoProtocols.swift
//  ProtonCore-CryptoGoImplementation - Created on 24/05/2023.
//
//  Copyright (c) 2023 Proton Technologies AG
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
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore. If not, see https://www.gnu.org/licenses/.
//

import Foundation
import GoLibs
import ProtonCoreCryptoGoInterface

extension ProtonCoreCryptoGoInterface.CryptoReaderProtocol {
    var toGoLibsType: GoLibs.CryptoReaderProtocol {
        if let goLibsReader = self as? GoLibs.CryptoReaderProtocol {
            return goLibsReader
        } else {
            return AnyGoLibsCryptoReader(cryptoReader: self)
        }
    }
}

final class AnyGoLibsCryptoReader: NSObject, GoLibs.CryptoReaderProtocol {

    let readClosure: (Data?, UnsafeMutablePointer<Int>?) throws -> Void

    init<T>(cryptoReader: T) where T: ProtonCoreCryptoGoInterface.CryptoReaderProtocol {
        self.readClosure = { b, n in try cryptoReader.read(b, n: n) }
    }

    func read(_ b: Data?, n: UnsafeMutablePointer<Int>?) throws {
        try readClosure(b, n)
    }
}

extension ProtonCoreCryptoGoInterface.CryptoMIMECallbacksProtocol {
    var toGoLibsType: GoLibs.CryptoMIMECallbacksProtocol {
        if let goLibsCallbacks = self as? GoLibs.CryptoMIMECallbacksProtocol {
            return goLibsCallbacks
        } else {
            return AnyGoLibsCryptoMIMECallbacks(cryptoCallbacks: self)
        }
    }
}

final class AnyGoLibsCryptoMIMECallbacks: NSObject, GoLibs.CryptoMIMECallbacksProtocol {

    private let onAttachmentClosure: (String?, Data?) -> ()
    private let onBodyClosure: (String?, String?) -> ()
    private let onEncryptedHeadersClosure: (String?) -> ()
    private let onErrorClosure: (Error?) -> ()
    private let onVerifiedClosure: (Int) -> ()

    init<T>(cryptoCallbacks: T) where T: ProtonCoreCryptoGoInterface.CryptoMIMECallbacksProtocol {
        self.onAttachmentClosure = { headers, data in cryptoCallbacks.onAttachment(headers, data: data)
        }
        self.onBodyClosure = { body, mimetype in
            cryptoCallbacks.onBody(body, mimetype: mimetype)
        }
        self.onEncryptedHeadersClosure = { headers in
            cryptoCallbacks.onEncryptedHeaders(headers)
        }
        self.onErrorClosure = { error in
            cryptoCallbacks.onError(error)
        }
        self.onVerifiedClosure = { verified in
            cryptoCallbacks.onVerified(verified)
        }
    }

    func onAttachment(_ headers: String?, data: Data?) {
        self.onAttachmentClosure(headers, data)
    }

    func onBody(_ body: String?, mimetype: String?) {
        self.onBodyClosure(body, mimetype)
    }

    func onEncryptedHeaders(_ headers: String?) {
        self.onEncryptedHeadersClosure(headers)
    }

    func onError(_ err: Error?) {
        self.onErrorClosure(err)
    }

    func onVerified(_ verified: Int) {
        self.onVerifiedClosure(verified)
    }
}

extension ProtonCoreCryptoGoInterface.CryptoWriterProtocol {
    var toGoLibsType: GoLibs.CryptoWriterProtocol {
        if let goLibsWriter = self as? GoLibs.CryptoWriterProtocol {
            return goLibsWriter
        } else {
            return AnyGoLibsCryptoWriter(cryptoWriter: self)
        }
    }
}

final class AnyGoLibsCryptoWriter: NSObject, GoLibs.CryptoWriterProtocol {

    private let writeClosure: (Data?, UnsafeMutablePointer<Int>?) throws -> Void

    init<T>(cryptoWriter: T) where T: ProtonCoreCryptoGoInterface.CryptoWriterProtocol {
        self.writeClosure = { b, n in try cryptoWriter.write(b, n: n) }
    }

    func write(_ b: Data?, n: UnsafeMutablePointer<Int>?) throws {
        try writeClosure(b, n)
    }
}

extension GoLibs.CryptoWriteCloserProtocol {
    var toCryptoGoType: ProtonCoreCryptoGoInterface.CryptoWriteCloserProtocol {
        if let goLibsWriter = self as? ProtonCoreCryptoGoInterface.CryptoWriteCloserProtocol {
            return goLibsWriter
        } else {
            return AnyCryptoGoWriteCloser(cryptoWriteCloser: self)
        }
    }
}

final class AnyCryptoGoWriteCloser: NSObject, ProtonCoreCryptoGoInterface.CryptoWriteCloserProtocol {
    private let closeClosure: () throws -> ()
    private let writeClosure: (Data?, UnsafeMutablePointer<Int>?) throws -> ()

    init<T>(cryptoWriteCloser: T) where T: GoLibs.CryptoWriteCloserProtocol {
        self.closeClosure = { try cryptoWriteCloser.close() }
        self.writeClosure = { b, n in try cryptoWriteCloser.write(b, n: n) }
    }

    func close() throws {
        try closeClosure()
    }

    func write(_ b: Data?, n: UnsafeMutablePointer<Int>?) throws {
        try writeClosure(b, n)
    }
}

extension ProtonCoreCryptoGoInterface.CryptoWriteCloserProtocol {
    var toGoLibsType: GoLibs.CryptoWriteCloserProtocol {
        if let goLibsWriter = self as? GoLibs.CryptoWriteCloserProtocol {
            return goLibsWriter
        } else {
            return AnyGoLibsWriteCloser(cryptoWriteCloser: self)
        }
    }
}

final class AnyGoLibsWriteCloser: NSObject, GoLibs.CryptoWriteCloserProtocol {
    private let closeClosure: () throws -> ()
    private let writeClosure: (Data?, UnsafeMutablePointer<Int>?) throws -> ()

    init<T>(cryptoWriteCloser: T) where T: ProtonCoreCryptoGoInterface.CryptoWriteCloserProtocol {
        self.closeClosure = { try cryptoWriteCloser.close() }
        self.writeClosure = { b, n in try cryptoWriteCloser.write(b, n: n) }
    }

    func close() throws {
        try closeClosure()
    }

    func write(_ b: Data?, n: UnsafeMutablePointer<Int>?) throws {
        try writeClosure(b, n)
    }
}

extension ProtonCoreCryptoGoInterface.HelperMobileReaderProtocol {
    var toGoLibsType: GoLibs.HelperMobileReaderProtocol {
        if let goLibsHelperMobileReader = self as? GoLibs.HelperMobileReaderProtocol {
            return goLibsHelperMobileReader
        } else {
            return AnyGoLibsHelperMobileReader(helperMobileReader: self)
        }
    }
}

final class AnyGoLibsHelperMobileReader: NSObject, GoLibs.HelperMobileReaderProtocol {
    private let readClosure: (Int) throws -> GoLibs.HelperMobileReadResult

    init<T>(helperMobileReader: T) where T: ProtonCoreCryptoGoInterface.HelperMobileReaderProtocol {
        self.readClosure = { max in try helperMobileReader.read(max).toGoLibsType }
    }

    func read(_ max: Int) throws -> GoLibs.HelperMobileReadResult {
        try readClosure(max)
    }
}


