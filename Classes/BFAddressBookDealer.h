//
//  BFAddressBookDealer.h
//  mrimSMSm
//
//  Created by Алексеев Влад on 14.06.10.
//  Copyright 2010 МИИТ. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AddressBook/AddressBook.h>

@interface BFAddressBookDealer : NSObject {
	ABAddressBookRef addressBookRef;
	
	NSMutableDictionary *contactListPhones;
	NSMutableDictionary *contactListImages;
	
	UIImage *photoPlaceholder;
}

+ (BFAddressBookDealer *)sharedDealer;

- (UIImage *)imageByScalingAndCroppingForSize:(CGSize)targetSize fromImage:(UIImage *)image;

- (UIImage *)imageForPhone:(NSString *)phoneNumber;
- (NSString *)cleanPhoneNumberForString:(NSString *)dirtyPhoneNumber;
- (NSString *)fullNameForPhone:(NSString *)phoneNumber withAlternativeText:(NSString *)text;
- (NSString *)fullNameForFirstName:(NSString *)firstname andLastName:(NSString *)lastname;

@end
