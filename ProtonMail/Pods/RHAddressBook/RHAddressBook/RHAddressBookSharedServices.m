//
//  RHAddressBookSharedServices.m
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

#import "RHAddressBookSharedServices.h"

#if RH_AB_INCLUDE_GEOCODING
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 50000
#import "RHAddressBookGeoResult.h"
#endif //end iOS5+
#endif //end Geocoding

#import "NSThread+RHBlockAdditions.h"
#import "RHAddressBook.h"
#import "RHAddressBookThreadMain.h"

#import <AddressBook/AddressBook.h>
#import <CoreLocation/CoreLocation.h>

#define PROCESS_ADDRESS_EVERY_SECONDS 5.0 //seconds between each geocode

//private
@interface RHAddressBookSharedServices ()

#if RH_AB_INCLUDE_GEOCODING
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 50000

//cache
-(void)loadCache;
-(void)writeCache;
-(void)purgeCache;
-(void)rebuildCache;
-(NSString*)cacheFilePath;

//geocoding
-(RHAddressBookGeoResult*)cacheEntryForPersonID:(ABRecordID)pid addressID:(ABPropertyID)aid;
-(void)processAddressesMissingLocationInfo;
-(void)processTimerFire;

#endif //end iOS5+
#endif //end Geocoding


//addressbook notifications
-(void)registerForAddressBookChanges;
-(void)deregisterForAddressBookChanges;
void RHAddressBookExternalChangeCallback (ABAddressBookRef addressBook, CFDictionaryRef info, void *context );


@end

@implementation RHAddressBookSharedServices {
    //we have our own instance of the address book
    ABAddressBookRef _addressBook;
    NSThread *_addressBookThread; //perform all address book operations on this thread. (AB is not thread safe. :()
    
#if RH_AB_INCLUDE_GEOCODING
    NSMutableArray *_cache; //array of RHAddressBookGeoResult objects
    NSTimer *_timer;
#endif //end Geocoding

}

#pragma mark - singleton
static __strong RHAddressBookSharedServices *_sharedInstance = nil;

+(id)sharedInstance{
    if (_sharedInstance) return _sharedInstance; //for performance reasons, check outside @synchronized
    
    @synchronized([self class]){
        if (!_sharedInstance){
            _sharedInstance = [[super allocWithZone:NULL] init];
        }
    }
    
    return _sharedInstance;
}

+(id)allocWithZone:(NSZone *)zone{
    return arc_retain([self sharedInstance]);
}

-(id)init {
        
    self = [super init];
    if (self) {
        
        //because NSThread retains its target, we use a placeholder object that contains the threads main method
        RHAddressBookThreadMain *threadMain = arc_autorelease([[RHAddressBookThreadMain alloc] init]);
        _addressBookThread = [[NSThread alloc] initWithTarget:threadMain selector:@selector(threadMain:) object:nil];
        [_addressBookThread setName:[NSString stringWithFormat:@"RHAddressBookSharedServicesThread for %p", self]];
        [_addressBookThread start];

        
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 60000
        if (ABAddressBookCreateWithOptions != NULL){
            __block CFErrorRef errorRef = NULL;
            [_addressBookThread rh_performBlock:^{
                _addressBook = ABAddressBookCreateWithOptions(nil, &errorRef);
            }];
            
            if (!_addressBook){
                //bail
                RHErrorLog(@"Error: Failed to create RHAddressBookSharedServices instance. Underlying ABAddressBookCreateWithOptions() failed with error: %@", errorRef);
                if (errorRef) CFRelease(errorRef);
                
                arc_release_nil(self);
                
                return nil;
            }
            
        } else {
#endif //end iOS6+
            
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            [_addressBookThread rh_performBlock:^{
                _addressBook = ABAddressBookCreate();
            }];
#pragma clang diagnostic pop
            
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 60000
        }
#endif //end iOS6+
        
        
#if RH_AB_INCLUDE_GEOCODING
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 50000
        if ([RHAddressBookSharedServices isGeocodingSupported]){
            [self loadCache];
            [self rebuildCache];
        }
#endif //end iOS5+
#endif //end Geocoding

        [self registerForAddressBookChanges];

    }
    return self;
}

