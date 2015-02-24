//
//  RHGroup.m
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

#import "RHGroup.h"
#import "RHRecord_Private.h"

#import "RHAddressBook.h"
#import "RHPerson.h"
#import "RHSource.h"


@implementation RHGroup

#pragma mark - group creator methods
+(id)newGroupInSource:(RHSource*)source{
    ABRecordRef newGroupRef = ABGroupCreateInSource(source.recordRef);
    RHGroup *newGroup = nil;
    if (newGroupRef){
        newGroup = [[RHGroup alloc] initWithAddressBook:source.addressBook recordRef:newGroupRef];
        CFRelease(newGroupRef);        
    }
    
    return newGroup;
}

#pragma mark - properties
-(NSString*)name{
    return [self getBasicValueForPropertyID:kABGroupNameProperty];
}

-(void)setName:(NSString *)name{
    NSError *error = nil;
    if (![self setBasicValue:(CFStringRef)name forPropertyID:kABGroupNameProperty error:&error]){
        RHErrorLog(@"-[RHGroup %@] error:%@", NSStringFromSelector(_cmd), error);
    }
}

-(RHSource*)source{
    RHSource *result = nil;
    ABRecordRef source = ABGroupCopySource(_recordRef);
    if (source){
        result = [_addressBook sourceForABRecordRef:source];
        CFRelease(source);
    }
    return result;
}

-(NSInteger)count{
    return [[self members] count];
}

#pragma mark - add / remove
-(BOOL)addMember:(RHPerson*)person{
    if (person.addressBook != self.addressBook) return NO;

    __block BOOL success = NO;
    [self performRecordAction:^(ABRecordRef recordRef) {
        CFErrorRef errorRef = NULL;
        success = ABGroupAddMember(recordRef, person.recordRef, &errorRef);
        if (!success) {
            RHErrorLog(@"RHGroup: Error adding member. %@", errorRef);
            if (errorRef) CFRelease(errorRef);
        }
    } waitUntilDone:YES];
    return success;
}

-(BOOL)removeMember:(RHPerson*)person{
    __block BOOL success = NO;
    [self performRecordAction:^(ABRecordRef recordRef) {
        CFErrorRef errorRef = NULL;
        success = ABGroupRemoveMember(recordRef, person.recordRef, &errorRef);
        if (!success) {
            RHErrorLog(@"RHGroup: Error removing member. %@", errorRef);
            if (errorRef) CFRelease(errorRef);
        }
    } waitUntilDone:YES];
    return success;
}

-(void)removeAllMembers{
    NSArray *members = [self members];
    for (RHPerson *person in members) {
        [self removeMember:person];
    }
}


#pragma mark - access
-(NSArray*)members{
    NSMutableArray *members = [NSMutableArray array];
    __block CFArrayRef memberRefs = NULL;
    
    [self performRecordAction:^(ABRecordRef recordRef) {
        memberRefs = ABGroupCopyArrayOfAllMembers(recordRef);
    } waitUntilDone:YES];
    

    if (memberRefs){
        for (int i = 0; i < CFArrayGetCount(memberRefs); i++) {
            ABRecordRef memberRef = CFArrayGetValueAtIndex(memberRefs, i);
            
            RHPerson *person = [_addressBook personForABRecordRef:memberRef];
            if (person) {
                [members addObject:person];
            } else {
                RHLog(@"Failed to find member");
            }
        }
        
        CFRelease(memberRefs);
    }
    
    return [NSArray arrayWithArray:members];
    
}

-(NSArray*)membersOrderedBySortOrdering:(ABPersonSortOrdering)ordering{
    NSMutableArray *members = [NSMutableArray array];
    __block CFArrayRef memberRefs = nil;
    
    [self performRecordAction:^(ABRecordRef recordRef) {
        memberRefs = ABGroupCopyArrayOfAllMembersWithSortOrdering(recordRef, ordering);
    } waitUntilDone:YES];
    
    if (memberRefs){
        for (int i = 0; i < CFArrayGetCount(memberRefs); i++) {
            ABRecordRef memberRef = CFArrayGetValueAtIndex(memberRefs, i);
            
            RHPerson *person = [_addressBook personForABRecordRef:memberRef];
            if (person){
                [members addObject:person]; 
            } else {
                RHLog(@"Failed to find member");
            }
        }
        
        CFRelease(memberRefs);
    }
    
    return [NSArray arrayWithArray:members];
}

-(NSArray*)membersOrderedByFirstName{
    return [self membersOrderedBySortOrdering:kABPersonSortByFirstName];
}

-(NSArray*)membersOrderedByLastName{
    return [self membersOrderedBySortOrdering:kABPersonSortByLastName];
}

-(NSArray*)membersOrderedByUsersPreference{
    return [self membersOrderedBySortOrdering:[RHAddressBook sortOrdering]];
}


#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 50000
-(NSData*)vCardRepresentationForMembers{
    return [_addressBook vCardRepresentationForPeople:[self members]];
}

#if RH_AB_INCLUDE_GEOCODING
-(NSArray*)membersWithinDistance:(double)distance ofLocation:(CLLocation*)location{

    NSArray *allWithinDistance = [_addressBook peopleWithinDistance:distance ofLocation:location];
    NSArray *allMembers = [self members];

    NSIndexSet *inRangeMemberIndexes = [allWithinDistance indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        return [allMembers containsObject:obj];
    }];
    
    return [allWithinDistance objectsAtIndexes:inRangeMemberIndexes];
}
#endif // Geocoding

#endif //end iOS5+


#pragma mark - remove
-(BOOL)remove{
    return [_addressBook removeGroup:self];
}


#pragma mark - misc
-(NSString*)description{
    return [NSString stringWithFormat:@"<%@: %p> name:%@", NSStringFromClass([self class]), self, self.name];
}

@end
