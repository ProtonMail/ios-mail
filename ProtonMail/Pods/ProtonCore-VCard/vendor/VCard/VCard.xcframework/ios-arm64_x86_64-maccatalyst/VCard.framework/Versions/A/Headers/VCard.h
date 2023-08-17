//
//  VCard.h
//  VCard
//
//  Created by Yanfeng Zhang on 3/3/21.
//  Copyright © 2021 Yanfeng Zhang. All rights reserved.
//

#import <Foundation/Foundation.h>

//! Project version number for OpenPGP.
FOUNDATION_EXPORT double VCardVersionNumber;

//! Project version string for OpenPGP.
FOUNDATION_EXPORT const unsigned char VCardVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <OpenPGP/PublicHeader.h>


//
////pgp part
//#include <OpenPGP/PMNOpenPgp.h>
//#include <OpenPGP/PMNSrpClient.h>
//#include <OpenPGP/PMNLibVersion.h>
//#include <OpenPGP/PMNBCryptHash.h>
//
//vcard part
#import "PMNIEzvcard.h"
#import "PMNIVCard.h"
#import "PMNIFormattedName.h"
#import "PMNIVCardVersion.h"
#import "PMNIOrganization.h"
#import "PMNIAddress.h"
#import "PMNITelephone.h"
#import "PMNIEmail.h"
#import "PMNICategories.h"
#import "PMNIUrl.h"
#import "PMNIUid.h"
#import "PMNIStructuredName.h"
#import "PMNINote.h"
#import "PMNIPMCustom.h"
#import "PMNINickname.h"
#import "PMNITitle.h"
#import "PMNIGender.h"
#import "PMNIBirthday.h"
#import "PMNIAnniversary.h"
#import "PMNIPMSign.h"
#import "PMNIPMEncrypt.h"
#import "PMNIKey.h"
#import "PMNIPMScheme.h"
#import "PMNIPMMimeType.h"
#import "PMNIPhoto.h"
