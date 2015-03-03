//
//  RHPerson.m
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

#import "RHPerson.h"
#import "RHRecord_Private.h"

#import "RHAddressBook.h"
#import "RHSource.h"

@implementation RHPerson

#pragma mark - person creator methods
//+(id)newPersonInDefaultSource{
//    //this is not currently supported.... 
//    ABRecordRef newPersonRef = ABPersonCreate();
//    RHPerson *newPerson = nil;
//    if (newPersonRef){
//        newPerson = [[RHPerson alloc] initWithAddressBook:nil recordRef:newPersonRef];
//        CFRelease(newPersonRef);
//    }
//    
//    return newPerson;
//}

+(id)newPersonInSource:(RHSource*)source{
    return [[RHPerson alloc] initWithSource:source];
}

-(id)initWithSource:(RHSource *)source{
    ABRecordRef newPersonRef = ABPersonCreateInSource(source.recordRef);
    if (newPersonRef){
        self = [super initWithAddressBook:source.addressBook recordRef:newPersonRef];
        if (self){
            //extra setup?
        }
        CFRelease(newPersonRef);
    }
    
    return self;
}

+(RHPerson*)personForABRecordRef:(ABRecordRef)personRef inAddressBook:(RHAddressBook*)addressBook{
    return [addressBook personForABRecordRef:personRef];
}

+(RHPerson*)personForABRecordID:(ABRecordID)personID inAddressBook:(RHAddressBook*)addressBook{
    return [addressBook personForABRecordID:personID];
}


#pragma mark - localized property and labels (class methods)
+(NSString*)localizedPropertyName:(ABPropertyID)propertyID{ 
    CFStringRef nameRef = ABPersonCopyLocalizedPropertyName(propertyID);
    NSString *name = nil;
    if (nameRef){
        name = [NSString stringWithString:(__bridge NSString*)nameRef];
        CFRelease(nameRef);
    }
    return name;
}

+(NSString*)localizedLabel:(NSString*)label{
    CFStringRef localizedRef = ABAddressBookCopyLocalizedLabel((__bridge CFStringRef)label);
    NSString *localized = nil;
    if (localizedRef){
        localized = [NSString stringWithString:(__bridge NSString*)localizedRef];
        CFRelease(localizedRef);
    }
    return localized;
}


#pragma mark - source
-(RHSource*)inSource{
    if (ABPersonCopySource == NULL) return nil; //availability check
    
    __block ABRecordRef sourceRef = NULL;
    [self performRecordAction:^(ABRecordRef recordRef) {
        sourceRef = ABPersonCopySource(recordRef);
    } waitUntilDone:YES];
    
    RHSource *source = [_addressBook sourceForABRecordRef:sourceRef];    
    if (sourceRef) CFRelease(sourceRef);
    
    return arc_autorelease(arc_retain(source));
}


#pragma mark - linked people
-(NSArray*)linkedPeople{
    if (ABPersonCopyArrayOfAllLinkedPeople == NULL) return nil; //availability check
    
    NSMutableArray *linkedPeople = [NSMutableArray array];
    __block CFArrayRef linkedArrayRef = NULL;
    
    [self performRecordAction:^(ABRecordRef recordRef) {
        linkedArrayRef = ABPersonCopyArrayOfAllLinkedPeople(recordRef);
    } waitUntilDone:YES];
    
    if (linkedArrayRef){
        for (CFIndex i = 0; i < CFArrayGetCount(linkedArrayRef); i++) {
            ABRecordRef personRef = CFArrayGetValueAtIndex(linkedArrayRef, i);
            RHPerson *person = [_addressBook personForABRecordRef:personRef];
            [linkedPeople addObject:person];
        }
        
        CFRelease(linkedArrayRef);
    }

    return [NSArray arrayWithArray:linkedPeople];
}

#pragma mark - image
-(BOOL)hasImage{
    __block BOOL result = NO;
    [self performRecordAction:^(ABRecordRef recordRef) {
        result = ABPersonHasImageData(recordRef);
    } waitUntilDone:YES];
    return result;
}

-(UIImage*)thumbnail{
    return [self imageWithFormat:kABPersonImageFormatThumbnail];
}

-(UIImage*)originalImage{
    return [self imageWithFormat:kABPersonImageFormatOriginalSize];
}

-(UIImage*)imageWithFormat:(ABPersonImageFormat)imageFormat{
    NSData *imgData = [self imageDataWithFormat:imageFormat];
    
    UIImage *image = nil;
    if (imgData){
        image = [UIImage imageWithData:imgData];
    }
    return image;
}

