/*
 File:       InstabugCore/IBGTypes.h
 
 Contains:   Enums and Constants for using Instabug's SDK.
 
 Copyright:  (c) 2013-2018 by Instabug, Inc., all rights reserved.
 
 Version:    11.3.0
 */

#import <UIKit/UIKit.h>

/// ------------------------------
/// @name User-facing Strings Keys
/// ------------------------------

// Predefined keys to be used to override any of the user-facing strings in the SDK. See + [Instabug setValue:forStringWithKey]

extern NSString * const kIBGStartAlertTextStringName;
extern NSString * const kIBGShakeStartAlertTextStringName;
extern NSString * const kIBGTwoFingerSwipeStartAlertTextStringName;
extern NSString * const kIBGEdgeSwipeStartAlertTextStringName;
extern NSString * const kIBGScreenshotStartAlertTextStringName;
extern NSString * const kIBGFloatingButtonStartAlertTextStringName;
extern NSString * const kIBGBetaWelcomeMessageWelcomeStepTitle;
extern NSString * const kIBGBetaWelcomeMessageWelcomeStepContent;
extern NSString * const kIBGBetaWelcomeMessageHowToReportStepTitle;
extern NSString * const kIBGBetaWelcomeMessageHowToReportStepContent;
extern NSString * const kIBGBetaWelcomeMessageFinishStepTitle;
extern NSString * const kIBGBetaWelcomeMessageFinishStepContent;
extern NSString * const kIBGBetaWelcomeDoneButtonTitle;
extern NSString * const kIBGLiveWelcomeMessageTitle;
extern NSString * const kIBGLiveWelcomeMessageContent;
extern NSString * const kIBGInvalidEmailMessageStringName;
extern NSString * const kIBGInvalidEmailTitleStringName;
extern NSString * const kIBGInvalidCommentMessageStringName;
extern NSString * const kIBGInvalidCommentTitleStringName;
extern NSString * const kIBGInvalidNumberTitleStringName;
extern NSString * const kIBGReportCategoriesAccessibilityScrollStringName;
extern NSString * const kIBGAnnotationCloseButtonStringName;
extern NSString * const kIBGAnnotationSaveButtonStringName;
extern NSString * const kIBGAnnotationDrawnShapeStringName;
extern NSString * const kIBGAttachmentActionSheetStopScreenRecording;
extern NSString * const kIBGAttachmentActionSheetUnmuteMic;
extern NSString * const kIBGAttachmentActionSheetMuteMic;
extern NSString * const kIBGScreenRecordingDuration;
extern NSString * const kIBGInvalidNumberMessageStringName;
extern NSString * const kIBGCloseConversationsStringLabel;
extern NSString * const kIBGBackToConversationsStringLabel;
extern NSString * const kIBGSendMessageStringLabel;
extern NSString * const kIBGDismissMessageStringLabel;
extern NSString * const kIBGReplyToMessageStringLabel;
extern NSString * const kIBGInvocationTitleStringName;
extern NSString * const kIBGInvocationTitleHintStringName;
extern NSString * const kIBGChatsListHintStringName;
extern NSString * const kIBGOneChatsListHintStringName;
extern NSString * const kIBGOneChatsListHintStringName;
extern NSString * const kIBGCancelPromptHintStringName;
extern NSString * const kIBGReportCategoriesBackButtonStringName;
extern NSString * const kIBGReportCategoriesBackButtonHintStringName;
extern NSString * const kIBGFeatureRequetsPromptName;
extern NSString * const kIBGAskAQuestionStringName;
extern NSString * const kIBGReportBugStringName;
extern NSString * const kIBGReportFeedbackStringName;
extern NSString * const kIBGReportBugDescriptionStringName;
extern NSString * const kIBGReportFeedbackDescriptionStringName;
extern NSString * const kIBGReportQuestionDescriptionStringName;
extern NSString * const kIBGRequestFeatureDescriptionStringName;
extern NSString * const kIBGAccessibilityReportFeedbackDescriptionStringName;
extern NSString * const kIBGAccessibilityReportBugDescriptionStringName;
extern NSString * const kIBGAccessibilityRequestFeatureDescriptionStringName;
extern NSString * const kIBGPhotoPickerTitle;
extern NSString * const kIBGProgressViewTitle;
extern NSString * const kIBGGalleryPermissionDeniedAlertTitle;
extern NSString * const kIBGGalleryPermissionDeniedAlertMessage;
extern NSString * const kIBGMaximumSizeExceededAlertTitle;
extern NSString * const kIBGMaximumSizeExceededAlertMessage;
extern NSString * const kIBGiCloudImportErrorAlertTitle;
extern NSString * const kIBGiCloudImportErrorAlertMessage;
extern NSString * const kIBGEmailFieldPlaceholderStringName;
extern NSString * const kIBGEmailFieldAccessibilityStringLabel;
extern NSString * const kIBGEmailFieldAccessibilityStringHint;
extern NSString * const kIBGNumberFieldPlaceholderStringName;
extern NSString * const kIBGNumberInfoAlertMessageStringName;
extern NSString * const kIBGCommentFieldPlaceholderForBugReportStringName;
extern NSString * const kIBGCommentFieldPlaceholderForFeedbackStringName;
extern NSString * const kIBGCommentFieldPlaceholderForQuestionStringName;
extern NSString * const kIBGCommentFieldAccessibilityStringLabel;
extern NSString * const kIBGCommentFieldBugAccessibilityStringHint;
extern NSString * const kIBGCommentFieldImprovementAccessibilityStringHint;
extern NSString * const kIBGCommentFieldAskQuestionAccessibilityStringHint;
extern NSString * const kIBGChatReplyFieldPlaceholderStringName;
extern NSString * const kIBGAddScreenRecordingMessageStringName;
extern NSString * const kIBGAddVoiceMessageStringName;
extern NSString * const kIBGAddImageFromGalleryStringName;
extern NSString * const kIBGExtraFieldsStringLabel;
extern NSString * const kIBGAccessibilityExtraFieldsStepsLabel;
extern NSString * const kIBGAccessibilityExtraFieldsStepsRequiredLabel;
extern NSString * const kIBGRequiredExtraFieldsStringLabel;
extern NSString * const kIBGAddExtraScreenshotStringName;
extern NSString * const kIBGAccessibilityReproStepsDisclaimerStringLabel;
extern NSString * const kIBGAccessibilityImageAttachmentStringHint;
extern NSString * const kIBGAccessibilityVideoAttachmentStringHint;
extern NSString * const kIBGTakeScreenshotAccessibilityStringLabel;
extern NSString * const kIBGTakeScreenRecordingAccessibilityStringLabel;
extern NSString * const kIBGSelectImageFromGalleryLabel;
extern NSString * const kIBGAddAttachmentAccessibilityStringLabel;
extern NSString * const kIBGAddAttachmentAccessibilityStringHint;
extern NSString * const kIBGExpandAttachmentAccessibilityStringLabel;
extern NSString * const kIBGCollapseAttachmentAccessibilityStringLabel;
extern NSString * const kIBGAudioRecordingPermissionDeniedTitleStringName;
extern NSString * const kIBGAudioRecordingPermissionDeniedMessageStringName;
extern NSString * const kIBGScreenRecordingPermissionDeniedMessageStringName;
extern NSString * const kIBGMicrophonePermissionAlertSettingsButtonTitleStringName;
extern NSString * const kIBGMicrophonePermissionAlertLaterButtonTitleStringName;
extern NSString * const kIBGChatsTitleStringName;
extern NSString * const kIBGTeamStringName;
extern NSString * const kIBGRecordingMessageToHoldTextStringName;
extern NSString * const kIBGRecordingMessageToReleaseTextStringName;
extern NSString * const kIBGMessagesNotificationTitleSingleMessageStringName;
extern NSString * const kIBGMessagesNotificationTitleMultipleMessagesStringName;
extern NSString * const kIBGScreenshotTitleStringName;
extern NSString * const kIBGOkButtonTitleStringName;
extern NSString * const kIBGSendButtonTitleStringName;
extern NSString * const kIBGCancelButtonTitleStringName;
extern NSString * const kIBGThankYouAlertTitleStringName;
extern NSString * const kIBGThankYouAccessibilityConfirmationTitleStringName;
extern NSString * const kIBGThankYouAlertMessageStringName;
extern NSString * const kIBGAudioStringName;
extern NSString * const kIBGScreenRecordingStringName;
extern NSString * const kIBGImageStringName;
extern NSString * const kIBGReachedMaximimNumberOfAttachmentsTitleStringName;
extern NSString * const kIBGReachedMaximimNumberOfAttachmentsMessageStringName;
extern NSString * const kIBGVideoRecordingFailureMessageStringName;
extern NSString * const kIBGSurveyEnterYourAnswerTextPlaceholder;
extern NSString * const kIBGSurveyNoAnswerTitle;
extern NSString * const kIBGSurveyNoAnswerMessage;
extern NSString * const kIBGVideoPressRecordTitle;
extern NSString * const kIBGCollectingDataText;
extern NSString * const kIBGLowDiskStorageTitle;
extern NSString * const kIBGLowDiskStorageMessage;
extern NSString * const kIBGInboundByLineMessage;
extern NSString * const kIBGExtraFieldIsRequiredText;
extern NSString * const kIBGExtraFieldMissingDataText;
extern NSString * const kIBGFeatureRequestsTitle;
extern NSString * const kIBGFeatureDetailsTitle;
extern NSString * const kIBGStringFeatureRequestsRefreshText;
extern NSString * const kIBGFeatureRequestErrorStateTitleLabel;
extern NSString * const kIBGFeatureRequestErrorStateDescriptionLabel;
extern NSString * const kIBGFeatureRequestSortingByRecentlyUpdatedText;
extern NSString * const kIBGFeatureRequestSortingByTopVotesText;
extern NSString * const kIBGStringFeatureRequestAllFeaturesText;
extern NSString * const kIBGAddNewFeatureRequestText;
extern NSString * const kIBGAddNewFeatureRequestToastText;
extern NSString * const kIBGAddNewFeatureRequestErrorToastText;
extern NSString * const kIBGAddNewFeatureRequestLoadingHUDTitle;
extern NSString * const kIBGAddNewFeatureRequestSuccessHUDTitle;
extern NSString * const kIBGAddNewFeatureRequestSuccessHUDMessage;
extern NSString * const kIBGAddNewFeatureRequestTryAgainText;
extern NSString * const kIBGAddNewFeatureRequestCancelPromptTitle;
extern NSString * const kIBGAddNewFeatureRequestCancelPromptYesAction;
extern NSString * const kIBGFeatureRequestInvalidEmailText;
extern NSString * const kIBGFeatureRequestTimelineEmptyText;
extern NSString * const kIBGFeatureRequestTimelineErrorDescriptionLabel;
extern NSString * const kIBGFeatureRequestStatusChangeText;
extern NSString * const kIBGFeatureRequestAddButtonText;
extern NSString * const kIBGFeatureRequestVoteWithCountText;
extern NSString * const kIBGFeatureRequestVoteText;
extern NSString * const kIBGFeatureRequestPostButtonText;
extern NSString * const kIBGFeatureRequestCommentsText;
extern NSString * const kIBGFeatureRequestAuthorText;
extern NSString * const kIBGFeatureRequestEmptyViewTitle;
extern NSString * const kIBGFeatureRequestAddYourIdeaText;
extern NSString * const kIBGFeatureRequestAnonymousText;
extern NSString * const kIBGFeatureRequestStatusPosted;
extern NSString * const kIBGFeatureRequestStatusPlanned;
extern NSString * const kIBGFeatureRequestStatusStarted;
extern NSString * const kIBGFeatureRequestStatusCompleted;
extern NSString * const kIBGFeatureRequestStatusMaybeLater;
extern NSString * const kIBGFeatureRequestStatusMoreText;
extern NSString * const kIBGFeatureRequestStatusLessText;
extern NSString * const kIBGFeatureRequestAddYourThoughtsText;
extern NSString * const kIBGEmailRequiredText;
extern NSString * const kIBGNameText;
extern NSString * const kIBGEmailText;
extern NSString * const kIBGTitleText;
extern NSString * const kIBGDescriptionText;
extern NSString * const kIBGStringFeatureRequestMyFeaturesText;
extern NSString * const kIBGSurveyIntroTitleText;
extern NSString * const kIBGSurveyIntroDescriptionText;
extern NSString * const kIBGSurveyIntroTakeSurveyButtonText;
extern NSString * const kIBGDismissButtonTitleStringName;
extern NSString * const kIBGStoreRatingThankYouTitleText;
extern NSString * const kIBGStoreRatingThankYouDescriptionText;
extern NSString * const kIBGSurveysNPSLeastLikelyStringName;
extern NSString * const kIBGSurveysNPSMostLikelyStringName;
extern NSString * const kIBGSurveyNextButtonTitle;
extern NSString * const kIBGSurveySubmitButtonTitle;
extern NSString * const kIBGSurveyAppStoreThankYouTitle;
extern NSString * const kIBGSurveyAppStoreButtonTitle;
extern NSString * const kIBGExpectedResultsStringName;
extern NSString * const kIBGActualResultsStringName;
extern NSString * const kIBGStepsToReproduceStringName;
extern NSString * const kIBGReplyButtonTitleStringName;
extern NSString * const kIBGAddAttachmentButtonTitleStringName;
extern NSString * const kIBGDiscardAlertTitle;
extern NSString * const kIBGDiscardAlertMessage;
extern NSString * const kIBGDiscardAlertAction;
extern NSString * const kIBGDiscardAlertCancel;
extern NSString * const kIBGVideoGalleryErrorMessageStringName;
extern NSString * const kIBGVideoDurationErrorTitle;
extern NSString * const kIBGVideoDurationErrorMessage;
extern NSString * const kIBGAutoScreenRecordingAlertAllowText;
extern NSString * const kIBGAutoScreenRecordingAlertAlwaysAllowText;
extern NSString * const kIBGAutoScreenRecordingAlertDenyText;
extern NSString * const kIBGAutoScreenRecordingAlertTitleText;
extern NSString * const kIBGAutoScreenRecordingAlertBodyText;
extern NSString * const kIBGReproStepsDisclaimerBody;
extern NSString * const kIBGReproStepsDisclaimerLink;
extern NSString * const kIBGReproStepsListHeader;
extern NSString * const kIBGReproStepsListEmptyStateLabel;
extern NSString * const kIBGReproStepsListTitle;
extern NSString * const kIBGReproStepsListItemName;

