//
//  NetworkDataFixture.h
//  Splunk-iOS
//
//  Created by G.Tas on 3/6/14.
//  Copyright (c) 2014 Splunk. All rights reserved.
//

#import "DataFixture.h"
#import "MintAppEnvironment.h"

@interface NetworkDataFixture : DataFixture

@property (nonatomic, strong) NSString* url;
@property (nonatomic, strong) NSString* protocol;
@property (nonatomic, strong) NSNumber<SPLIgnore>* endTime;
@property (nonatomic, strong) NSNumber<SPLIgnore>* duration;
@property (nonatomic, strong) NSNumber* statusCode;
@property (nonatomic, strong) NSNumber<SPLIgnore>* contentLength;
@property (nonatomic, strong) NSNumber* requestLength;
@property (nonatomic, assign) BOOL failed;
@property (nonatomic, strong) NSMutableDictionary<SPLIgnore>* reqHeaders;
@property (nonatomic, strong) NSMutableDictionary<SPLIgnore>* respHeaders;
@property (nonatomic, strong) NSString* exception;
@property (nonatomic, strong) NSNumber* responseLength;
@property (nonatomic, strong) NSNumber* latency;

- (void) appendWithStatusCode: (NSNumber*)statusCode;
- (void) appendStartTime;
- (void) appendEndTime;
- (void) appendRequestInfo:(NSURLRequest*)request;
- (void) appendResponseInfo:(NSURLResponse*)response;
- (void) appendResponseData:(NSData*)data;
- (void) appendResponseDataSize:(NSUInteger)dataSize;
- (void) appendWithError:(NSError*)error;
- (void) appendGlobalExtraData;
- (void) debugPrint;
- (void) saveToDisk;

@end
