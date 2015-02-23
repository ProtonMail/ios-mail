//
//  RHAddressBookGeoResult.h
//  RHAddressBook
//
//  Created by Richard Heard on 12/11/11.
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

#import "RHAddressBook.h"

#if RH_AB_INCLUDE_GEOCODING
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 50000

#import <Foundation/Foundation.h>
#import <AddressBook/AddressBook.h>
#import <CoreLocation/CoreLocation.h>

@class CLPlacemark;
@class CLGeocoder;

@interface RHAddressBookGeoResult : NSObject <NSCoding>

@property (assign, readonly) ABRecordID personID;
@property (assign, readonly) ABMultiValueIdentifier addressID;
@property (retain, readonly) NSString *addressHash;

@property (retain, readonly) CLLocation *location;
@property (retain, readonly) CLPlacemark *placemark; //we only store the most accurate placemark
@property (assign, readonly) BOOL resultNotFound;

//initializer... only time the ids can be set, auto calculates its address hash
-(id)initWithPersonID:(ABRecordID)personID addressID:(ABMultiValueIdentifier)addressID;

//used to determine if the stored address hash matches the corresponding address in the current AddressBook
-(BOOL)isValid;

-(NSDictionary*)associatedAddressDictionary; //performs a realtime lookup based on the stored ids

//geocode
-(void)geocodeAssociatedAddressDictionary; //performs a geocode on the object

//hashing
+(NSString*)hashForDictionary:(NSDictionary*)dict;
+(NSString*)hashForString:(NSString*)string;

@end

#endif //end iOS5+
#endif //end Geocoding
