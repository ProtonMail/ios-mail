/*
 File:       Instabug/IBGSurveys.h
 
 Contains:   API for using Instabug's SDK.
 
 Copyright:  (c) 2013-2020 by Instabug, Inc., all rights reserved.

 Version:    11.3.0
 */

#import <Foundation/Foundation.h>
#import "IBGSurvey.h"
#import "IBGSurveyFinishedState.h"

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(Surveys)
@interface IBGSurveys : NSObject

@property (class, atomic, assign) BOOL enabled;

/**
 @returns `YES` if Surveys have exceeded the usage limit on your plan. Otherwise, returns `NO`.
 
 @discussion If you have exceeded the usage limit on your plan, no Surveys will appear to the end users.
 */
@property (class, atomic, readonly) BOOL usageExceeded;

/**
 @brief Sets whether auto surveys showing are enabled or not.
 
 @discussion If you disable surveys auto showing on the SDK but still have active surveys on your Instabug dashboard, those surveys are still going to be sent to the device, but are not going to be shown automatically.
 
 To manually display any available surveys, call `+ [Instabug showSurveyIfAvailable]`.
 
 Defaults to YES.
 */
@property (class, atomic, assign) BOOL autoShowingEnabled;

/**
 @brief Returns array of available surveys that match the current device/user asynchronous.
 */
+ (void)availableSurveysWithCompletionHandler:(void (^)(NSArray<IBGSurvey *> * validSurveys))completionHandler;

/**
 @brief Sets a block of code to be executed just before the survey's UI is presented.
 
 @discussion This block is executed on the UI thread. Could be used for performing any UI changes before the survey's UI
 is shown.
 */
@property (class, atomic, strong) void(^willShowSurveyHandler)(void);

/**
 @brief Sets a block of code to be executed right after the survey's UI is dismissed.
 
 @discussion This block is executed on the UI thread. Could be used for performing any UI changes after the survey's UI
 is dismissed.
 */
@property (class, atomic, strong) void(^didDismissSurveyHandler)(void);

/**
 *  @brief Sets a block of code to be executed when the survey finishes.
 *
 *  @discussion This block is executed when the survey is dismissed at the start or midway, or when the survey is submitted. The block is passed the following:
 *
 *      * `IBGSurveyFinishedState state` - An enum describing the state of the survey on finishing, whether it was dismissed at start
 *      or midway or completed.
 *
 *      * `NSDictionary *info` - A dictionary carrying info about the survey and the questions' responses
 *
 *      * `NSString *identifier` - A string with the survey's identifier
 */
@property (class, atomic, strong, nullable) void(^didFinishSurveyHandler)(IBGSurveyFinishedState state, NSDictionary *info, NSString *identifier);

/**
 @brief Setting an option for all the surveys to show a welcome screen before the user starts taking the survey.
 
 @discussion By enabling this option, any survey that appears to the user will have a welcome screen with a title, subtitle
 and a button that if clicked, will take the user to the survey. All the strings in the welcome screen have a default value
 and localized. They can also be modified using the strings API. The default value of this option is false.
 */
@property (class, atomic, assign) BOOL shouldShowWelcomeScreen;

/**
 @brief Shows one of the surveys that were not shown before, that also have conditions that match the current device/user.
 
 @discussion Does nothing if there are no available surveys.
 */
+ (void)showSurveyIfAvailable;

/**
 @brief Shows Survey with a specific token.
 
 @discussion Does nothing if there are no available surveys with that specific token. Answered and canceled surveys won't show up again.
 
 @param surveyToken A String with a survey token.
 */
+ (void)showSurveyWithToken:(NSString *)surveyToken;

/**
 @brief Returns true in the completion handler if the survey with a specific token was answered before .
 
 @discussion Will return false if the token does not exist or if the survey was not answered before.
 
 @param surveyToken A String with a survey token.
 @param completionHandler A CompletionHandler for the result..
 */
+ (void)hasRespondedToSurveyWithToken:(NSString *)surveyToken
                    completionHandler:(void(^)(BOOL hasResponded))completionHandler;


/**
 @brief Sets url for the published iOS app on AppStore.
 
 @discussion You can redirect NPS Surveys or AppRating Surveys to AppStore to let users rate your app on AppStore itself.
 
 */
@property (class, atomic, strong) NSString *appStoreURL;

@end

NS_ASSUME_NONNULL_END
