//
//  RHRecord.m
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

#import "RHRecord.h"
#import "RHRecord_Private.h"

#import "RHAddressBook.h"
#import "RHAddressBook_private.h"
#import "RHMultiValue.h"

@implementation RHRecord

-(id)initWithAddressBook:(RHAddressBook*)addressBook recordRef:(ABRecordRef)recordRef{
    self = [super init];
    if (self) {
        
        if (!recordRef){
            arc_release_nil(self);
            return nil;
        }

        _addressBook = arc_retain(addressBook);
        _recordRef = CFRetain(recordRef);

        //check in so we can be added to the weak link cache
        if (_addressBook){
            [_addressBook _recordCheckIn:self];
        }
    }
    return self;
}
#pragma mark - thread safe action block
-(void)performRecordAction:(void (^)(ABRecordRef recordRef))actionBlock waitUntilDone:(BOOL)wait{
    //if we have an address book perform it on that thread
    if (_addressBook){
        if (_recordRef) CFRetain(_recordRef);
        [_addressBook performAddressBookAction:^(ABAddressBookRef addressBookRef) {
            actionBlock(_recordRef);
            if (_recordRef) CFRelease(_recordRef);
        } waitUntilDone:wait];
    } else {
        //otherwise, a user created object... just use current thread.
        actionBlock(_recordRef);
    }

}



#pragma mark - properties

@synthesize addressBook=_addressBook;
@synthesize recordRef=_recordRef;

-(ABRecordID)recordID{
    
    __block ABRecordID recordID = kABPropertyInvalidID;
    
    [self performRecordAction:^(ABRecordRef recordRef) {
        recordID = ABRecordGetRecordID(recordRef);
    } waitUntilDone:YES];
    
    return recordID;
}

-(ABRecordType)recordType{

    __block ABRecordType recordType = -1;
    
    [self performRecordAction:^(ABRecordRef recordRef) {
        recordType = ABRecordGetRecordType(recordRef);
    } waitUntilDone:YES];
    
    return recordType;
}

-(NSString*)compositeName{
   __block CFStringRef compositeNameRef = NULL;

    [self performRecordAction:^(ABRecordRef recordRef) {
        compositeNameRef = ABRecordCopyCompositeName(recordRef);
    } waitUntilDone:YES];

    NSString* compositeName = [(__bridge NSString*)compositeNameRef copy];
    if (compositeNameRef) CFRelease(compositeNameRef);
    
    return arc_autorelease(compositeName);
}


#pragma mark - generic getter/setter/remover
-(id)getBasicValueForPropertyID:(ABPropertyID)propertyID{
    if (!_recordRef) return nil; //no record ref
    if (propertyID == kABPropertyInvalidID) return nil; //invalid    
    
    __block CFTypeRef value = NULL;
    
    [self performRecordAction:^(ABRecordRef recordRef) {
        value = ABRecordCopyValue(recordRef, propertyID);
    } waitUntilDone:YES];

    id result = [(__bridge id)value copy];
    if (value) CFRelease(value);
    
    return arc_autorelease(result);
}


-(BOOL)setBasicValue:(CFTypeRef)value forPropertyID:(ABPropertyID)propertyID error:(NSError**)error{
    if (!_recordRef) return false; //no record ref
    if (propertyID == kABPropertyInvalidID) return false; //invalid
    if (value == NULL) return [self unsetBasicValueForPropertyID:propertyID error:error]; //allow NULL to unset the property
    
    __block CFErrorRef cfError = NULL;
    __block BOOL result;
    [self performRecordAction:^(ABRecordRef recordRef) {
        result = ABRecordSetValue(recordRef, propertyID, value, &cfError);
    } waitUntilDone:YES];

    if (!result){
        if (error && cfError) *error = (NSError*)ARCBridgingRelease(CFRetain(cfError));
        if (cfError) CFRelease(cfError);
    }
    return result;
}

-(BOOL)unsetBasicValueForPropertyID:(ABPropertyID)propertyID error:(NSError**)error{
    if (!_recordRef) return false; //no record ref
    if (propertyID == kABPropertyInvalidID) return false; //invalid

    __block CFErrorRef cfError = NULL;
    __block BOOL result;
    [self performRecordAction:^(ABRecordRef recordRef) {
        result = ABRecordRemoveValue(recordRef, propertyID, &cfError);
    } waitUntilDone:YES];

    if (!result){
        if (error && cfError) *error = (NSError*)ARCBridgingRelease(CFRetain(cfError));
        if (cfError) CFRelease(cfError);
    }
    return result;
}


