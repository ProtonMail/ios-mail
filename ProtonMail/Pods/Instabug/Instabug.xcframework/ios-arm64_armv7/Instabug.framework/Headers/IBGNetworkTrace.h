/*
 File:       Instabug/IBGNetworkTrace.h
 
 Contains:   API for using Instabug's SDK.
 
 Copyright:  (c) 2013-2021 by Instabug, Inc., all rights reserved.
 
 Version:    0.0.0
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(NetworkTrace)
@interface IBGNetworkTrace : NSObject

@property (nonatomic, strong) NSURLRequest* request;

/// Object will be nil if there isn't a response.
@property (nonatomic, strong, nullable) NSURLResponse* response;

/// Object will be nil if there isn't response data, or data size exceeded the maximum limit.
@property (nonatomic, strong, nullable) NSData* responseData;

@property (nonatomic, assign) NSUInteger responseDataSize;

@end

NS_ASSUME_NONNULL_END
