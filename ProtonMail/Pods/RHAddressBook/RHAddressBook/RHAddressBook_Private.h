//
//  RHAddressBook_Private.h
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

#import "RHAddressBook.h"

@class RHRecord;
@interface RHAddressBook ()

//used by RHRecord objects upon  init / dealloc, so that the addressbook class is made aware of an object being created or destroyed and can add/remove it from its weakly linked cache
-(void)_recordCheckIn:(RHRecord*)record;
-(void)_recordCheckOut:(RHRecord*)record;

@property (nonatomic, readonly) dispatch_queue_t addressBookQueue; //serial queue for thread safety.

@end

//use this, in combination with  addressBookQueue for thread safety when messing with the ab directly
extern void rh_dispatch_sync_for_addressbook(RHAddressBook *addressbook, dispatch_block_t block);

//returns YES if currently being executed on the addressbooks addressBookQueue, otherwise NO.
extern BOOL rh_dispatch_is_current_queue_for_addressbook(RHAddressBook *addressBook);



