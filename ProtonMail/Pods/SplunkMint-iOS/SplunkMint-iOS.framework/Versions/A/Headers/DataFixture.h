//
//  DataFixture.h
//  Splunk-iOS
//
//  Created by G.Tas on 11/6/13.
//  Copyright (c) 2013 Splunk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SPLJSONModel.h"
#import "ExtraData.h"

/**
 *  The base class model of all requests
 */
@interface DataFixture : SPLJSONModel

/**
 *  The SplunkMint API key
 */
@property (nonatomic, strong) NSString* apiKey;

/**
 *  The SplunkMint SDK version
 */
@property (nonatomic, strong) NSString* sdkVersion;

/**
 *  The SplunkMint SDK platform. Always iOS
 */
@property (nonatomic, strong) NSString* sdkPlatform;

/**
 *  The type of the request
 */
@property (nonatomic, strong) NSString<SPLIgnore>* type;

/**
 *  The name of the device
 */
@property (nonatomic, strong) NSString* device;

/**
 *  The iOS version
 */
@property (nonatomic, strong) NSString* osVersion;

/**
 *  The device locale
 */
@property (nonatomic, strong) NSString* locale;

/**
 *  The application SplunkMint UUID
 */
@property (nonatomic, strong) NSString* uuid;

/**
 *  The user identifier
 */
@property (nonatomic, strong) NSString<SPLOptional>* userIdentifier;

/**
 *  The UNIX timestamp of the request
 */
@property (nonatomic, strong) NSString<SPLIgnore>* timestamp;

/**
 *  The name of the carrier
 */
@property (nonatomic, strong) NSString* carrier;

/**
 *  A helper property always having a specific value for the server
 */
@property (nonatomic, strong) NSString* remoteIP;

/**
 *  The type of the connection when the request logged
 */
@property (nonatomic, strong) NSString<SPLOptional>* connection;

/**
 *  The state of the connection when the request logged
 */
@property (nonatomic, strong) NSString<SPLOptional>* state;

/**
 *  The application package name
 */
@property (nonatomic, strong) NSString* packageName;

/**
 *  The application full version
 */
@property (nonatomic, strong) NSString* appVersionName;

/**
 *  The application short version
 */
@property (nonatomic, strong) NSString* appVersionCode;

/**
 *  The binary name
 */
@property (nonatomic, strong) NSString<SPLIgnore>* binaryName;

/**
 *  The global extra data
 */
@property (nonatomic, strong) NSMutableDictionary<SPLOptional>* extraData;

/**
 *  The screen orientation
 */
@property (nonatomic, strong) NSString* screenOrientation;

/**
 * Transaction id list
 */
@property (nonatomic, strong) NSArray* transactions;

/**
 *App running state: Background or Foreground
 */
@property (nonatomic, strong) NSString *appRunningState;

/**
 *Battery level of current device
 */
@property (nonatomic, strong) NSString *batteryLevel;
/**
 *Current view that the user viewing
 */
@property (nonatomic, strong) NSString *currentView;

@end
