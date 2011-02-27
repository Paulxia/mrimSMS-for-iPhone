//
//  BFAddressBookDealer.m
//  mrimSMSm
//
//  Created by Алексеев Влад on 14.06.10.
//  Copyright 2010 МИИТ. All rights reserved.
//

#import "BFAddressBookDealer.h"


@implementation BFAddressBookDealer

static BFAddressBookDealer *sharedDealer = nil;

+ (BFAddressBookDealer *)sharedDealer {
    if (sharedDealer == nil) {
        sharedDealer = [[super allocWithZone:NULL] init];
    }
    return sharedDealer;
}

+ (id)allocWithZone:(NSZone *)zone {
    return [[self sharedDealer] retain];
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (id)retain {
    return self;
}

- (NSUInteger)retainCount {
    return NSUIntegerMax;  //denotes an object that cannot be released
}

- (void)release {
    //do nothing
}

- (void)dealloc {
	[contactListImages release];
	[contactListPhones release];
	if (addressBookRef != NULL)
		CFRelease(addressBookRef);
	
	[photoPlaceholder release];
	
	[super dealloc];
}

- (id)autorelease {
    return self;
}

#pragma mark -
#pragma mark AddressBook

- (UIImage *)photoPlaceholder {
	if (photoPlaceholder == nil) {
		photoPlaceholder = [[UIImage imageNamed:@"unknownContact.png"] retain];
	}
	return photoPlaceholder;
}

- (NSString *)cleanPhoneNumberForString:(NSString *)phone 
{
	if (phone == nil) 
		return @"+";
	
	if ([phone isEqualToString:@""])
		return @"+";
	
	NSMutableString *selectedPhoneNumber = [NSMutableString stringWithString:phone];
	
	if ([selectedPhoneNumber hasPrefix:@"810"]) {
		selectedPhoneNumber = [NSMutableString stringWithFormat:@"+%@", [selectedPhoneNumber substringFromIndex:3]];
		selectedPhoneNumber = [NSMutableString stringWithString:selectedPhoneNumber];
	}
	if ([selectedPhoneNumber hasPrefix:@"8"]) {
		NSString *defaultPrefixReplacement = [[NSUserDefaults standardUserDefaults] valueForKey:@"eight_replacement"];
		if ((defaultPrefixReplacement == nil) || ([defaultPrefixReplacement isEqualToString:@""])) {
			defaultPrefixReplacement = @"+7";
			[[NSUserDefaults standardUserDefaults] setValue:@"+7" forKey:@"eight_replacement"];
			[[NSUserDefaults standardUserDefaults] synchronize];
		}
		selectedPhoneNumber = [NSMutableString stringWithFormat:@"%@%@", defaultPrefixReplacement, [selectedPhoneNumber substringFromIndex:1]];
		selectedPhoneNumber = [NSMutableString stringWithString:selectedPhoneNumber];
	}
	
	[selectedPhoneNumber replaceOccurrencesOfString:@" " 
										 withString:@"" 
											options:NSCaseInsensitiveSearch 
											  range:NSMakeRange(0, [selectedPhoneNumber length])];
	if ([selectedPhoneNumber length] < 12)
	{
		return @"+";
	}
	[selectedPhoneNumber replaceOccurrencesOfString:@"-" 
										 withString:@"" 
											options:NSCaseInsensitiveSearch 
											  range:NSMakeRange(0, [selectedPhoneNumber length])];
	if ([selectedPhoneNumber length] < 12)
	{
		return @"+";
	}
	[selectedPhoneNumber replaceOccurrencesOfString:@"(" 
										 withString:@"" 
											options:NSCaseInsensitiveSearch 
											  range:NSMakeRange(0, 12)];
	if ([selectedPhoneNumber length] < 12)
	{
		return @"+";
	}
	[selectedPhoneNumber replaceOccurrencesOfString:@")" 
										 withString:@"" 
											options:NSCaseInsensitiveSearch 
											  range:NSMakeRange(0, 12)];
	if ([selectedPhoneNumber length] < 12)
	{
		return @"+";
	}
	NSRange braketsRange = [selectedPhoneNumber rangeOfString:@"("];
	if (braketsRange.location != NSNotFound)
	{
		selectedPhoneNumber = [NSMutableString stringWithString:[selectedPhoneNumber substringToIndex:braketsRange.location]];
	}
	if ([selectedPhoneNumber length] < 12)
	{
		return @"+";
	}
	
	@try {
		NSInteger phoneNumberLength;
		phoneNumberLength = [selectedPhoneNumber length];
		if (phoneNumberLength > 13)
			phoneNumberLength = 13;
		selectedPhoneNumber = (NSMutableString *)[selectedPhoneNumber substringToIndex:phoneNumberLength];
	}
	@catch (NSException *e) {
		selectedPhoneNumber = (NSMutableString *)@"+";
	}
	
	return (NSString *)selectedPhoneNumber;
}

- (UIImage *)imageForPhone:(NSString *)ph
{
	if (contactListImages == nil) 
		contactListImages = [[NSMutableDictionary alloc] init];
	
	UIImage *currentStoredImage = [contactListImages objectForKey:ph];
	if (currentStoredImage == nil) {
		if (addressBookRef == NULL)
			addressBookRef = ABAddressBookCreate(); 
		
		CFArrayRef allPeople = ABAddressBookCopyArrayOfAllPeople(addressBookRef);  // все записи
		
		CFIndex nPeople = ABAddressBookGetPersonCount(addressBookRef);  // число контактов
		
		NSInteger i = 0;
		BOOL found = NO;
		while ((i < nPeople) && (!found))
		{
			ABRecordRef ref = CFArrayGetValueAtIndex(allPeople, i);  // человек
			CFStringRef allPhonesRef = ABRecordCopyValue(ref,kABPersonPhoneProperty);	// все телефоны
			CFIndex nPhones = ABMultiValueGetCount(allPhonesRef);	// число телефонов
			NSInteger currentPhone = 0;
			for (currentPhone = 0; currentPhone < nPhones; currentPhone++) 
			{
				CFStringRef currentPhoneNumber = ABMultiValueCopyValueAtIndex(allPhonesRef, currentPhone);
				NSString *currentCleanPhoneNumber = [self cleanPhoneNumberForString:[NSString stringWithFormat:@"%@", currentPhoneNumber]];
				
				if (![currentCleanPhoneNumber isEqualToString:@"+"]) 
				{
					if ([currentCleanPhoneNumber isEqualToString:ph]) {
						CFDataRef imageDataRef = ABPersonCopyImageData(ref);
						UIImage *contactImage;
						if (imageDataRef != NULL) {
							contactImage = [UIImage imageWithData:(NSData *)imageDataRef];
							CFRelease(imageDataRef);
						}
						else {
							contactImage = [self photoPlaceholder];
						}
						
						[contactListImages setObject:[self imageByScalingAndCroppingForSize:CGSizeMake(48, 48) fromImage:contactImage] 
											  forKey:currentCleanPhoneNumber];
						found = YES;
					}
				}
				
				CFRelease(currentPhoneNumber);
			}
			CFRelease(allPhonesRef);
			i++;
		}
		CFRelease(allPeople);
	}
	
	UIImage *imageToReturn = nil;
	imageToReturn = [contactListImages objectForKey:ph];
	if (imageToReturn == nil) {
		imageToReturn = [self photoPlaceholder];
	}
	
	return imageToReturn;
}

-(NSString *)fullNameForPhone:(NSString *)ph withAlternativeText:(NSString *)text
{
	if (contactListPhones == nil) {
		contactListPhones = [[NSMutableDictionary alloc] init];
		
		if (addressBookRef == NULL)
			addressBookRef = ABAddressBookCreate(); 
		
		CFArrayRef allPeopleRef = ABAddressBookCopyArrayOfAllPeople(addressBookRef);  // все записи
		CFIndex nPeople = ABAddressBookGetPersonCount(addressBookRef);  // число контактов
		
		int i = 0;
		
		while (i < nPeople)
		{
			ABRecordRef recordRef = CFArrayGetValueAtIndex(allPeopleRef, i);  // человек
			CFStringRef allRecordPhonesRef = ABRecordCopyValue(recordRef, kABPersonPhoneProperty);	// все телефоны
			CFIndex nPhones = ABMultiValueGetCount(allRecordPhonesRef);	// число телефонов
			NSInteger currentPhone = 0;
			for (currentPhone = 0; currentPhone < nPhones; currentPhone++) 
			{
				CFStringRef currentPhoneNumberRef = ABMultiValueCopyValueAtIndex(allRecordPhonesRef, currentPhone);
				NSString *currentCleanPhoneNumber = [self cleanPhoneNumberForString:(NSString *)currentPhoneNumberRef];
				if (currentPhoneNumberRef != NULL)
				{
					CFRelease(currentPhoneNumberRef);
				}
				
				CFStringRef firstName = ABRecordCopyValue(recordRef, kABPersonFirstNameProperty);
				CFStringRef lastName = ABRecordCopyValue(recordRef, kABPersonLastNameProperty);
				NSString *fullName = [self fullNameForFirstName:(NSString *)firstName 
													andLastName:(NSString *)lastName];
				
				if (firstName != NULL)
					CFRelease(firstName);
				if (lastName != NULL)
					CFRelease(lastName);
				
				if (![currentCleanPhoneNumber isEqualToString:@"+"]) {
					[contactListPhones setObject:fullName forKey:currentCleanPhoneNumber];
				}
			}
			
			CFRelease(allRecordPhonesRef);
			i++;
		}
		CFRelease(allPeopleRef);
	}
	
	NSString *fname = [contactListPhones objectForKey:ph];
	if (fname == nil) {
		return text;
	}
	
	return fname;
}

-(NSString *)fullNameForFirstName:(NSString *)fn andLastName:(NSString *)ln
{
	NSString *senderName = nil;
	
	if ((ln != NULL) && (fn != NULL))
		senderName = [NSString stringWithFormat:@"%@ %@", ln, fn];
	if ((ln == NULL) && (fn != NULL))
		senderName = [NSString stringWithFormat:@"%@", fn];
	if ((ln != NULL) && (fn == NULL))
		senderName = [NSString stringWithFormat:@"%@", ln];
	if ((ln == NULL) && (fn == NULL))
		senderName = @"";
	return senderName;
}

- (UIImage *)imageWithImage:(UIImage*)image scaledToSize:(CGSize)newSize {
	UIGraphicsBeginImageContext( newSize );
	[image drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
	UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	return newImage;
}

- (UIImage*)imageByScalingAndCroppingForSize:(CGSize)targetSize fromImage:(UIImage *)image
{
	UIImage *sourceImage = image;
	UIImage *newImage = nil;        
	CGSize imageSize = sourceImage.size;
	CGFloat width = imageSize.width;
	CGFloat height = imageSize.height;
	CGFloat targetWidth = targetSize.width;
	CGFloat targetHeight = targetSize.height;
	CGFloat scaleFactor = 0.0;
	CGFloat scaledWidth = targetWidth;
	CGFloat scaledHeight = targetHeight;
	CGPoint thumbnailPoint = CGPointMake(0.0,0.0);
	
	if (CGSizeEqualToSize(imageSize, targetSize) == NO) 
	{
        CGFloat widthFactor = targetWidth / width;
        CGFloat heightFactor = targetHeight / height;
		
        if (widthFactor > heightFactor) 
			scaleFactor = widthFactor;
        else
			scaleFactor = heightFactor;
        scaledWidth  = width * scaleFactor;
        scaledHeight = height * scaleFactor;
		
        if (widthFactor > heightFactor)
		{
			thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5; 
		}
        else 
			if (widthFactor < heightFactor)
			{
				thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
			}
	}       
	
	UIGraphicsBeginImageContext(targetSize);
	
	CGRect thumbnailRect = CGRectZero;
	thumbnailRect.origin = thumbnailPoint;
	thumbnailRect.size.width  = scaledWidth;
	thumbnailRect.size.height = scaledHeight;
	
	[sourceImage drawInRect:thumbnailRect];
	
	newImage = UIGraphicsGetImageFromCurrentImageContext();
	if(newImage == nil) 
        NSLog(@"could not scale image");
	
	UIGraphicsEndImageContext();
	return newImage;
}

@end
