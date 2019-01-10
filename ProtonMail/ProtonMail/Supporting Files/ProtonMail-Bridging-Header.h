//
//  ProtonMail-Bridging-Header.h
//  ProtonMail
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


#ifndef ProtonMail_ProtonMail_Bridging_Header_h
#define ProtonMail_ProtonMail_Bridging_Header_h

//new work
//#import <AFNetworking/AFNetworking.h>
//#import <AFNetworking/UIKit+AFNetworking.h>
//#import <AFNetworkActivityLogger.h>
//#import <AFNetworkActivityConsoleLogger.h>


#import <CommonCrypto/CommonCrypto.h>

//try catch objective-c
#import "SwiftTryCatch.h"

//1 password
#import "OnePasswordExtension.h"

//network check
#import "Reachability.h"

//localization
#import "LanguageManager.h"
#import "NSBundle+Language.h"

//pgp part
#import <OpenPGP/PMNOpenPgp.h>
#import <OpenPGP/PMNSrpClient.h>
#import <OpenPGP/PMNLibVersion.h>
#import <OpenPGP/PMNBCryptHash.h>

//vcard part
#import <OpenPGP/PMNIEzvcard.h>
#import <OpenPGP/PMNIVCard.h>
#import <OpenPGP/PMNIFormattedName.h>
#import <OpenPGP/PMNIVCardVersion.h>
#import <OpenPGP/PMNIOrganization.h>
#import <OpenPGP/PMNIAddress.h>
#import <OpenPGP/PMNITelephone.h>
#import <OpenPGP/PMNIEmail.h>
#import <OpenPGP/PMNICategories.h>
#import <OpenPGP/PMNIUrl.h>
#import <OpenPGP/PMNIUid.h>
#import <OpenPGP/PMNIStructuredName.h>
#import <OpenPGP/PMNINote.h>
#import <OpenPGP/PMNIPMCustom.h>
#import <OpenPGP/PMNINickname.h>
#import <OpenPGP/PMNITitle.h>
#import <OpenPGP/PMNIGender.h>
#import <OpenPGP/PMNIBirthday.h>
#import <OpenPGP/PMNIAnniversary.h>
#import <OpenPGP/PMNIPMSign.h>
#import <OpenPGP/PMNIPMEncrypt.h>
#import <OpenPGP/PMNIKey.h>
#import <OpenPGP/PMNIPMScheme.h>
#import <OpenPGP/PMNIPMMimeType.h>
#import <OpenPGP/PMNIPhoto.h>

#endif

// how the heck does it compile? Only extension targets have APP_EXTENSION flag, but the pod is installed only for main target. Even more strange things: without condition or with opposite condition, which seems more correct, ShareDev target, which this line should be excluded for, fails to compile cuz can not find this pod, which it should not use at all
// 🤯
#if APP_EXTENSION
#import <SWRevealViewController/SWRevealViewController.h>
#endif
