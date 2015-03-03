//
//  RHPerson.h
//  RHAddressBook
//
//  Created by Richard Heard on 14/11/11.
//  Copyright (c) 2011 Richard Heard. All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions
//  are met:
//  1. Redistributions of source code must retain the above copyright
//  notice, this list of conditions and the following disclaimer.
//  2. Redistributions in binary form must reproduce the above copyright
//  notice, this list of conditions and the following disclaimer in the
//  documentation and/or other materials provided with the distribution.
//  3. The name of the author may not be used to endorse or promote products
//  derived from this software without specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
//  IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
//  OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
//  IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
//  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
//  NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
//  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
//  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
//  THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

#import "RHRecord.h"

#import <UIKit/UIKit.h>
#import "RHMultiValue.h"
#import "RHPersonLabels.h"

@class RHPerson;
@class RHSource;

@class CLPlacemark;
@class CLLocation;

// To create a new empty instance of a person either use -[RHAddressBook newPersonInDefaultSource] or the below newPersonInSource: method
// If you have an existing  ABPersonRef that you want to wrap with an RHPerson object, use the personForABRecordRef: method on RHAddressBook or the below forwarding wrapper method.

@interface RHPerson : RHRecord

//once a person object is created using a given source object from an ab instance, its not safe to use that object with any other instance of the addressbook.
//you can always access the persons associated addressbook object using @property (readonly) RHAddressBook* addressBook; 
//the addressbook instance is guaranteed to stay alive until its last associated object is dealloc'd.
//these methods do not automatically add the new object to the source.addressBook, if you want it added you will need do add it yourself. -[RHAddressBook addPerson:];
+(id)newPersonInSource:(RHSource*)source;
-(id)initWithSource:(RHSource*)source;

//look up an RHPerson instance for an existing ABRecordRef in a particular addressbook; if the current recordRef does not belong to the given addressbook, the person objects underlying personRef will differ from the passed in value. This is required in-order to maintain thread safety for the underlying AddressBook instance.
+(RHPerson*)personForABRecordRef:(ABRecordRef)personRef inAddressBook:(RHAddressBook*)addressBook; //equivalent to -[RHAddressBook personForABRecordRef:];
+(RHPerson*)personForABRecordID:(ABRecordID)personID inAddressBook:(RHAddressBook*)addressBook; //equivalent to -[RHAddressBook personForABRecordID:];


//localised property and labels (class methods)
+(NSString*)localizedPropertyName:(ABPropertyID)propertyID; //properties eg:kABPersonFirstNameProperty (ABPersonCopyLocalizedPropertyName)
+(NSString*)localizedLabel:(NSString*)label; //labels eg: kABWorkLabel (ABAddressBookCopyLocalizedLabel)


//person is from given source
-(RHSource*)inSource;

//linked people (ie other cards that represent the same person in other sources)
-(NSArray*)linkedPeople;

//image

#if __IPHONE_OS_VERSION_MAX_ALLOWED < 40100
//iOS4.1 added ABPersonImageFormat, however later versions of the headers think it was added in 4.0
//running on 4.0 we will always return the full size image
typedef enum {
    kABPersonImageFormatThumbnail = 0,      // the square thumbnail
    kABPersonImageFormatOriginalSize = 2    // the original image as set by ABPersonSetImageData
} ABPersonImageFormat;
#endif


-(BOOL)hasImage;
-(UIImage*)thumbnail;
-(UIImage*)originalImage;
-(UIImage*)imageWithFormat:(ABPersonImageFormat)imageFormat;
-(NSData*)thumbnailData;
-(NSData*)originalImageData;
-(NSData*)imageDataWithFormat:(ABPersonImageFormat)imageFormat;
-(BOOL)setImage:(UIImage*)image;
-(BOOL)removeImage;

//personal properties
@property (nonatomic, copy, readonly) NSString *name;       // alias for compositeName
@property (nonatomic, copy) NSString *firstName;            // kABPersonFirstNameProperty
@property (nonatomic, copy) NSString *lastName;             // kABPersonLastNameProperty
@property (nonatomic, copy) NSString *middleName;           // kABPersonMiddleNameProperty
@property (nonatomic, copy) NSString *prefix;               // kABPersonPrefixProperty
@property (nonatomic, copy) NSString *suffix;               // kABPersonSuffixProperty
@property (nonatomic, copy) NSString *nickname;             // kABPersonNicknameProperty

@property (nonatomic, copy) NSString *firstNamePhonetic;    // kABPersonFirstNamePhoneticProperty
@property (nonatomic, copy) NSString *lastNamePhonetic;     // kABPersonLastNamePhoneticProperty
@property (nonatomic, copy) NSString *middleNamePhonetic;   // kABPersonMiddleNamePhoneticProperty

@property (nonatomic, copy) NSString *organization;         // kABPersonOrganizationProperty
@property (nonatomic, copy) NSString *jobTitle;             // kABPersonJobTitleProperty
@property (nonatomic, copy) NSString *department;           // kABPersonDepartmentProperty