-(id)copyWithZone:(NSZone *)zone{
    return self;
}

#pragma mark - cleanup
-(void)dealloc {
    //do stuff (even though we are a singleton)
    [self deregisterForAddressBookChanges];

    if (_addressBook) { CFRelease(_addressBook); _addressBook = NULL; }
    
    [_addressBookThread cancel];
    arc_release_nil(_addressBookThread);

#if RH_AB_INCLUDE_GEOCODING
    arc_release_nil(_cache);
    arc_release_nil(_timer);
#endif //end Geocoding
    
    arc_super_dealloc();
}

#if RH_AB_INCLUDE_GEOCODING
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 50000

#pragma mark - cache management
-(void)loadCache{
    RHLog(@"");
    arc_release(_cache);
    _cache = arc_retain([NSKeyedUnarchiver unarchiveObjectWithFile:[self cacheFilePath]]);
    
    //if unarchive failed or on first run
    if (!_cache) _cache = [[NSMutableArray alloc] init];
    
}

-(void)writeCache{
    RHLog(@"");
    [NSKeyedArchiver archiveRootObject:_cache toFile:[self cacheFilePath]];
    
}

-(void)purgeCache{
    RHLog(@"");
    [[NSFileManager defaultManager] removeItemAtPath:[self cacheFilePath] error:nil];
    [self loadCache];
}

//creates a new cache array, pulling over all existing values from the old cache array that are useable
-(void)rebuildCache{
    if (![[NSThread currentThread] isEqual:_addressBookThread]){
        [self performSelector:_cmd onThread:_addressBookThread withObject:nil waitUntilDone:YES];
        return;
    }
    RHLog(@"");
    
    NSMutableArray *newCache = [NSMutableArray array];

    //make sure the address book instance is up to date
    ABAddressBookRevert(_addressBook);
    
    CFArrayRef people = ABAddressBookCopyArrayOfAllPeople(_addressBook);

    if (people){
        for (CFIndex i = 0; i < CFArrayGetCount(people); i++) {
            
            ABRecordRef person = CFArrayGetValueAtIndex(people, i);

            if (person){
                
                ABRecordID personID = ABRecordGetRecordID(person);
                ABMultiValueRef addresses = ABRecordCopyValue(person, kABPersonAddressProperty);
                
                if (addresses){
                    for (CFIndex i = 0; i < ABMultiValueGetCount(addresses); i++) {
                        
                        ABPropertyID addressID = ABMultiValueGetIdentifierAtIndex(addresses, i);
                        CFDictionaryRef addressDict = ABMultiValueCopyValueAtIndex(addresses, i);
                        //======================================================================
                        
                        //see if we have a valid, old entry
                        RHAddressBookGeoResult* old = [self cacheEntryForPersonID:personID addressID:addressID];
                        
                        if (old && [old isValid]){
                            //yes
                            [newCache addObject:old]; // just add it and be done.
                        } else {
                            // not valid, create a new entry
                            RHAddressBookGeoResult* new = [[RHAddressBookGeoResult alloc] initWithPersonID:personID addressID:addressID];
                            [newCache addObject:new];
                            arc_release(new);
                        }
                        
                        //======================================================================
                        if (addressDict) CFRelease(addressDict);
                    }
                    
                    CFRelease(addresses);
                } //addresses
            } //person
        }
        
        CFRelease(people);
    } //people

    //swap old cache with the new
    arc_release(_cache);
    _cache = arc_retain(newCache);
    
    [self processAddressesMissingLocationInfo];
    [self writeCache]; //get it to disk asap
    
}


-(RHAddressBookGeoResult*)cacheEntryForPersonID:(ABRecordID)pid addressID:(ABPropertyID)aid{
    for (RHAddressBookGeoResult *entry in _cache) {
        if (entry.personID == pid && entry.addressID == aid){
            return arc_autorelease(arc_retain(entry));
        }
    }
    
    return nil;
}

