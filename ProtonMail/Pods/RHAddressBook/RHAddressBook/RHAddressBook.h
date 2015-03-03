//
//  RHAddressBook.h
//  RHAddressBook
//
//  Created by Richard Heard on 11/11/11.
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

#import <Foundation/Foundation.h>
#import <AddressBook/AddressBook.h>

//enable framework debug logging (by default, enabled if DEBUG is defined, change FALSE to TRUE to enable always)
#ifndef RH_AB_ENABLE_DEBUG_LOGGING
    #define RH_AB_ENABLE_DEBUG_LOGGING  ( defined(DEBUG) || FALSE )
#endif

//include geocoding support in RHAddressbook. (0 == NO; 1 == YES;)
#ifndef RH_AB_INCLUDE_GEOCODING
    #define RH_AB_INCLUDE_GEOCODING 0
#endif


@class RHRecord;
@class RHSource;

@class RHPerson;
@class RHGroup;

@class CLLocation;
@class CLPlacemark;

//Notification fired when the address book is changed externally
extern NSString * const RHAddressBookExternalChangeNotification;

#if RH_AB_INCLUDE_GEOCODING
//notification fired when a person and address pair has been geocoded (info dict contains personID and addressID as [NSNumber integerValue])
extern NSString * const RHAddressBookPersonAddressGeocodeCompleted;
#endif

//authorization status enum.
typedef enum RHAuthorizationStatus {
    RHAuthorizationStatusNotDetermined = 0,
    RHAuthorizationStatusRestricted,
    RHAuthorizationStatusDenied,
    RHAuthorizationStatusAuthorized
} RHAuthorizationStatus;


@interface RHAddressBook : NSObject

-(id)init; //create an instance of the addressbook (iOS6+ may return nil, signifying an access error. Error is logged to console)

+(RHAuthorizationStatus)authorizationStatus; // pre iOS6+ will always return RHAuthorizationStatusAuthorized
-(void)requestAuthorizationWithCompletion:(void (^)(bool granted, NSError* error))completion; //completion block is always called, you only need to call authorize if ([RHAddressBook authorizatonStatus] != RHAuthorizationStatusAuthorized). Pre, iOS6 completion block is always called with granted=YES. The block is called on an arbitrary queue, so dispatch_async to the main queue for any UI updates.

//any access to the underlying ABAddressBook should be done inside this block wrapper below.
//from the addressbook programming guide... Important: Instances of ABAddressBookRef cannot be used by multiple threads. Each thread must make its own instance by calling ABAddressBookCreate.
-(void)performAddressBookAction:(void (^)(ABAddressBookRef addressBookRef))actionBlock waitUntilDone:(BOOL)wait;

//access 
-(NSArray*)sources;
-(RHSource*)defaultSource;
-(RHSource*)sourceForABRecordRef:(ABRecordRef)sourceRef; //returns nil if ref not found in the current ab, eg unsaved record from another ab. if the passed recordRef does not belong to the current addressbook, the returned person objects underlying personRef will differ from the passed in value. This is required in-order to maintain thread safety for the underlying AddressBook instance.
-(RHSource*)sourceForABRecordID:(ABRecordID)sourceID; //returns nil if not found in the current ab, eg unsaved record from another ab.

-(NSArray*)groups;
-(long)numberOfGroups;
-(NSArray*)groupsInSource:(RHSource*)source;
-(RHGroup*)groupForABRecordRef:(ABRecordRef)groupRef; //returns nil if ref not found in the current ab, eg unsaved record from another ab. if the passed recordRef does not belong to the current addressbook, the returned person objects underlying personRef will differ from the passed in value. This is required in-order to maintain thread safety for the underlying AddressBook instance.
-(RHGroup*)groupForABRecordID:(ABRecordID)groupID; //returns nil if not found in the current ab, eg unsaved record from another ab.

-(NSArray*)people;
-(long)numberOfPeople;
-(NSArray*)peopleOrderedBySortOrdering:(ABPersonSortOrdering)ordering;
-(NSArray*)peopleOrderedByUsersPreference; //preferred
-(NSArray*)peopleOrderedByFirstName;
-(NSArray*)peopleOrderedByLastName;

-(NSArray*)peopleWithName:(NSString*)name;
-(NSArray*)peopleWithEmail:(NSString*)email;
-(RHPerson*)personForABRecordRef:(ABRecordRef)personRef; //returns nil if ref not found in the current ab, eg unsaved record from another ab. if the passed recordRef does not belong to the current addressbook, the returned person objects underlying personRef will differ from the passed in value. This is required in-order to maintain thread safety for the underlying AddressBook instance.
-(RHPerson*)personForABRecordID:(ABRecordID)personID; //returns nil if not found in the current ab, eg unsaved record from another ab.


