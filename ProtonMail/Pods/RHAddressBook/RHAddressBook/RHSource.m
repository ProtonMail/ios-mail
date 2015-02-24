//
//  RHSource.m
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

#import "RHSource.h"

#import "RHAddressBook.h"
#import "NSThread+RHBlockAdditions.h"

@implementation RHSource 

-(NSString*)name{
    NSString *sourceName = [self getBasicValueForPropertyID:kABSourceNameProperty];
    return sourceName;
}

-(ABSourceType)type{
   NSNumber *sourceType = [self getBasicValueForPropertyID:kABSourceTypeProperty];
    return [sourceType intValue];
}

//groups
-(NSArray*)groups{
    return [_addressBook groupsInSource:self];
}


//people
-(NSArray*)people{

    NSMutableArray *people = [NSMutableArray array];
    
    [_addressBook performAddressBookAction:^(ABAddressBookRef addressBookRef) {
        
        CFArrayRef peopleRefs = ABAddressBookCopyArrayOfAllPeopleInSource(addressBookRef, _recordRef);

        if (peopleRefs){
            for (CFIndex i = 0; i < CFArrayGetCount(peopleRefs); i++) {
                ABRecordRef personRef = CFArrayGetValueAtIndex(peopleRefs, i);
                RHPerson *person = [_addressBook personForABRecordRef:personRef]; // this method either pulls from the old cache or creates a new object
                if (person)[people addObject:person];
            }
            
            CFRelease(peopleRefs);
        }
    } waitUntilDone:YES];
    
    return [NSArray arrayWithArray:people];
}

-(NSArray*)peopleOrderedBySortOrdering:(ABPersonSortOrdering)ordering{
    NSMutableArray *people = [NSMutableArray array];
    
    [_addressBook performAddressBookAction:^(ABAddressBookRef addressBookRef) {
        
        CFArrayRef peopleRefs = ABAddressBookCopyArrayOfAllPeopleInSourceWithSortOrdering(addressBookRef, _recordRef, ordering);

        if (peopleRefs){
            for (CFIndex i = 0; i < CFArrayGetCount(peopleRefs); i++) {
                ABRecordRef personRef = CFArrayGetValueAtIndex(peopleRefs, i);
                RHPerson *person = [_addressBook personForABRecordRef:personRef]; // this method either pulls from the old cache or creates a new object
                if (person)[people addObject:person];
            }
            
            CFRelease(peopleRefs);
        }
    } waitUntilDone:YES];
    
    return [NSArray arrayWithArray:people];
}

-(NSArray*)peopleOrderedByFirstName{
    return [self peopleOrderedBySortOrdering:kABPersonSortByFirstName];
}

-(NSArray*)peopleOrderedByLastName{
    return [self peopleOrderedBySortOrdering:kABPersonSortByLastName];
}

-(NSArray*)peopleOrderedByUsersPreference{
    return [self peopleOrderedBySortOrdering:[RHAddressBook sortOrdering]];
}


//additions
-(RHPerson*)newPerson{
    return [_addressBook newPersonInSource:self];
}

-(RHGroup*)newGroup{
    return [_addressBook newGroupInSource:self];
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 50000
#pragma mark - vCard (iOS5+)
-(NSArray*)addPeopleFromVCardRepresentation:(NSData*)representation{
    return [_addressBook addPeopleFromVCardRepresentation:representation toSource:self];
}

-(NSData*)vCardRepresentationForPeople{
    return [_addressBook vCardRepresentationForPeople:[self people]];
}

#endif //end iOS5+


-(NSString*)description{
    return [NSString stringWithFormat:@"<%@: %p> name:%@ type:%i", NSStringFromClass([self class]), self, self.name, self.type];
}


@end
