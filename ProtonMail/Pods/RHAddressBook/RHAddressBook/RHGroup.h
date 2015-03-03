//
//  RHGroup.h
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

@class RHPerson;
@class RHSource;
@class CLLocation;

//To create a new empty instance of a group use -[RHAddressBook createGroup] or -[RHSource createGroup]
@interface RHGroup : RHRecord

//once a group object is created using a given source object from an ab instance, its not safe to use that object with any other instance of the addressbook
+(id)newGroupInSource:(RHSource*)source;

//properties
@property (copy) NSString *name;
@property (retain, readonly) RHSource *source;
@property (readonly) NSInteger count;

//add and remove members from this group
-(BOOL)addMember:(RHPerson*)person;
-(BOOL)removeMember:(RHPerson*)person;
-(void)removeAllMembers;

//access group members
-(NSArray*)members;
-(NSArray*)membersOrderedBySortOrdering:(ABPersonSortOrdering)ordering;
-(NSArray*)membersOrderedByFirstName;
-(NSArray*)membersOrderedByLastName;
-(NSArray*)membersOrderedByUsersPreference;

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 50000
//vCard (iOS5+) pre iOS5 this method is a no-op
-(NSData*)vCardRepresentationForMembers;

#if RH_AB_INCLUDE_GEOCODING
//geolocation
-(NSArray*)membersWithinDistance:(double)distance ofLocation:(CLLocation*)location;
#endif // Geocoding

#endif //end iOS5+

//remove group from addressBook
-(BOOL)remove;


@end