#pragma mark - generic multi value getter/setter/remover
-(RHMultiValue*)getMultiValueForPropertyID:(ABPropertyID)propertyID{
    if (!_recordRef) return nil; //no record ref
    if (propertyID == kABPropertyInvalidID) return nil; //invalid    
    
    __block ABMultiValueRef valueRef = NULL;
    
    [self performRecordAction:^(ABRecordRef recordRef) {
        valueRef = ABRecordCopyValue(recordRef, propertyID);
    } waitUntilDone:YES];
    
    RHMultiValue *multiValue = nil;
    if (valueRef){
        multiValue = [[RHMultiValue alloc] initWithMultiValueRef:valueRef];
        CFRelease(valueRef);
    }    
    return arc_autorelease(multiValue);
}

-(BOOL)setMultiValue:(RHMultiValue*)multiValue forPropertyID:(ABPropertyID)propertyID error:(NSError**)error{
    if (multiValue == NULL) return [self unsetMultiValueForPropertyID:propertyID error:error]; //allow NULL to unset the property
    return [self setBasicValue:multiValue.multiValueRef forPropertyID:propertyID error:error];
}

-(BOOL)unsetMultiValueForPropertyID:(ABPropertyID)propertyID error:(NSError**)error{
    //this should just be able to be forwarded
   return [self unsetBasicValueForPropertyID:propertyID error:error];
}


#pragma mark - forward
-(BOOL)save{
    return [_addressBook save];
}

//renamed method shim
-(BOOL)save:(NSError**)error{
    RHErrorLog(@"RHAddressBook: The save: method has been renamed to saveWithError: You should update your sources appropriately.");
    return [self saveWithError:error];
}

-(BOOL)saveWithError:(NSError**)error{
    return [_addressBook saveWithError:error];
}
-(BOOL)hasUnsavedChanges{
    return [_addressBook hasUnsavedChanges];
}
-(void)revert{
    [_addressBook revert];
}


#pragma mark - cleanup

//unfortunately ensuring dealloc occurs on our _addressBook queue is not available under ARC.
#if ARC_IS_NOT_ENABLED
-(oneway void)release{
    //ensure dealloc occurs on our ABs addressBookQueue
    //we do this to guarantee that we are removed from the weak cache before someone else ends up with us.
    if (_addressBook && !rh_dispatch_is_current_queue_for_addressbook(_addressBook)){
        dispatch_async(_addressBook.addressBookQueue, ^{
            [self release];
        });
    } else {
        [super release];
    }
}
#endif

-(void)dealloc {
    
    //check out so we can be removed from the weak link lookup cache
    if (_addressBook){
        [_addressBook _recordCheckOut:self];
    }
    
    arc_release_nil(_addressBook);
    if (_recordRef) CFRelease(_recordRef);
    _recordRef = NULL;
    arc_super_dealloc();
}

#pragma mark - misc
-(NSString*)description{
    return [NSString stringWithFormat:@"<%@: %p> name:%@", NSStringFromClass([self class]), self, self.compositeName];
}

+(NSString*)descriptionForRecordType:(ABRecordType)type{
    switch (type) {
        case kABPersonType:    return @"kABPersonType - Person Record Type";
        case kABGroupType:    return @"kABGroupType - Group Record Type";
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 50000
        case kABSourceType:    return @"kABSourceType - Source Record Type";
#endif            
        default: return @"Unknown Property Type";
    }
}

+(NSString*)descriptionForPropertyType:(ABPropertyType)type{
    switch (type) {
        case kABInvalidPropertyType:    return @"kABInvalidPropertyType - Invalid Property Type";
        case kABStringPropertyType:     return @"kABStringPropertyType - String Property Type";
        case kABIntegerPropertyType:    return @"kABIntegerPropertyType - Integer Property Type";
        case kABRealPropertyType:       return @"kABRealPropertyType - Real Property Type";
        case kABDateTimePropertyType:   return @"kABDateTimePropertyType - Date Time Property Type";
        case kABDictionaryPropertyType: return @"kABDictionaryPropertyType - Dictionary Property Type";

        case kABMultiStringPropertyType:     return @"kABMultiStringPropertyType - Multi String Property Type";
        case kABMultiIntegerPropertyType:    return @"kABMultiIntegerPropertyType - Multi Integer Property Type";
        case kABMultiRealPropertyType:       return @"kABMultiRealPropertyType - Multi Real Property Type";
        case kABMultiDateTimePropertyType:   return @"kABMultiDateTimePropertyType - Multi Date Time Property Type";
        case kABMultiDictionaryPropertyType: return @"kABMultiDictionaryPropertyType - Multi Dictionary Property Type";
            
        default: return @"Unknown Property Type";
    }
}


@end
