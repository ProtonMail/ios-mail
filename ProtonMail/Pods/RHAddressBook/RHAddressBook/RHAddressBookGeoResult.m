//
//  RHAddressBookGeoResult.m
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

#import "RHAddressBookGeoResult.h"

#if RH_AB_INCLUDE_GEOCODING
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 50000

#import <CommonCrypto/CommonDigest.h>   //for hashing functions
#import <CoreLocation/CoreLocation.h>   //for geo
#import "RHAddressBook.h"               // for logging
#import "RHAddressBookSharedServices.h" // for isGeocodingSupported

@interface RHAddressBookGeoResult ()
@property (readwrite, retain) CLPlacemark *placemark;
@property (readwrite, assign) BOOL resultNotFound;
@end

@implementation RHAddressBookGeoResult {

    CLGeocoder *_geocoder; //only a valid pointer while performing a geo operation
}

@synthesize placemark=_placemark;
@synthesize personID=_personID;
@synthesize addressID=_addressID;
@synthesize addressHash=_addressHash;
@synthesize resultNotFound=_resultNotFound;

-(CLLocation*)location{
    return _placemark.location;
}

-(id)init {
    [NSException raise:NSInvalidArgumentException format:@"Unable to create a GeoResult without a personID and addressID."];
    return nil;
}

-(id)initWithPersonID:(ABRecordID)personID addressID:(ABMultiValueIdentifier)addressID {
    self = [super init];
    if (self) {
        _personID = personID;
        _addressID = addressID;
        
        //compute address hash and store it
        _addressHash = arc_retain([RHAddressBookGeoResult hashForDictionary:[self associatedAddressDictionary]]);
    }
    return self;
}


-(id)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        _placemark = arc_retain([coder decodeObjectForKey:@"placemark"]);
        _personID = [coder decodeInt32ForKey:@"personID"];
        _addressID = [coder decodeInt32ForKey:@"addressID"];
        _addressHash = arc_retain([coder decodeObjectForKey:@"addressHash"]);
        _resultNotFound = [coder decodeBoolForKey:@"resultNotFound"];
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder *)coder{
    [coder encodeObject:_placemark forKey:@"placemark"];
    [coder encodeInt32:_personID forKey:@"personID"];
    [coder encodeInt32:_addressID forKey:@"addressID"];
    [coder encodeObject:_addressHash forKey:@"addressHash"];
    [coder encodeBool:_resultNotFound forKey:@"resultNotFound"];    
}



-(BOOL)isValid{
    BOOL valid = NO;

    NSDictionary *address = [self associatedAddressDictionary];
    if (address){
        NSString *newHash = [RHAddressBookGeoResult hashForDictionary:address];
        if ([newHash isEqualToString:self.addressHash]){
            valid = YES;
        }
    }
    
    return valid;
}


-(NSDictionary*)associatedAddressDictionary{

    NSDictionary *result = nil;
    ABAddressBookRef addressBookRef = NULL;
    
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 60000
    if (ABAddressBookCreateWithOptions != NULL){
        
        CFErrorRef errorRef = NULL;
        addressBookRef = ABAddressBookCreateWithOptions(nil, &errorRef);
        
        if (!addressBookRef){
            //bail
            RHErrorLog(@"Error: Failed to get -[RHAddressBookGeoResult associatedAddressDictionary]. Underlying ABAddressBookCreateWithOptions() failed with error: %@", errorRef);
            if (errorRef) CFRelease(errorRef);
            
            return nil;
        }

    } else {
#endif //end iOS6+
        
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        addressBookRef = ABAddressBookCreate();
#pragma clang diagnostic pop
        
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 60000
    }
#endif //end iOS6+
    
    ABRecordRef person = ABAddressBookGetPersonWithRecordID(addressBookRef, self.personID);
    if (person){
        ABMultiValueRef addresses = ABRecordCopyValue(person, kABPersonAddressProperty);
        if (ABMultiValueGetCount(addresses) > 0){
            
            CFIndex index = ABMultiValueGetIndexForIdentifier(addresses, self.addressID);
            if (index != -1){
                CFDictionaryRef address = ABMultiValueCopyValueAtIndex(addresses, index);
                if (address){

                    result = [[NSDictionary alloc] initWithDictionary:(__bridge NSDictionary*)address];
                    CFRelease(address);
                }
            } else {
                //invalid addressID
                RHLog(@"got a -1 address index for %@", self);
            }
        }
        //cleanup
        if (addresses) CFRelease(addresses);
    }
    if (addressBookRef) CFRelease(addressBookRef);

    return arc_autorelease(result);
}


#pragma mark - geocode
-(void)geocodeAssociatedAddressDictionary{
    
    //if geocoding is not supported, do nothing
    if (![RHAddressBookSharedServices isGeocodingSupported]) return;
        
    //don't do anything if our address is no longer valid
    if (! [self isValid]){ 
        RHLog(@"%@ is no longer valid. Skipping Geocode Op.", self);
        return;
    }
    
    //geocode currently in progress.. nothing to do
    if (_geocoder){
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        _geocoder = [[CLGeocoder alloc] init];

        NSDictionary *addressDict = [self associatedAddressDictionary];
        
        RHLog(@"beginning geocode for :%@", addressDict);

        [_geocoder geocodeAddressDictionary:addressDict completionHandler:^(NSArray *placemarks, NSError *error) {
            if ([placemarks count]){
                self.placemark = [placemarks objectAtIndex:0];
                self.resultNotFound = NO;
                
                RHLog(@"geocode found for :%@", self);
                
            } else {
                if (error.code == kCLErrorNetwork){
                    //network error, offline
                    RHLog(@"geocode not found for: %@. A network error occurred: %@.", self, error);
                } else {
                    //we are interested in:
                    //kCLErrorGeocodeFoundNoResult
                    //kCLErrorGeocodeFoundPartialResult
                    //kCLErrorGeocodeCanceled
                    self.resultNotFound = YES;
                    RHLog(@"geocode not found for: %@ error: %@", self, error);
                }
            }
            
            // we no longer need the geocoder, release it.
             arc_release_nil(_geocoder);

            dispatch_async(dispatch_get_main_queue(), ^{
                //send our notification RHAddressBookPersonAddressGeocodeCompleted
                NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:
                                      [NSNumber numberWithInteger:self.personID], @"personID",
                                      [NSNumber numberWithInteger:self.addressID], @"addressID",
                                      nil];
                [[NSNotificationCenter defaultCenter] postNotificationName:RHAddressBookPersonAddressGeocodeCompleted object:nil userInfo:info];
                
            });
        }];
            
    });
    
}

-(void)dealloc{
    arc_release_nil(_placemark);
    arc_release_nil(_addressHash);
    arc_super_dealloc();
}

#pragma mark - hashing
+(NSString*)hashForDictionary:(NSDictionary*)dict{
    return [RHAddressBookGeoResult hashForString:[dict description]];
}

+(NSString*)hashForString:(NSString*)string{
    if (! string) return nil;
    if (!CC_MD5) return nil; //availability check

    //md5 hash the string    
    const char *str = [string UTF8String];
    unsigned char outBuffer[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, strlen(str), outBuffer);
    
    NSMutableString *hash = [NSMutableString string];
    for(int i = 0; i<CC_MD5_DIGEST_LENGTH; i++) {
        [hash appendFormat:@"%02x", outBuffer[i]];
    }
    return hash;
}



@end

#endif //end iOS5+
#endif //end Geocoding
