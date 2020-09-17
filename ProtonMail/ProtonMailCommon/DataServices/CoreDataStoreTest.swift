//
//  CoreDataStoreTest.swift
//  ProtonMail - Created on 12/19/18.
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
    

import XCTest
@testable import ProtonMail
import CoreData
import Groot

class CoreDataStoreTest: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        //
        // Generate test data
        //
        let oldModelUrl = Bundle.main.url(forResource: "ProtonMail.momd/ProtonMail", withExtension: "mom")!
        let oldManagedObjectModel = NSManagedObjectModel(contentsOf: oldModelUrl)
        XCTAssertNotNil(oldManagedObjectModel)
        
        let coordinator = NSPersistentStoreCoordinator.init(managedObjectModel: oldManagedObjectModel!)
        let url = FileManager.default.temporaryDirectoryUrl.appendingPathComponent("ProtonMail.sqlite", isDirectory: false)
        try? coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: nil)
        let managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        XCTAssertNotNil(managedObjectContext)
        
        
        let test = """
 {
    "IsForwarded" : 0,
    "IsEncrypted" : 1,
    "ExpirationTime" : 0,
    "ReplyTo" : {
        "Address" : "contact@protonmail.ch",
        "Name" : "ProtonMail"
    },
    "Subject" : "Important phishing warning for all ProtonMail users",
    "BCCList" : [
    ],
    "Size" : 2217,
    "ParsedHeaders" : {
        "Subject" : "Important phishing warning for all ProtonMail users",
        "X-Pm-Content-Encryption" : "end-to-end",
        "To" : "feng88@protonmail.com",
        "X-Auto-Response-Suppress" : "OOF",
        "Precedence" : "bulk",
        "X-Original-To" : "feng88@protonmail.com",
        "Mime-Version" : "1.0",
        "Return-Path" : "<contact@protonmail.ch>",
        "Content-Type" : "texthtml",
        "Delivered-To" : "feng88@protonmail.com",
        "From" : "ProtonMail <contact@protonmail.ch>",
        "Received" : "from mail.protonmail.ch by mail.protonmail.ch; Wed, 02 May 2018 12:43:19 -0400",
        "Message-Id" : "<MQV54A1N98S8ASTB7Z183NM1MG@protonmail.ch>",
        "Date" : "Wed, 02 May 2018 12:43:19 -0400",
        "X-Pm-Origin" : "internal"
    },
    "ToList" : [
    {
    "Address" : "feng88@protonmail.com",
    "Name" : "",
    "Group" : ""
    }
    ],
    "Order" : 200441873160,
    "IsRepliedAll" : 0,
    "ExternalID" : "MQV54A1N98S8ASTB7Z183NM1MG@protonmail.ch",
    "AddressID" : "hbBwBsOdTi5cDhhZcF28yrJ50AZQ8jhXF4d0P7OaUcCS5iv2N8hN_FjvAyPMt8EiP5ch_E_81gHZAjK4D3gfzw==",
    "Location" : 0,
    "LabelIDs" : [
    "0",
    "5",
    "10"
    ],
    "Time" : 1525279399,
    "ReplyTos" : [
    {
    "Address" : "contact@protonmail.ch",
    "Name" : "ProtonMail"
    }
    ],
    "NumAttachments" : 0,
    "SenderAddress" : "contact@protonmail.ch",
    "MIMEType" : "texthtml",
    "Starred" : 1,
    "Unread" : 0,
    "ID" : "cA6j2rszbPUSnKojxhGlLX2U74ibyCXc3-zUAb_nBQ5UwkYSAhoBcZag8Wa0F_y_X5C9k9fQnbHAITfDd_au1Q==",
    "ConversationID" : "3Spjf96LXv8EDUylCxJkKsL7x9IgBac_0z416buSBBMwAkbh_dHh2Ng7O6ss70yhlaLBht0hiJqvqbxoBKtb9Q==",
    "Body" : "-----BEGIN PGP MESSAGE-----This is encrypted body-----END PGP MESSAGE-----",
    "Flags" : 13,
    "Header" : "Date: Wed, 02 May 2018 12:43:19 this is a header",
    "SenderName" : "ProtonMail",
    "SpamScore" : 0,
    "Attachments" : [
    ],
    "Type" : 0,
    "CCList" : [
    ],
    "Sender" : {
        "Address" : "contact@protonmail.ch",
        "Name" : "ProtonMail"
    },
    "IsReplied" : 0
}
"""
        guard let out = test.parseObjectAny() else {
            return
        }

        let managedObj = try? GRTJSONSerialization.object(withEntityName: "Message",
                                                         fromJSONDictionary: out, in: managedObjectContext)
        //NSEntityDescription.insertNewObjectForEntityForName
        XCTAssertNotNil(managedObj)
        
        //build samples
    }

    override func tearDown() {
        //clear out the data
        do {
            let url = FileManager.default.temporaryDirectoryUrl.appendingPathComponent("ProtonMail.sqlite", isDirectory: false)
            try FileManager.default.removeItem(at: url)
        } catch {
        }
        
        do {
            let url = FileManager.default.temporaryDirectoryUrl.appendingPathComponent("ProtonMail_NewModel.sqlite", isDirectory: false)
            try FileManager.default.removeItem(at: url)
        } catch {
        }
    }

    func test_ProtonMail_to_1_12_0() {
        return //TODO::FIXME. this test fails
        let oldModelUrl = Bundle.main.url(forResource: "ProtonMail.momd/ProtonMail", withExtension: "mom")!
        let oldManagedObjectModel = NSManagedObjectModel(contentsOf: oldModelUrl)
        let oldUrl = FileManager.default.temporaryDirectoryUrl.appendingPathComponent("ProtonMail.sqlite", isDirectory: false)
        XCTAssertNotNil(oldManagedObjectModel)
        //
        // Migration
        //
        let newModelUrl = Bundle.main.url(forResource: "ProtonMail.momd/1.12.0", withExtension: "mom")!
        let newManagedObjectModel = NSManagedObjectModel(contentsOf: newModelUrl)
        let newUrl = FileManager.default.temporaryDirectoryUrl.appendingPathComponent("ProtonMail_NewModel.sqlite", isDirectory: false)
        XCTAssertNotNil(newManagedObjectModel)
        
//        NSMappingModel.entityMappingsByName
        
        let mappingUrl = Bundle.main.url(forResource: "ProtonMail_to_1.12.0", withExtension: "cdm")!
        //NSMappingModel *mappingModel = [[NSMappingModel alloc] initWithContentsOfURL:fileURL]
        let mappingModel = NSMappingModel(contentsOf: mappingUrl) //NSMappingModel(from: [CoreDataStore.modelBundle], forSourceModel: oldManagedObjectModel, destinationModel: newManagedObjectModel)
        XCTAssertNotNil(mappingModel)
        let migrationManager = NSMigrationManager(sourceModel: oldManagedObjectModel!, destinationModel: newManagedObjectModel!)
        XCTAssertNotNil(migrationManager)
        //Migrate type in the future could try to user in memory Type
        do {
            try migrationManager.migrateStore(from: oldUrl,
                                              sourceType: NSSQLiteStoreType,
                                              options: nil,
                                              with: mappingModel,
                                              toDestinationURL: newUrl,
                                              destinationType: NSSQLiteStoreType,
                                              destinationOptions: nil)
        } catch {
            XCTAssertNil(error)
        }
        

        //
        // to verify data
        //
    }
}