-(NSString*)cacheFilePath{
    
    //cache
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    
    NSString *applicationID = [[[NSBundle mainBundle] infoDictionary] valueForKey:(NSString *)kCFBundleIdentifierKey];
    path = [path stringByAppendingPathComponent:applicationID];
    
    path = [path stringByAppendingPathComponent:@"RHAddressBookGeoCache.cache"];
    
    return path;
}


#pragma mark - Geocoding Process
-(void)processAddressesMissingLocationInfo{
    
    //don't do any geocoding if its not available (iOS 5+ only)
    if (![RHAddressBookSharedServices isGeocodingSupported]) return;

    //if disabled, do nothing
    if (![self.class isPreemptiveGeocodingEnabled]) return;
    
    
    if (!_timer){
        _timer = arc_retain([NSTimer scheduledTimerWithTimeInterval:PROCESS_ADDRESS_EVERY_SECONDS target:self selector:@selector(processTimerFire) userInfo:nil repeats:YES]);
    }
}

-(void)processTimerFire{
        
    //if we are offline, the geocode fails with a specific error
    // in that instance we don't set the resultNotFound flag, so next time around we will re-attempt the particular address.
    //TODO: we really should handle this better, with our shared services class observing some form of reachability and pausing / resuming the timer.
    
    //write the cache periodically, not just at the end... incase we... you know..... yea.....
    [self writeCache];
    
    //if we have been disabled, stop working
    if (![self.class isPreemptiveGeocodingEnabled]){
        [_timer invalidate];
        arc_release_nil(_timer);
        RHLog(@"Location Lookup has been disabled.");
        return;
    }
    
    //look for next unprocessed entry
    for (RHAddressBookGeoResult *entry in _cache) {
        if (!entry.location && !entry.resultNotFound){
            //needs processing
            [entry geocodeAssociatedAddressDictionary]; //if this is called and the entry is already geocoding, its just a no-op and so is an easy way for us to bail
            return;
        }
    }
    
    //we are done, all addresses processed
    [self writeCache];
    [_timer invalidate];
    arc_release_nil(_timer);

    RHLog(@"Location Lookup Processing done.");
    
}

#pragma mark - Geocode Lookup
//forward
-(CLPlacemark*)placemarkForPersonID:(ABRecordID)personID addressID:(ABMultiValueIdentifier)addressID{
    RHAddressBookGeoResult *cacheEntry = [self cacheEntryForPersonID:personID addressID:addressID];
    if (cacheEntry && !cacheEntry.placemark && !cacheEntry.resultNotFound && [self.class isGeocodingSupported] && !_timer) {
        //lets force a geocode for this one address
        [cacheEntry geocodeAssociatedAddressDictionary];
    }
    return [cacheEntry placemark];
}

-(CLLocation*)locationForPersonID:(ABRecordID)personID addressID:(ABMultiValueIdentifier)addressID{
    return [[self placemarkForPersonID:personID addressID:addressID] location];
}

//reverse
-(NSArray*)geoResultsWithinDistance:(CLLocationDistance)distance ofLocation:(CLLocation*)location{
    NSMutableArray *results = [[NSMutableArray alloc] init];
    
    for (RHAddressBookGeoResult *entry in _cache) {
        if (entry.location) {
            CLLocationDistance tmpDistance = [entry.location distanceFromLocation:location];
            if (tmpDistance < distance) {
                //within radius
                [results addObject:entry];
            }
        }
    } 
    
    return arc_autorelease(results);
}

-(RHAddressBookGeoResult*)geoResultClosestToLocation:(CLLocation*)location{
    return [self geoResultClosestToLocation:location distanceOut:nil];
}