//add

//convenience people methods (return a +1 retain count object and are automatically added to the current addressBook)
-(RHPerson*)newPersonInDefaultSource; //returns nil on error (eg read only source)
-(RHPerson*)newPersonInSource:(RHSource*)source;

//add a person to the current address book instance (this will thrown an exception if the RHPerson object belongs to another ab, eg by being been added to another ab, or created with a source object that was not from the current addressbook)
-(BOOL)addPerson:(RHPerson*)person;
-(BOOL)addPerson:(RHPerson*)person error:(NSError**)error;

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 50000
//add people from vCard to the current addressbook (iOS5+ : pre iOS5 these methods are no-ops)
-(NSArray*)addPeopleFromVCardRepresentationToDefaultSource:(NSData*)representation; //returns an array of newly created RHPerson objects, nil on error
-(NSArray*)addPeopleFromVCardRepresentation:(NSData*)representation toSource:(RHSource*)source;
-(NSData*)vCardRepresentationForPeople:(NSArray*)people;

#endif //end iOS5+

//convenience group methods (return a +1 retain count object and are automatically added to the current addressBook)
-(RHGroup*)newGroupInDefaultSource; //returns nil on error (eg read only source or does not support groups ex. exchange)
-(RHGroup*)newGroupInSource:(RHSource*)source;

//add a group to the current address book instance (this will thrown an exception if the RHGroup object belongs to another ab, eg by being been added to another ab, or created with a source object that was not from the current addressbook)
-(BOOL)addGroup:(RHGroup*)group;
-(BOOL)addGroup:(RHGroup *)group error:(NSError**)error;

//remove
-(BOOL)removePerson:(RHPerson*)person;
-(BOOL)removePerson:(RHPerson*)person error:(NSError**)error;

-(BOOL)removeGroup:(RHGroup*)group;
-(BOOL)removeGroup:(RHGroup*)group error:(NSError**)error;


//save
-(BOOL)save;
-(BOOL)saveWithError:(NSError**)error;
-(BOOL)hasUnsavedChanges;
-(void)revert;


//user prefs
+(ABPersonSortOrdering)sortOrdering;
+(BOOL)orderByFirstName; // YES if first name ordering is preferred
+(BOOL)orderByLastName;  // YES if last name ordering is preferred

+(ABPersonCompositeNameFormat)compositeNameFormat;
+(BOOL)compositeNameFormatFirstNameFirst;  // YES if first name comes before last name
+(BOOL)compositeNameFormatLastNameFirst;  // YES if last name comes before first name


#if RH_AB_INCLUDE_GEOCODING
//if geocoding is currently supported (runtime & compile-time check safe)
+(BOOL)isGeocodingSupported;

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 50000

//geocoding (if geocoding is not available or background processing is disabled, only results already processed will be returned)

//class methods to enable / disable geocoding
+(BOOL)isPreemptiveGeocodingEnabled; //defaults to YES
+(void)setPreemptiveGeocodingEnabled:(BOOL)enabled; //Geocoding starts on first instantiation of the AB class, therefore this is a class method, allowing you to set it to false before the first AB instance is created.
-(float)preemptiveGeocodingProgress; // returns percentage range 0.0f - 1.0f

//forward
-(CLPlacemark*)placemarkForPerson:(RHPerson*)person addressID:(ABMultiValueIdentifier)addressID;
-(CLLocation*)locationForPerson:(RHPerson*)person addressID:(ABMultiValueIdentifier)addressID;

//reverse
-(NSArray*)peopleWithinDistance:(double)distance ofLocation:(CLLocation*)location; //distance in meters
-(RHPerson*)personClosestToLocation:(CLLocation*)location;
-(RHPerson*)personClosestToLocation:(CLLocation*)location distanceOut:(double*)distanceOut; //distance in meters

#endif //end iOS5+
#endif //end Geocoding

@end


//define the debug logging macros

#if RH_AB_ENABLE_DEBUG_LOGGING
#define RHLog(format, ...) NSLog( @"%s:%i %@ ", __PRETTY_FUNCTION__, __LINE__, [NSString stringWithFormat: format, ##__VA_ARGS__])
#else
#define RHLog(format, ...)
#endif

#define RHErrorLog(format, ...) NSLog( @"%s:%i %@ ", __PRETTY_FUNCTION__, __LINE__, [NSString stringWithFormat: format, ##__VA_ARGS__])