/// -----------
/// @name Enums
/// -----------

/**
 The event used to invoke the feedback form.
 */
typedef NS_OPTIONS(NSInteger, IBGInvocationEvent) {
    /** Shaking the device while in any screen to show the feedback form. */
    IBGInvocationEventShake = 1 << 0,
    /** Taking a screenshot using the Home+Lock buttons while in any screen to show the feedback form. */
    IBGInvocationEventScreenshot = 1 << 1,
    /** Swiping two fingers left while in any screen to show the feedback form. */
    IBGInvocationEventTwoFingersSwipeLeft = 1 << 2,
    /** Swiping one finger left from the right edge of the screen to show the feedback form, substituted with IBGInvocationEventTwoFingersSwipeLeft on iOS 6.1.3 and earlier. */
    IBGInvocationEventRightEdgePan = 1 << 3,
    /**  Shows a floating button on top of all views, when pressed it takes a screenshot. */
    IBGInvocationEventFloatingButton = 1 << 4,
    /** No event will be registered to show the feedback form, you'll need to code your own and call the method showFeedbackForm. */
    IBGInvocationEventNone = 1 << 5,
};

/**
 The color theme of the different UI elements.
 */
typedef NS_ENUM(NSInteger, IBGColorTheme) {
    IBGColorThemeLight,
    IBGColorThemeDark
};