-(RHAddressBookGeoResult*)geoResultClosestToLocation:(CLLocation*)location distanceOut:(CLLocationDistance*)distanceOut{

    CLLocationDistance distance = DBL_MAX;
    RHAddressBookGeoResult *result = nil;

    for (RHAddressBookGeoResult *entry in _cache) {
        if (entry.location) {
            CLLocationDistance tmpDistance = [entry.location distanceFromLocation:location];
            if (tmpDistance < distance) {
                //closer point
                result = entry;
                distance = tmpDistance;
            }
        }
    } 
    
    if (distanceOut) *distanceOut = distance;
    return result;
}

#endif //end iOS5+

#pragma mark - geocoding settings
NSString static * RHAddressBookSharedServicesPreemptiveGeocodingEnabled = @"RHAddressBookSharedServicesPreemptiveGeocodingEnabled";

+(BOOL)isPreemptiveGeocodingEnabled{
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 50000
    if ([RHAddressBookSharedServices isGeocodingSupported]){
        return [[NSUserDefaults standardUserDefaults] boolForKey:RHAddressBookSharedServicesPreemptiveGeocodingEnabled];
    }
#endif //end iOS5+
    return NO;
}

+(void)setPreemptiveGeocodingEnabled:(BOOL)enabled{
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 50000
    if ([RHAddressBookSharedServices isGeocodingSupported]){
        [[NSUserDefaults standardUserDefaults] setBool:enabled forKey:RHAddressBookSharedServicesPreemptiveGeocodingEnabled];
        //for the disabled->enabled case
        if (_sharedInstance)[_sharedInstance processAddressesMissingLocationInfo];
    }
#endif //end iOS5+

}

-(float)preemptiveGeocodingProgress{
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 50000
    if ([RHAddressBookSharedServices isGeocodingSupported]){
        NSInteger incomplete = 0;
        for (RHAddressBookGeoResult *entry in _cache) {
            if (!entry.location && !entry.resultNotFound){
                incomplete++;
            }
        }

        if ([_cache count] == 0) return 1.0f;
        
        return 1.0f - ((float)incomplete / (float)[_cache count]);
    }
#endif //end iOS5+

    return 0.0f;
}


+(BOOL)isGeocodingSupported{
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 50000
    //the response to selector check is required because iOS4 actually has a private CLGeocoder class. 
    return ([CLGeocoder class] && [CLGeocoder instancesRespondToSelector:@selector(geocodeAddressDictionary:completionHandler:)]);
#endif //end iOS5+
    return NO; //if not compiled with Geocoding, return false, always
}

#endif //end Geocoding


#pragma mark - addressbook changes

-(void)registerForAddressBookChanges{
    if (![[NSThread currentThread] isEqual:_addressBookThread]){
        [self performSelector:_cmd onThread:_addressBookThread withObject:nil waitUntilDone:YES];
        return;
    }

    ABAddressBookRegisterExternalChangeCallback(_addressBook, RHAddressBookExternalChangeCallback, (__bridge void *)(self)); //use the context as a pointer to self
    
}

-(void)deregisterForAddressBookChanges{
    if (![[NSThread currentThread] isEqual:_addressBookThread]){
        [self performSelector:_cmd onThread:_addressBookThread withObject:nil waitUntilDone:YES];
        return;
    }
    
    // when unregistering a callback both the callback and the context
    // need to match the ones that were registered.
    if (_addressBook){
        ABAddressBookUnregisterExternalChangeCallback(_addressBook,  RHAddressBookExternalChangeCallback, (__bridge void *)(self));
    }
    
}

void RHAddressBookExternalChangeCallback (ABAddressBookRef addressBook, CFDictionaryRef info, void *context ){

#if RH_AB_INCLUDE_GEOCODING
    RHLog(@"AddressBook changed externally. Rebuilding RHABGeoCache");
    
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 50000
    if ([RHAddressBookSharedServices isGeocodingSupported]){
        [(__bridge RHAddressBookSharedServices*)context rebuildCache]; //use the context as a pointer to self
    }
#endif //end iOS5+
#endif //end Geocoding

    //post external change notification for public clients, on the main thread
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:RHAddressBookExternalChangeNotification object:nil];
    });
}




@end
