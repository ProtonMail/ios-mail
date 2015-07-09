//
//  Answers.h
//  Crashlytics
//
//  Copyright (c) 2015 Crashlytics, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Fabric/FABAttributes.h>

FAB_START_NONNULL

@interface Answers : NSObject

/**
 *  Log an Answers Signup Event to track how users are signing up for your application.
 *
 *  @param signUpMethodOrNil     The method by which a user logged in, e.g. Twitter or Digits.
 *  @param signUpSucceededOrNil  The ultimate success or failure of the login
 *  @param customAttributesOrNil A dictionary of custom attributes to associate with this purchase.
 */
+ (void)logSignUpWithMethod:(NSString * FAB_NULLABLE)signUpMethodOrNil
                    success:(NSNumber * FAB_NULLABLE)signUpSucceededOrNil
           customAttributes:(NSDictionary * FAB_NULLABLE)customAttributesOrNil;

/**
 *  Log an Answers Login Event to track how users are logging in to your application.
 *
 *  @param loginMethodOrNil      The method by which a user logged in, e.g. email, Twitter or Digits.
 *  @param loginSucceededOrNil   The ultimate success or failure of the login
 *  @param customAttributesOrNil A dictionary of custom attributes to associate with this purchase.
 */
+ (void)logLoginWithMethod:(NSString * FAB_NULLABLE)loginMethodOrNil
                   success:(NSNumber * FAB_NULLABLE)loginSucceededOrNil
          customAttributes:(NSDictionary * FAB_NULLABLE)customAttributesOrNil;

/**
 *  Log an Answers Share Event to track what and how users are sharing content from your application.
 *
 *  @param shareMethodOrNil      The method by which a user shared, e.g. email, Twitter, SMS.
 *  @param contentNameOrNil      The human readable name for this piece of content.
 *  @param contentTypeOrNil      The type of content shared.
 *  @param contentIdOrNil        The unique identifier for this piece of content. Useful for finding the top shared item.
 *  @param customAttributesOrNil A dictionary of custom attributes to associate with this event.
 */
+ (void)logShareWithMethod:(NSString * FAB_NULLABLE)shareMethodOrNil
               contentName:(NSString * FAB_NULLABLE)contentNameOrNil
               contentType:(NSString * FAB_NULLABLE)contentTypeOrNil
                 contentId:(NSString * FAB_NULLABLE)contentIdOrNil
          customAttributes:(NSDictionary * FAB_NULLABLE)customAttributesOrNil;

/**
 *  Log an Answers Invite Event to track how users are inviting other users into
 *  your application.
 *
 *  @param inviteMethodOrNil     The method of invitation, e.g. GameCenter, Twitter, email.
 *  @param customAttributesOrNil A dictionary of custom attributes to associate with this purchase.
 */
+ (void)logInviteWithMethod:(NSString * FAB_NULLABLE)inviteMethodOrNil
           customAttributes:(NSDictionary * FAB_NULLABLE)customAttributesOrNil;

/**
 *  Log an Answers Purchase Event to track when, how and what users are purchasing in your app.
 *
 *  @param itemPriceOrNil         The purchased item's price.
 *  @param currencyOrNil          The ISO4217 currency code. Example: USD
 *  @param purchaseSucceededOrNil Was the purchase succesful or unsuccesful
 *  @param itemNameOrNil          The human-readable form of the item's name. Example:
 *  @param itemIdOrNil            The machine-readable, unique item identifier Example: SKU.
 *  @param itemTypeOrNil          The type, or genre of the item. Example: Song
 *  @param customAttributesOrNil  A dictionary of custom attributes to associate with this purchase.
 */
+ (void)logPurchaseWithPrice:(NSDecimalNumber * FAB_NULLABLE)itemPriceOrNil
                    currency:(NSString * FAB_NULLABLE)currencyOrNil
                     success:(NSNumber * FAB_NULLABLE)purchaseSucceededOrNil
                    itemName:(NSString * FAB_NULLABLE)itemNameOrNil
                    itemType:(NSString * FAB_NULLABLE)itemTypeOrNil
                      itemId:(NSString * FAB_NULLABLE)itemIdOrNil
            customAttributes:(NSDictionary * FAB_NULLABLE)customAttributesOrNil;

/**
 *  Log a Custom Answers Event to track metrics and actions which are unique to your app.
 *
 *  @param eventName             The human-readable name for the event.
 *  @param customAttributesOrNil A dictionary of custom attributes to associate with this purchase. Attribute keys
 *                               must be <code>NSString</code> and and values must be <code>NSNumber</code> or <code>NSString</code>.
 *  @discussion                  How we treat <code>NSNumbers</code>:
 *                               We will provide information about the distribution of values over time.
 *
 *                               How we treat <code>NSStrings</code>:
 *                               NSStrings are used as categorical data, allowing comparison across different category values.
 *                               Strings are limited to a maximum length of 100 characters, attributes over this length will be
 *                               truncated.
 *
 *                               When tracking the Tweet views to better understand user engagement, sending the tweet's length
 *                               and the type of media present in the tweet allows you to track how tweet length and the type of media influence
 *                               engagement.
 */
+ (void)logCustomEventWithName:(NSString *)eventName
              customAttributes:(NSDictionary * FAB_NULLABLE)customAttributesOrNil;

@end

FAB_END_NONNULL