/**
 The mode used upon invocating the SDK.
 */
typedef NS_ENUM(NSInteger, IBGInvocationMode) {
    IBGInvocationModeNA,
    IBGInvocationModeNewBug,
    IBGInvocationModeNewFeedback,
    IBGInvocationModeNewQuestion,
    IBGInvocationModeNewChat,
    IBGInvocationModeChatsList,
    IBGInvocationModeNewQuestionManually        //Only when you call Chats.show()
};

/**
 Deprecated, should use IBGBugReportingOption instead.
 */
__attribute__((deprecated))
typedef NS_OPTIONS(NSInteger, IBGBugReportingInvocationOption) {
    IBGBugReportingInvocationOptionEmailFieldHidden = 1 << 0,
    IBGBugReportingInvocationOptionEmailFieldOptional = 1 << 1,
    IBGBugReportingInvocationOptionCommentFieldRequired = 1 << 2,
    IBGBugReportingInvocationOptionDisablePostSendingDialog = 1 << 3,
    IBGBugReportingInvocationOptionNone = 1 << 4,
};

/**
 Type of report to be submitted.
 */
typedef NS_OPTIONS(NSInteger, IBGBugReportingReportType) {
    IBGBugReportingReportTypeBug = 1 << 0,
    IBGBugReportingReportTypeFeedback = 1 << 1,
    IBGBugReportingReportTypeQuestion = 1 << 2,
};