-(NSData*)thumbnailData{
    return [self imageDataWithFormat:kABPersonImageFormatThumbnail];
}

-(NSData*)originalImageData{
    return [self imageDataWithFormat:kABPersonImageFormatOriginalSize];
}

-(NSData*)imageDataWithFormat:(ABPersonImageFormat)imageFormat{
    NSData *imageData = nil;
    
    __block CFDataRef dataRef = NULL;
    [self performRecordAction:^(ABRecordRef recordRef) {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 40100
        if (ABPersonCopyImageDataWithFormat != NULL){
            dataRef = ABPersonCopyImageDataWithFormat(recordRef, imageFormat);
        } else {
#endif
            //if not available, default to the pre-iOS 4 code.
            dataRef = ABPersonCopyImageData(_recordRef);
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 40100
        }
#endif
    } waitUntilDone:YES];
    
    if(dataRef){
        imageData = (__bridge NSData*)dataRef;
    }
    return arc_autorelease(imageData);
}


-(BOOL)setImage:(UIImage*)image{
    //extern bool ABPersonSetImageData(ABRecordRef person, CFDataRef imageData, CFErrorRef* error);
    __block CFErrorRef errorRef = NULL;
    __block BOOL result = NO;
    CFDataRef imageDataRef = (CFDataRef) ARCBridgingRetain(UIImagePNGRepresentation(image));
    [self performRecordAction:^(ABRecordRef recordRef) {
        result = ABPersonSetImageData(recordRef, imageDataRef, &errorRef);
    } waitUntilDone:YES];
    if (!result) {
        RHErrorLog(@"-[RHPerson %@] error:%@", NSStringFromSelector(_cmd), errorRef);
        if (errorRef) CFRelease(errorRef);
    }
    if (imageDataRef) CFRelease(imageDataRef);
    return result;
}

-(BOOL)removeImage{
    __block CFErrorRef errorRef = NULL;
    __block BOOL result = NO;
    [self performRecordAction:^(ABRecordRef recordRef) {
        result = ABPersonRemoveImageData(recordRef, &errorRef);
    } waitUntilDone:YES];
    if (!result) {
        RHErrorLog(@"-[RHPerson %@] error:%@", NSStringFromSelector(_cmd), errorRef);
        if (errorRef) CFRelease(errorRef);
    }
    return result;
}


#pragma mark - personal properties