@property (nonatomic, copy) RHMultiStringValue *emails;     // kABPersonEmailProperty - (Multi String)
@property (nonatomic, copy) NSDate *birthday;               // kABPersonBirthdayProperty
@property (nonatomic, copy) NSString *note;                 // kABPersonNoteProperty

@property (nonatomic, copy, readonly) NSDate *created;      // kABPersonCreationDateProperty
@property (nonatomic, copy, readonly) NSDate *modified;     // kABPersonModificationDateProperty

// (For more info on the keys and values for MultiValue objects check out <AddressBook/ABPerson.h> )
// (Also check out RHPersonLabels.h, it casts a bunch of CF labels into their toll free bridged counterparts for ease of use with this class )

//Addresses
@property (nonatomic, copy) RHMultiDictionaryValue *addresses;        // kABPersonAddressProperty - (Multi Dictionary) dictionary keys are ( kABPersonAddressStreetKey, kABPersonAddressCityKey, kABPersonAddressStateKey, kABPersonAddressZIPKey, kABPersonAddressCountryKey, kABPersonAddressCountryCodeKey )


//Dates
@property (nonatomic, copy) RHMultiDateTimeValue *dates;            // kABPersonDateProperty - (Multi Date) possible predefined labels ( kABPersonAnniversaryLabel )

//Kind
@property (nonatomic, copy) NSNumber *kind;                 // kABPersonKindProperty (Integer) possible values include (kABPersonKindPerson, kABPersonKindOrganization)
-(BOOL)isOrganization;                                      // if person == kABPersonKindOrganization
-(BOOL)isPerson;                                            // if person == kABPersonKindPerson

//Phone numbers
@property (nonatomic, copy) RHMultiStringValue *phoneNumbers;     // kABPersonPhoneProperty (Multi String) possible labels are ( kABPersonPhoneMobileLabel, kABPersonPhoneIPhoneLabel, kABPersonPhoneMainLabel, kABPersonPhoneHomeFAXLabel, kABPersonPhoneWorkFAXLabel, kABPersonPhoneOtherFAXLabel, kABPersonPhonePagerLabel )


//IM
@property (nonatomic, copy) RHMultiDictionaryValue *instantMessageServices;   // kABPersonInstantMessageProperty - (Multi Dictionary) dictionary keys are ( kABPersonInstantMessageServiceKey, kABPersonInstantMessageUsernameKey ) possible services are ( kABPersonInstantMessageServiceYahoo, kABPersonInstantMessageServiceJabber, kABPersonInstantMessageServiceMSN, kABPersonInstantMessageServiceICQ, kABPersonInstantMessageServiceAIM, kABPersonInstantMessageServiceQQ, kABPersonInstantMessageServiceGoogleTalk, kABPersonInstantMessageServiceSkype, kABPersonInstantMessageServiceFacebook, kABPersonInstantMessageServiceGaduGadu )


//URLs
@property (nonatomic, copy) RHMultiStringValue *urls;             // kABPersonURLProperty - (Multi String)  possible labels are ( kABPersonHomePageLabel )


//Related Names (Relationships)
@property (nonatomic, copy) RHMultiStringValue *relatedNames;     // kABPersonRelatedNamesProperty - (Multi String) possible labels are ( kABPersonFatherLabel, kABPersonMotherLabel, kABPersonParentLabel, kABPersonBrotherLabel, kABPersonSisterLabel, kABPersonChildLabel, kABPersonFriendLabel, kABPersonSpouseLabel, kABPersonPartnerLabel, kABPersonAssistantLabel, kABPersonManagerLabel )


#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 50000

//Social Profile (iOS5 +)
@property (nonatomic, copy) RHMultiDictionaryValue *socialProfiles;   // kABPersonSocialProfileProperty - (Multi Dictionary) possible dictionary keys are ( kABPersonSocialProfileURLKey, kABPersonSocialProfileServiceKey, kABPersonSocialProfileUsernameKey, kABPersonSocialProfileUserIdentifierKey )
                                                            // possible kABPersonSocialProfileServiceKey values ( kABPersonSocialProfileServiceTwitter, kABPersonSocialProfileServiceGameCenter, kABPersonSocialProfileService Facebook, kABPersonSocialProfileServiceMyspace, kABPersonSocialProfileServiceLinkedIn, kABPersonSocialProfileServiceFlickr )

//vCard formatting (iOS5 +)
-(NSData*)vCardRepresentation; //the current persons vCard representation
+(NSData*)vCardRepresentationForPeople:(NSArray*)people; //array of RHPerson Objects.

//geocoding
#if RH_AB_INCLUDE_GEOCODING
-(CLPlacemark*)placemarkForAddressID:(ABMultiValueIdentifier)addressID;
-(CLLocation*)locationForAddressID:(ABMultiValueIdentifier)addressID;
#endif //end Geocoding

#endif //end iOS5+

//remove person from addressBook
-(BOOL)remove;
-(BOOL)hasBeenRemoved; // we check to see if ABAddressBookGetPersonWithRecordID() returns NULL for self.recordID; This is the recommended approach from the AB docs.


//composite name format for this explicit record
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000
-(ABPersonCompositeNameFormat)compositeNameFormat; // at runtime, if you are running on a pre ios 7 device, we return the default system preference
#endif //end iOS7+

@end