typedef NS_OPTIONS(NSInteger, IBGBugReportingOption) {
    IBGBugReportingOptionEmailFieldHidden = 1 << 0,
    IBGBugReportingOptionEmailFieldOptional = 1 << 1,
    IBGBugReportingOptionCommentFieldRequired = 1 << 2,
    IBGBugReportingOptionDisablePostSendingDialog = 1 << 3,
    IBGBugReportingOptionNone = 1 << 4,
};

typedef NS_ENUM(NSInteger, IBGReportType) {
    IBGReportTypeBug,
    IBGReportTypeFeedback,
    IBGReportTypeQuestion
};

/**
 Type of SDK dismiss.
 */
typedef NS_ENUM(NSInteger, IBGDismissType) {
    /** Dismissed after report submit */
    IBGDismissTypeSubmit,
    /** Dismissed via cancel */
    IBGDismissTypeCancel,
    /** Dismissed while taking screenshot */
    IBGDismissTypeAddAttachment
};

/**
 Supported locales.
 */
typedef NS_ENUM(NSInteger, IBGLocale) {
    IBGLocaleArabic,
    IBGLocaleAzerbaijani,
    IBGLocaleChineseSimplified,
    IBGLocaleChineseTaiwan,
    IBGLocaleChineseTraditional,
    IBGLocaleCzech,
    IBGLocaleDanish,
    IBGLocaleDutch,
    IBGLocaleEnglish,
    IBGLocaleFrench,
    IBGLocaleGerman,
    IBGLocaleItalian,
    IBGLocaleJapanese,
    IBGLocaleKorean,
    IBGLocaleNorwegian,
    IBGLocalePolish,
    IBGLocalePortuguese,
    IBGLocalePortugueseBrazil,
    IBGLocaleRussian,
    IBGLocaleSlovak,
    IBGLocaleSpanish,
    IBGLocaleSwedish,
    IBGLocaleTurkish,
    IBGLocaleHungarian,
    IBGLocaleFinnish,
    IBGLocaleCatalan,
    IBGLocaleCatalanSpain,
    IBGLocaleCatalanRomanian
};

