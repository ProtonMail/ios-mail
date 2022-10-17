/*
 File:       Instabug/IBGReplies.h
 
 Contains:   API for using Instabug's SDK.
 
 Copyright:  (c) 2013-2020 by Instabug, Inc., all rights reserved.

 Version:    11.3.0
 */

#import <Foundation/Foundation.h>

NS_SWIFT_NAME(Replies)
@interface IBGReplies : NSObject

/**
 @brief Acts as a master switch for the In-app Replies.
 
 @discussion It's enabled by default. When disabled, the user can’t reach the chats history from the SDK. The chats list button is removed from Instabug Prompt Options. In addition, when disabled the in-app notification as well as the push notifications are disabled. And, +show won’t have an effect.
 */
@property (class, atomic, assign) BOOL enabled;

/**
 @brief Sets a block of code that gets executed when a new message is received.
 */
@property (class, atomic, strong) void (^didReceiveReplyHandler)(void);

/**
 @brief Enables/disables showing in-app notifications when the user receives a new message.
 */
@property (class, atomic, assign) BOOL inAppNotificationsEnabled;

/**
 @brief Enables/disables the use of push notifications in the SDK.
 
 @discussion In order to enable push notifications, implement
 `-[UIApplicationDelegate application:didRegisterForRemoteNotificationsWithDeviceToken:]` and either
 `-[UIApplicationDelegate application:didReceiveRemoteNotification]` or
 `-[UIApplicationDelegate application:didReceiveRemoteNotification:fetchCompletionHandler:]`.
 
 Defaults to YES.
  */
@property (class, atomic, assign) BOOL pushNotificationsEnabled;

/**
 @brief Returns the number of unread messages the user currently has.
 
 @discussion Use this method to get the number of unread messages the user has, then possibly notify them about it with
 your own UI.
 
 @return Notifications count, or -1 incase the SDK has not been initialized.
 */
@property (class, atomic, assign, readonly) NSInteger unreadRepliesCount;

/**
 @method +show
 @brief Shows the chats list.
 
 @discussion It shows the chats list only if the user has a chats history. Use +hasChats to know if a user has chats history or not. */
+ (void)show;

/**
 @method +hasChats
 @brief To know if a user already has a chats history or not.
 
 @discussion Use it before calling show.
 */
+ (BOOL)hasChats;

/**
 @brief Call this method and pass the notification's userInfo dictionary to allow Instabug to handle its remote notifications.
 
 @discussion Instabug will check if notification is from Instabug's servers and only handle it if it is.
 You should call this method in -[UIApplicationDelegate application:didReceiveRemoteNotification:] and pass received userInfo
 dictionary, or `-[UIApplicationDelegate application:didFinishLaunchingWithOptions:]` and pass
 `[launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey]`.
 
 @param userInfo userInfo dictionary from `-[UIApplicationDelegate application:didReceiveRemoteNotification:]` or
 `[launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey]` from
 `-[UIApplicationDelegate application:didFinishLaunchingWithOptions:]`.
 */
+ (BOOL)didReceiveRemoteNotification:(NSDictionary *)userInfo;

/**
 @brief Use this method to set Apple Push Notification token to enable receiving Instabug push notifications.
 
 @discussion You should call this method after receiving token in
 `-[UIApplicationDelegate didRegisterForRemoteNotificationsWithDeviceToken:]` and pass received token.
 
 @param deviceToken Device token received in `-[UIApplicationDelegate didRegisterForRemoteNotificationsWithDeviceToken:]`
 */
+ (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken;


@end