-(NSString*)name{
    return [self.compositeName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

// kABPersonFirstNameProperty
-(NSString*)firstName{ 
    return [self getBasicValueForPropertyID:kABPersonFirstNameProperty];
}
-(void)setFirstName:(NSString*)firstName{
    NSError *error = nil;
    if (![self setBasicValue:(CFStringRef)firstName forPropertyID:kABPersonFirstNameProperty error:&error]){
        RHErrorLog(@"-[RHPerson %@] error:%@", NSStringFromSelector(_cmd), error);
    }
}

// kABPersonLastNameProperty
-(NSString*)lastName{ 
    return [self getBasicValueForPropertyID:kABPersonLastNameProperty];
}
-(void)setLastName:(NSString*)lastName{
    NSError *error = nil;
    if (![self setBasicValue:(CFStringRef)lastName forPropertyID:kABPersonLastNameProperty error:&error]){
        RHErrorLog(@"-[RHPerson %@] error:%@", NSStringFromSelector(_cmd), error);
    }
}


// kABPersonMiddleNameProperty
-(NSString*)middleName{
    return [self getBasicValueForPropertyID:kABPersonMiddleNameProperty];
}
-(void)setMiddleName:(NSString*)middleName{
    NSError *error = nil;
    if (![self setBasicValue:(CFStringRef)middleName forPropertyID:kABPersonMiddleNameProperty error:&error]){
        RHErrorLog(@"-[RHPerson %@] error:%@", NSStringFromSelector(_cmd), error);
    }
}


// kABPersonPrefixProperty
-(NSString*)prefix{
    return [self getBasicValueForPropertyID:kABPersonPrefixProperty];
}
-(void)setPrefix:(NSString*)prefix{
    NSError *error = nil;
    if (![self setBasicValue:(CFStringRef)prefix forPropertyID:kABPersonPrefixProperty error:&error]){
        RHErrorLog(@"-[RHPerson %@] error:%@", NSStringFromSelector(_cmd), error);
    }
}


// kABPersonSuffixProperty
-(NSString*)suffix{
    return [self getBasicValueForPropertyID:kABPersonSuffixProperty];
}
-(void)setSuffix:(NSString*)suffix{
    NSError *error = nil;
    if (![self setBasicValue:(CFStringRef)suffix forPropertyID:kABPersonSuffixProperty error:&error]){
        RHErrorLog(@"-[RHPerson %@] error:%@", NSStringFromSelector(_cmd), error);
    }
}


// kABPersonNicknameProperty
-(NSString*)nickname{
    return [self getBasicValueForPropertyID:kABPersonNicknameProperty];
}
-(void)setNickname:(NSString*)nickname{
    NSError *error = nil;
    if (![self setBasicValue:(CFStringRef)nickname forPropertyID:kABPersonNicknameProperty error:&error]){
        RHErrorLog(@"-[RHPerson %@] error:%@", NSStringFromSelector(_cmd), error);
    }
}


// kABPersonFirstNamePhoneticProperty
-(NSString*)firstNamePhonetic{
    return [self getBasicValueForPropertyID:kABPersonFirstNamePhoneticProperty];
}
-(void)setFirstNamePhonetic:(NSString*)firstNamePhonetic{
    NSError *error = nil;
    if (![self setBasicValue:(CFStringRef)firstNamePhonetic forPropertyID:kABPersonFirstNamePhoneticProperty error:&error]){
        RHErrorLog(@"-[RHPerson %@] error:%@", NSStringFromSelector(_cmd), error);
    }
}


// kABPersonLastNamePhoneticProperty
-(NSString*)lastNamePhonetic{
    return [self getBasicValueForPropertyID:kABPersonLastNamePhoneticProperty];
}
-(void)setLastNamePhonetic:(NSString*)lastNamePhonetic{
    NSError *error = nil;
    if (![self setBasicValue:(CFStringRef)lastNamePhonetic forPropertyID:kABPersonLastNamePhoneticProperty error:&error]){
        RHErrorLog(@"-[RHPerson %@] error:%@", NSStringFromSelector(_cmd), error);
    }
}


// kABPersonMiddleNamePhoneticProperty
-(NSString*)middleNamePhonetic{
    return [self getBasicValueForPropertyID:kABPersonMiddleNamePhoneticProperty];
}
-(void)setMiddleNamePhonetic:(NSString*)middleNamePhonetic{
    NSError *error = nil;
    if (![self setBasicValue:(CFStringRef)middleNamePhonetic forPropertyID:kABPersonMiddleNamePhoneticProperty error:&error]){
        RHErrorLog(@"-[RHPerson %@] error:%@", NSStringFromSelector(_cmd), error);
    }
}


// kABPersonOrganizationProperty
-(NSString*)organization{
    return [self getBasicValueForPropertyID:kABPersonOrganizationProperty];
}
-(void)setOrganization:(NSString*)organization{
    NSError *error = nil;
    if (![self setBasicValue:(CFStringRef)organization forPropertyID:kABPersonOrganizationProperty error:&error]){
        RHErrorLog(@"-[RHPerson %@] error:%@", NSStringFromSelector(_cmd), error);
    }
}


// kABPersonJobTitleProperty
-(NSString*)jobTitle{
    return [self getBasicValueForPropertyID:kABPersonJobTitleProperty];
}
-(void)setJobTitle:(NSString*)jobTitle{
    NSError *error = nil;
    if (![self setBasicValue:(CFStringRef)jobTitle forPropertyID:kABPersonJobTitleProperty error:&error]){
        RHErrorLog(@"-[RHPerson %@] error:%@", NSStringFromSelector(_cmd), error);
    }
}


// kABPersonDepartmentProperty
-(NSString*)department{
    return [self getBasicValueForPropertyID:kABPersonDepartmentProperty];
}
-(void)setDepartment:(NSString*)department{
    NSError *error = nil;
    if (![self setBasicValue:(CFStringRef)department forPropertyID:kABPersonDepartmentProperty error:&error]){
        RHErrorLog(@"-[RHPerson %@] error:%@", NSStringFromSelector(_cmd), error);
    }
}


// kABPersonEmailProperty - (Multi String) 
-(RHMultiStringValue*)emails{
    return [self getMultiValueForPropertyID:kABPersonEmailProperty];
}
-(void)setEmails:(RHMultiStringValue*)emails{
    NSError *error = nil;
    if (![self setMultiValue:emails forPropertyID:kABPersonEmailProperty error:&error]){
        RHErrorLog(@"-[RHPerson %@] error:%@", NSStringFromSelector(_cmd), error);
    }
}


// kABPersonBirthdayProperty
-(NSDate*)birthday{
    return [self getBasicValueForPropertyID:kABPersonBirthdayProperty];
}
-(void)setBirthday:(NSDate*)birthday{
    NSError *error = nil;
    if (![self setBasicValue:(CFDateRef)birthday forPropertyID:kABPersonBirthdayProperty error:&error]){
        RHErrorLog(@"-[RHPerson %@] error:%@", NSStringFromSelector(_cmd), error);
    }
}


// kABPersonNoteProperty
-(NSString*)note{
    return [self getBasicValueForPropertyID:kABPersonNoteProperty];
}
-(void)setNote:(NSString*)note{
    NSError *error = nil;
    if (![self setBasicValue:(CFStringRef)note forPropertyID:kABPersonNoteProperty error:&error]){
        RHErrorLog(@"-[RHPerson %@] error:%@", NSStringFromSelector(_cmd), error);
    }
}


// kABPersonCreationDateProperty (read only)
-(NSDate*)created{
    return [self getBasicValueForPropertyID:kABPersonCreationDateProperty];
}


// kABPersonModificationDateProperty (read only)
-(NSDate*)modified{
    return [self getBasicValueForPropertyID:kABPersonModificationDateProperty];
}


#pragma mark - Addresses
// kABPersonAddressProperty (multi dictionary)
-(RHMultiDictionaryValue*)addresses{
    return [self getMultiValueForPropertyID:kABPersonAddressProperty];
}
-(void)setAddresses:(RHMultiDictionaryValue*)addresses{
    NSError *error = nil;
    if (![self setMultiValue:addresses forPropertyID:kABPersonAddressProperty error:&error]){
        RHErrorLog(@"-[RHPerson %@] error:%@", NSStringFromSelector(_cmd), error);
    }
}


#pragma mark - Dates
// kABPersonDateProperty (multi date)
-(RHMultiDateTimeValue*)dates{
    return [self getMultiValueForPropertyID:kABPersonDateProperty];
}
-(void)setDates:(RHMultiDateTimeValue*)dates{
    NSError *error = nil;
    if (![self setMultiValue:dates forPropertyID:kABPersonDateProperty error:&error]){
        RHErrorLog(@"-[RHPerson %@] error:%@", NSStringFromSelector(_cmd), error);
    }
}


#pragma mark - Kind
// kABPersonKindProperty 
-(NSNumber*)kind{
    return [self getBasicValueForPropertyID:kABPersonKindProperty];
}
-(void)setKind:(NSNumber*)kind{
    NSError *error = nil;
    if (![self setBasicValue:(CFNumberRef)kind forPropertyID:kABPersonKindProperty error:&error]){
        RHErrorLog(@"-[RHPerson %@] error:%@", NSStringFromSelector(_cmd), error);
    }
}

// if person == kABPersonKindOrganization
-(BOOL)isOrganization{ return ([[self kind] isEqualToNumber:(NSNumber*)kABPersonKindOrganization]); }

// if person == kABPersonKindPerson
-(BOOL)isPerson{ return ([[self kind] isEqualToNumber:(NSNumber*)kABPersonKindPerson]); }


#pragma mark - Phone numbers
// kABPersonPhoneProperty (Multi String) 
-(RHMultiStringValue*)phoneNumbers{
    return [self getMultiValueForPropertyID:kABPersonPhoneProperty];
}
-(void)setPhoneNumbers:(RHMultiStringValue*)phoneNumbers{
    NSError *error = nil;
    if (![self setMultiValue:phoneNumbers forPropertyID:kABPersonPhoneProperty error:&error]){
        RHErrorLog(@"-[RHPerson %@] error:%@", NSStringFromSelector(_cmd), error);
    }
}


#pragma mark - IM
// kABPersonInstantMessageProperty - (Multi Dictionary)
-(RHMultiDictionaryValue*)instantMessageServices{
    return [self getMultiValueForPropertyID:kABPersonInstantMessageProperty];
}
-(void)setInstantMessageServices:(RHMultiDictionaryValue*)instantMessageServices{
    NSError *error = nil;
    if (![self setMultiValue:instantMessageServices forPropertyID:kABPersonInstantMessageProperty error:&error]){
        RHErrorLog(@"-[RHPerson %@] error:%@", NSStringFromSelector(_cmd), error);
    }
}


#pragma mark - URLs
// kABPersonURLProperty - (Multi String) 
-(RHMultiStringValue*)urls{
    return [self getMultiValueForPropertyID:kABPersonURLProperty];
}
-(void)setUrls:(RHMultiStringValue*)urls{
    NSError *error = nil;
    if (![self setMultiValue:urls forPropertyID:kABPersonURLProperty error:&error]){
        RHErrorLog(@"-[RHPerson %@] error:%@", NSStringFromSelector(_cmd), error);
    }
}


#pragma mark - Related Names (Relationships)
// kABPersonRelatedNamesProperty - (Multi String)
-(RHMultiStringValue*)relatedNames{
    return [self getMultiValueForPropertyID:kABPersonRelatedNamesProperty];
}
-(void)setRelatedNames:(RHMultiStringValue*)relatedNames{
    NSError *error = nil;
    if (![self setMultiValue:relatedNames forPropertyID:kABPersonRelatedNamesProperty error:&error]){
        RHErrorLog(@"-[RHPerson %@] error:%@", NSStringFromSelector(_cmd), error);
    }
}

//iOS5+ methods
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 50000

#pragma mark - Social Profile (iOS5 +)
// kABPersonSocialProfileProperty - (Multi Dictionary)
-(RHMultiDictionaryValue*)socialProfiles{
    if (&kABPersonSocialProfileProperty == NULL) return nil; //availability check
    return [self getMultiValueForPropertyID:kABPersonSocialProfileProperty];
}
-(void)setSocialProfiles:(RHMultiDictionaryValue*)socialProfiles{
    if (&kABPersonSocialProfileProperty == NULL) return; //availability check
    NSError *error = nil;
    if (![self setMultiValue:socialProfiles forPropertyID:kABPersonSocialProfileProperty error:&error]){
        RHErrorLog(@"-[RHPerson %@] error:%@", NSStringFromSelector(_cmd), error);
    }
}

#pragma mark - vCard formatting (iOS5 +)
-(NSData*)vCardRepresentation{
    if (ABPersonCreateVCardRepresentationWithPeople == NULL) return nil; //availability check
    __block CFDataRef vCardDataRef = NULL;
    [self performRecordAction:^(ABRecordRef recordRef) {
        vCardDataRef = ABPersonCreateVCardRepresentationWithPeople((__bridge CFArrayRef)[NSArray arrayWithObject:(__bridge id)(recordRef)]);
    } waitUntilDone:YES];
    
    if (vCardDataRef){
        NSData *vCardData = [(__bridge NSData*)vCardDataRef copy];
        CFRelease(vCardDataRef);
        return arc_autorelease(vCardData);
    }
    
    return nil;
}

+(NSData*)vCardRepresentationForPeople:(NSArray*)people{
    if (ABPersonCreateVCardRepresentationWithPeople == NULL) return nil; //availability check
    
    CFDataRef vCardDataRef = ABPersonCreateVCardRepresentationWithPeople((__bridge CFArrayRef)people);
    
    if (vCardDataRef){
        NSData *vCardData = [(__bridge NSData*)vCardDataRef copy];
        CFRelease(vCardDataRef);
        return arc_autorelease(vCardData);
    }
    
    return nil;
}

#pragma mark - geocoding (iOS5+)

#if RH_AB_INCLUDE_GEOCODING
-(CLPlacemark*)placemarkForAddressID:(ABMultiValueIdentifier)addressID{
    return [_addressBook placemarkForPerson:self addressID:addressID];
}

-(CLLocation*)locationForAddressID:(ABMultiValueIdentifier)addressID{
    return [_addressBook locationForPerson:self addressID:addressID];
}
#endif //end Geocoding

#endif //end iOS5+

#pragma mark - remove
-(BOOL)remove{
    return [_addressBook removePerson:self];
}

-(BOOL)hasBeenRemoved{
    __block BOOL result = NO;
    [_addressBook performAddressBookAction:^(ABAddressBookRef addressBookRef) {
        result = ( NULL == ABAddressBookGetPersonWithRecordID(addressBookRef, self.recordID));
    } waitUntilDone:YES];

    return result;
}

#pragma mark - composite name format
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000
-(ABPersonCompositeNameFormat)compositeNameFormat{
    __block ABPersonCompositeNameFormat format = [RHAddressBook compositeNameFormat];
    if (ABPersonGetCompositeNameFormatForRecord != NULL){
        [self performRecordAction:^(ABRecordRef recordRef) {
            format = ABPersonGetCompositeNameFormatForRecord(recordRef);
        } waitUntilDone:YES];
    }
    return format;
}
#endif //end iOS7+


@end