/**
 The prompt option selected in Instabug prompt.
 */
typedef NS_OPTIONS(NSInteger, IBGPromptOption) {
    IBGPromptOptionChat = 1 << 0,
    IBGPromptOptionBug = 1 << 1,
    IBGPromptOptionFeedback = 1 << 2,
    IBGPromptOptionNone = 1 << 3,
};

/**
 Instabug floating buttons positions.
 */
typedef NS_ENUM(NSInteger, IBGPosition) {
    IBGPositionBottomRight,
    IBGPositionTopRight,
    IBGPositionBottomLeft,
    IBGPositionTopLeft
};

/**
 The Conosle Log Level.
 */
typedef NS_ENUM(NSInteger, IBGLogLevel) {
    IBGLogLevelNone = 0,
    IBGLogLevelError,
    IBGLogLevelWarning,
    IBGLogLevelInfo,
    IBGLogLevelDebug,
    IBGLogLevelVerbose,
};

/**
 Verbosity level of the SDK debug logs. This has nothing to do with IBGLog, and only affect the logs used to debug the
 SDK itself.
 
 Defaults to IBGSDKDebugLogsLevelError. Make sure you only use IBGSDKDebugLogsLevelError or IBGSDKDebugLogsLevelNone in
 production builds.
 */
typedef NS_ENUM(NSInteger, IBGSDKDebugLogsLevel) {
    IBGSDKDebugLogsLevelVerbose = 1,
    IBGSDKDebugLogsLevelDebug = 2,
    IBGSDKDebugLogsLevelError = 3,
    IBGSDKDebugLogsLevelNone = 4
};

