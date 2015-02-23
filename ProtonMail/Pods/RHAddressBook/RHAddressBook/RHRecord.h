//
//  RHRecord.h
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

@class RHAddressBook;
@class RHMultiValue;

@interface RHRecord : NSObject{
    ABRecordID _recordID;
    __strong RHAddressBook *_addressBook; //strong, we don't want our addressbook instance going away while we are still alive. ever.
    ABRecordRef _recordRef;
}

//thread safe access block
-(void)performRecordAction:(void (^)(ABRecordRef recordRef))actionBlock waitUntilDone:(BOOL)wait;

//accessors
@property (retain, readonly) RHAddressBook* addressBook; // address book instance that this record is a member of

@property (readonly) ABRecordID recordID;
@property (readonly) ABRecordRef recordRef;
@property (readonly) ABRecordType recordType;
@property (copy, readonly) NSString *compositeName;

//generic property accessors (only safe for toll free bridged values)
-(id)getBasicValueForPropertyID:(ABPropertyID)propertyID;
-(BOOL)setBasicValue:(CFTypeRef)value forPropertyID:(ABPropertyID)propertyID error:(NSError**)error;
-(BOOL)unsetBasicValueForPropertyID:(ABPropertyID)propertyID error:(NSError**)error;


//multi value accessors
-(RHMultiValue*)getMultiValueForPropertyID:(ABPropertyID)propertyID; //returned multi's are always immutable, if you want to edit use -[RHMultiValue mutableCopy]
-(BOOL)setMultiValue:(RHMultiValue*)multiValue forPropertyID:(ABPropertyID)propertyID error:(NSError**)error;
-(BOOL)unsetMultiValueForPropertyID:(ABPropertyID)propertyID error:(NSError**)error;



//save (convenience methods.. these just forward up to this records addressbook)
-(BOOL)save;
-(BOOL)saveWithError:(NSError**)error;
-(BOOL)hasUnsavedChanges; //addressbook level, not record level
-(void)revert;

//misc
+(NSString*)descriptionForRecordType:(ABRecordType)type;
+(NSString*)descriptionForPropertyType:(ABRecordType)type;

@end
