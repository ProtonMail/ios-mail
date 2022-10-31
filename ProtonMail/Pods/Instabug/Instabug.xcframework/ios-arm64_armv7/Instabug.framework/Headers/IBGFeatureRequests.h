/*
 File:       Instabug/IBGFeatureRequests.h
 
 Contains:   API for using Instabug's SDK.
 
 Copyright:  (c) 2013-2020 by Instabug, Inc., all rights reserved.

 Version:    11.3.0
 */


#import <Foundation/Foundation.h>
#import "IBGTypes.h"

NS_SWIFT_NAME(FeatureRequests)
@interface IBGFeatureRequests : NSObject

/**
 @brief Acts as a master switch for the Feature Requests.
 
 @discussion It's enabled by default. When disabled, all the functionalities related to the Feature Requests is disabled.
 */
@property (class, atomic, assign) BOOL enabled;

/**
 @brief Sets whether users are required to enter an email address or not when doing a certain action `IBGAction`.
 
 @discussion Defaults to YES.
 
 @param isEmailFieldRequired A boolean to indicate whether email field is required or not.
 @param actionType An enum that indicates which action types will have the isEmailFieldRequired.
 */
+ (void)setEmailFieldRequired:(BOOL)isEmailFieldRequired forAction:(IBGAction)actionType;

/**
 @brief Shows the UI for feature requests list
 */
+ (void)show;

@end
