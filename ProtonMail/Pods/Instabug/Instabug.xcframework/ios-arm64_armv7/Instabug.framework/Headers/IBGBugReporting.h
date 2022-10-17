/*
 File:       Instabug/IBGBugReporting.h
 
 Contains:   API for using Instabug's SDK.
 
 Copyright:  (c) 2013-2020 by Instabug, Inc., all rights reserved.

 Version:    11.3.0
 */

#import <Foundation/Foundation.h>
#import "IBGTypes.h"

NS_SWIFT_NAME(BugReporting)
@interface IBGBugReporting : NSObject

/**
 @brief Acts as master switch for the Bug Reporting.
 
 @discussion It's enabled by default. When disabled, both "Report a bug" and "Suggest an improvement" will be removed from Instabug Prompt Options. In addition, when disabled +showWithReportType:options: won’t have an effect.
 */
@property (class, atomic, assign) BOOL enabled;

/**
 @returns `YES` if Bug Reporting has exceeded the usage limit on your plan. Otherwise, returns `NO`.
 
 @discussion If you have exceeded the usage limit on your plan, the Bug Reporting prompt will still appear to the end users normally. In that case, the bug won't be sent to the dashboard.
 */
@property (class, atomic, readonly) BOOL usageExceeded;

/**
 @brief Sets a block of code to be executed just before the SDK's UI is presented.
 
 @discussion This block is executed on the UI thread. Could be used for performing any UI changes before the SDK's UI
 is shown.
 */
@property(class, atomic, strong) void(^willInvokeHandler)(void);

/**
 @brief Sets a block of code to be executed right after the SDK's UI is dismissed.
 
 @discussion This block is executed on the UI thread. Could be used for performing any UI changes after the SDK's UI
 is dismissed.

 The block has the following parameters:
 
 - dismissType: How the SDK was dismissed.
 - reportType: Type of report that has been sent. Will be set to IBGReportTypeBug in case the SDK has been dismissed
 without selecting a report type, so you might need to check dismissType before reportType.
 
 @see IBGReportType, IBGDismissType
 */
@property(class, atomic, strong) void(^didDismissHandler)(IBGDismissType dismissType, IBGReportType reportType);

/**
 @brief Sets a block of code to be executed when a prompt option is selected
 
 @param didSelectPromptOptionHandler A block of code that gets executed when a prompt option is selected.
 
 The block has the following parameters:
 - prompOption: The option selected in prompt.
 */
@property(class, atomic, strong) void(^didSelectPromptOptionHandler)(IBGPromptOption promptOption);

/**
 @brief Sets the events that invoke the feedback form.
 
 @discussion Default is set by `startWithToken:invocationEvent:`.
 
 @see IBGInvocationEvent
 */
@property(class, atomic, assign) IBGInvocationEvent invocationEvents;

/**
 @brief Sets the threshold value of the shake gesture for iPhone/iPod Touch.

 @discussion Default for iPhone is 2.5. The lower the threshold, the easier it will be to invoke Instabug with the
 shake gesture. A threshold which is too low will cause Instabug to be invoked unintentionally.
 */
@property(class, atomic, assign) CGFloat shakingThresholdForiPhone;

/**
 @brief Sets the threshold value of the shake gesture for iPad.
 
 @discussion Default for iPad is 0.6. The lower the threshold, the easier it will be to invoke Instabug with the
 shake gesture. A threshold which is too low will cause Instabug to be invoked unintentionally.
 */
@property(class, atomic, assign) CGFloat shakingThresholdForiPad;

/**
 @brief Sets the default edge at which the floating button will be shown. Different orientations are already handled.
 
 @discussion Default for `floatingButtonEdge` is `CGRectMaxXEdge`.
 */
@property(class, atomic, assign) CGRectEdge floatingButtonEdge;

/**
 @brief Sets the default offset from the top at which the floating button will be shown.
 
 @discussion Default for `floatingButtonOffsetFromTop` is 50
 */
@property(class, atomic, assign) CGFloat floatingButtonTopOffset;

/**
 @brief Sets whether attachments in bug reporting and in-app messaging are enabled.
 */
@property(class, atomic, assign) IBGAttachmentType enabledAttachmentTypes;