/**
 The user steps option.
 */
typedef NS_ENUM(NSInteger, IBGUserStepsMode) {
    IBGUserStepsModeEnable,
    IBGUserStepsModeEnabledWithNoScreenshots,
    IBGUserStepsModeDisable
};

 /**
    The attachment types selected in Attachment action sheet.
 */
typedef NS_OPTIONS(NSInteger, IBGAttachmentType) {
    IBGAttachmentTypeScreenShot = 1 << 1,
    IBGAttachmentTypeExtraScreenShot = 1 << 2,
    IBGAttachmentTypeGalleryImage = 1 << 4,
    IBGAttachmentTypeScreenRecording = 1 << 6,
};

/**
 The extended bug report mode.
 */
typedef NS_ENUM(NSInteger, IBGExtendedBugReportMode) {
    IBGExtendedBugReportModeEnabledWithRequiredFields,
    IBGExtendedBugReportModeEnabledWithOptionalFields,
    IBGExtendedBugReportModeDisabled
};

typedef NS_OPTIONS(NSInteger, IBGAction) {
    IBGActionAllActions = 1 << 0,
    IBGActionReportBug = 1 << 1,
    IBGActionRequestNewFeature = 1 << 2,
    IBGActionAddCommentToFeature = 1 << 3,
};

/**
 The welcome message mode.
 */
typedef NS_ENUM(NSInteger, IBGWelcomeMessageMode) {
    IBGWelcomeMessageModeLive,
    IBGWelcomeMessageModeBeta,
    IBGWelcomeMessageModeDisabled
};

/* CHECK NULLABILITY! */
typedef void (^NetworkObfuscationCompletionBlock)(NSData *data, NSURLResponse *response);

/* Platform */
typedef NS_ENUM(NSInteger, IBGPlatform) {
    IBGPlatformIOS,
    IBGPlatformReactNative,
    IBGPlatformCordova,
    IBGPlatformXamarin,
    IBGPlatformUnity,
    IBGPlatformFlutter
};

/**
User's touch event types
*/
typedef NS_ENUM(NSInteger, IBGUIEventType) {
    IBGUIEventTypeTap,
    IBGUIEventTypeForceTouch,
    IBGUIEventTypeLongPress,
    IBGUIEventTypePinch,
    IBGUIEventTypeSwipe,
    IBGUIEventTypeScroll
};
