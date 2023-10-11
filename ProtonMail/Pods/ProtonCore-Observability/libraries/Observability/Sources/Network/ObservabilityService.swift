//
//  ObservabilityService.swift
//  ProtonCore-Observability - Created on 26.01.23.
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
import ProtonCoreFeatureSwitch
import ProtonCoreNetworking
import ProtonCoreUtilities

public protocol ObservabilityService {
    /// Reports events to Back-End
    /// - Parameters:
    ///   - metrics: An array of events to report.
    func report<Labels: Encodable & Equatable>(_ event: ObservabilityEvent<PayloadWithLabels<Labels>>)
}

public class ObservabilityServiceImpl: ObservabilityService {
    
    private let requestPerformer: ProtonCoreNetworking.RequestPerforming?
    
    private let timer: ObservabilityTimer
    private let aggregator: ObservabilityAggregator
    private let reportingQueue: CompletionBlockExecutor
    private let completion: ((URLSessionDataTask?, Result<JSONDictionary, NSError>) -> Void)?
    
    private let encoder = JSONEncoder()
    private let endpoint = ObservabilityEndpoint()
    
    private var isTimerRunning: Atomic<Bool> = .init(false)
    
    public convenience init(requestPerformer: RequestPerforming) {
        self.init(
            requestPerformer: requestPerformer,
            timer: ObservabilityTimerImpl(),
            aggregator: ObservabilityAggregatorImpl(),
            reportingQueue: .asyncExecutor(dispatchQueue: .global())
        )
    }
    
    init(requestPerformer: RequestPerforming,
         timer: ObservabilityTimer = ObservabilityTimerImpl(),
         aggregator: ObservabilityAggregator = ObservabilityAggregatorImpl(),
         reportingQueue: CompletionBlockExecutor = .asyncExecutor(dispatchQueue: .global()),
         completion: ((URLSessionDataTask?, Result<JSONDictionary, NSError>) -> Void)? = nil) {
        self.requestPerformer = requestPerformer
        self.timer = timer
        self.aggregator = aggregator
        self.reportingQueue = reportingQueue
        self.completion = completion
    }

    private func startTimer() {
        timer.register { [weak self] in
            guard let self = self else { return }
            self.sendMetrics(completion: self.completion)
        }
        timer.start()
    }
    
    public func report<Labels: Encodable & Equatable>(_ event: ObservabilityEvent<PayloadWithLabels<Labels>>) {
        isTimerRunning.mutate { value in
            guard value else {
                value = true
                startTimer()
                return
            }
        }
        
        aggregator.aggregate(event: event)
    }
    
    private func sendMetrics(completion: ((URLSessionDataTask?, Result<JSONDictionary, NSError>) -> Void)?) {
        
        if aggregator.aggregatedEvents.value.isEmpty { return }
        
        reportingQueue.execute { [weak self] in
            guard let self else { return }
            let eventToReport = self.aggregator.aggregatedEvents.value
            self.aggregator.clear()
            let metrics = Metrics(metrics: eventToReport)
            
            do {
                let metricsData = try self.encoder.encode(metrics)
                let parameters = try JSONSerialization.jsonObject(with: metricsData, options: [])
            
                self.requestPerformer?.performRequest(request: self.endpoint,
                                                      parameters: parameters,
                                                      headers: self.endpoint.headers,
                                                      jsonCompletion: completion)
            } catch {
                completion?(nil, .failure(.init(domain: "", code: 0, localizedDescription: error.localizedDescription)))
            }
        }
    }
}