/**
 @brief Controls if Instabug Prompt Options should contain "Report a problem” and/or "Suggest an improvement" or not.
 
 @discussion By default, both options are enabled.
 */
@property(class, atomic, assign) IBGBugReportingReportType promptOptionsEnabledReportTypes;

/**
 @brief Sets whether the extended bug report mode should be disabled, enabled with required fields or enabled with optional fields.
 
 @discussion This feature is disabled by default. When enabled, it adds more fields for your reporters to fill in. You can set whether the extra fields are required or optional.
 1. Expected Results.
 2. Actual Results.
 3. Steps to Reproduce.
 
 An enum to disable the extended bug report mode, enable it with required or with optional fields.
 */
@property(class, atomic, assign) IBGExtendedBugReportMode extendedBugReportMode;

/**
 @brief Use to specify different options that would affect how Instabug is shown and other aspects about the reporting experience.
 
 @discussion See IBGInvocationOptions.
 */
@property(class, atomic, assign) IBGBugReportingOption bugReportingOptions;

/**
 @brief Sets the default position at which the Instabug screen recording button will be shown. Different orientations are already handled.
 
 @discussion Default for `position` is `bottomRight`.
 */
@property(class, atomic, assign) IBGPosition videoRecordingFloatingButtonPosition;

/**
 @method +showWithReportType:options:
 @brief Shows the compose view of a bug report or a feedback.
 
 @see IBGBugReportingReportType
 @see IBGBugReportingOption
  */
+ (void)showWithReportType:(IBGBugReportingReportType)reportType
                   options:(IBGBugReportingOption)options;

/**
 @brief Dismisses any Instabug views that are currently being shown.
 */
+ (void)dismiss;

/**
 @brief Enables/disables inspect view hierarchy when reporting a bug/feedback.
 */
@property (class, atomic, assign) BOOL shouldCaptureViewHierarchy;

/**
 @brief Sets whether the SDK is recording the screen or not.
 
 @discussion Enabling auto screen recording would give you an insight on the scenario a user has performed before encountering a bug. screen recording is attached with each bug being sent.
 
 Auto screen recording is disabled by default.
 */
@property (class, atomic, assign) BOOL autoScreenRecordingEnabled;

/**
 @brief Sets maximum auto screen recording video duration.
 
 @discussion sets maximum auto screen recording video duration with max value 30 seconds and min value greater than 1 sec.
 */
@property (class, atomic, assign) CGFloat autoScreenRecordingDuration;

/**
 @brief Sets the disclaimer text in the bug report by parsing it and detecting any kind of link. Embedded links should be in Markdown in the form of @code @"[Link Name](http/https://www.example.com)" @endcode
 
 @discussion if `text` in empty or `nil` the disclaimer text view will be hidden. Max characters of the text without the link url is 100 characters and any extra characters will be truncated.
 We will accept links starts with `http` and `https` only.
 */
+ (void)setDisclaimerText:(NSString *)text;

/// @brief Sets the minimum accepted number of characters in the comment field in a report
/// @discussion Calling this method will make the comment field required for the specified report types. In case the report's comment is less than the limit set by this API, an alert will be shown to the user and the report will not be sent
/// @param reportTypes The report types to be affected by the limit
/// @param limit The minimum characters allowed for the comment field. Minimum accepted value is 2.
+ (void)setCommentMinimumCharacterCountForReportTypes:(IBGBugReportingReportType)reportTypes
                                            withLimit:(NSInteger)limit;

/*
 +------------------------------------------------------------------------+
 |                            Deprecated APIs                             |
 +------------------------------------------------------------------------+
 | The following section includes all deprecated APIs.                    |
 |                                                                        |
 | We've made a few changes to our APIs starting from version 8.0 to make |
 | them more intuitive and easily reachable.                              |
 |                                                                        |
 | While the APIs below still function, they will be completely removed   |
 | in a future release.                                                   |
 |                                                                        |
 | To adopt the new changes, please refer to our migration guide at:      |
 | https://docs.instabug.com/docs/ios-sdk-8-1-migration-guide             |
 +------------------------------------------------------------------------+
 */

@end
