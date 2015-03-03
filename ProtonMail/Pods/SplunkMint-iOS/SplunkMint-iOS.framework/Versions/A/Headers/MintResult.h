//
//  SplunkResult.h
//  Splunk-iOS
//
//  Created by G.Tas on 11/2/13.
//  Copyright (c) 2013 Splunk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MintEnums.h"
#import "MintMessageException.h"

/**
 *  The MintResult class contains information about the completion of a request.
 */
@interface MintResult : NSObject

/**
 *  The type of request.
 */
@property (nonatomic, assign) MintRequestType requestType;

/**
 *  A description with information about the request, such as a value when something has gone wrong or a notification.
 */
@property (nonatomic, strong) NSString* descriptionResult;

/**
 *  The result of the request.
 */
@property (nonatomic, assign) MintResultState resultState;

/**
 *  A NSException instance that provides you with information when a request fails.
 */
@property (nonatomic, strong) MintMessageException* exceptionError;

/**
 *  The JSON model that is sent to the server.
 */
@property (nonatomic, strong) NSString* clientRequest;

/**
 *   A Boolean that indicates whether the request was properly handled while debugging.
 */
@property (nonatomic, assign) BOOL handledWhileDebugging;

@end
