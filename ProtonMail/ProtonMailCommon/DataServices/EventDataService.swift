//
//  EventDataService.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 11/28/17.
//  Copyright © 2017 ProtonMail. All rights reserved.
//

import Foundation

//TODO:: use this later
class EventDataService {
    typealias FetchEventComplete = APIService.CompletionBlock
    func fetchEvents(completion: FetchEventComplete?) {
        let eventAPI = EventCheckRequest<EventCheckResponse>(eventID: lastUpdatedStore.lastEventID)
        eventAPI.call() { task, _eventsRes, _hasEventsError in

        }
    }
    
    /**
     this function to process the event logs
     
     :param: messages   the message event log
     :param: task       NSURL session task
     :param: completion complete call back
     */
    fileprivate func processIncrementalUpdateMessages(_ notificationMessageID: String?, messages: [[String : Any]], task: URLSessionDataTask!, completion: CompletionBlock?) {
        struct IncrementalUpdateType {
            static let delete = 0
            static let insert = 1
            static let update1 = 2
            static let update2 = 3
        }
    }}
