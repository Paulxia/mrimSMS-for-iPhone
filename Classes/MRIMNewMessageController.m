//
//  MRIMNewMessageController.m
//  mrimSMSmobile
//
//  Created by Алексеев Влад on 20.10.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MRIMNewMessageController.h"
#import <AddressBookUI/AddressBookUI.h>
#import "MRIMRecentNumbersViewController.h"

#import "BFAddressBookDealer.h"
#import "BFConnectionController.h"
#import "BFHistoryStorage.h"

@implementation MRIMNewMessageController

@synthesize appDelegate;
@synthesize historyViewController;

- (void)viewDidLoad {
    [super viewDidLoad];
	sendMessageButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"mSendButton", nil)
														 style:UIBarButtonItemStyleDone 
														target:self
														action:@selector(sendMessage)];
	cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel 
																 target:self 
																 action:@selector(cancelButtonPress)];
	
	[[self navigationItem] setRightBarButtonItem:sendMessageButton];
	[[self navigationItem] setLeftBarButtonItem:cancelButton];
	
	[[self navigationItem] setTitle:NSLocalizedString(@"mNewMessage", nil)];
	[phoneNumberField becomeFirstResponder];
	
	[self registerForTextNotifications];
	
	[messageTextView setFont:[UIFont systemFontOfSize:15]];
	
	[self textDidChange:[NSNotification notificationWithName:UITextViewTextDidChangeNotification object:nil]];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	UIEdgeInsets insets;
	if (UIInterfaceOrientationIsPortrait(interfaceOrientation)) {
		insets = UIEdgeInsetsMake(20, 0, 161, 0);
		[messageTextView setContentInset:insets];
		[messageTextView setScrollIndicatorInsets:insets];
		[messageInfoView setHidden:NO];
	}
	else {
		insets = UIEdgeInsetsMake(0, 0, 161, 0);
		[messageTextView setContentInset:insets];
		[messageTextView setScrollIndicatorInsets:insets];
		[messageInfoView setHidden:YES];
	}

	
	if (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown) {
		return YES;
	}
    return NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}

#pragma mark -
#pragma mark Actions

-(void)registerForTextNotifications
{
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(textDidChange:) 
												 name:UITextFieldTextDidChangeNotification
											   object:phoneNumberField];
	
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(textDidChange:) 
												 name:UITextViewTextDidChangeNotification
											   object:messageTextView];
}

#pragma mark Enviroment methods

-(void)setPersonName:(NSString *)name phoneNumber:(NSString *)phone message:(NSString *)message photo:(UIImage *)photo
{
	[personNameLabel setText:name];
	[personPhoto setImage:photo];
	[phoneNumberField setText:phone];
	[messageTextView setText:message];
}

-(void)setPersonNameFieldText {
	NSString *phoneNumber = [[BFAddressBookDealer sharedDealer] cleanPhoneNumberForString:[phoneNumberField text]];
	[personNameLabel setText:[[BFAddressBookDealer sharedDealer] fullNameForPhone:phoneNumber
															  withAlternativeText:@""]];
	[personPhoto setImage:[[BFAddressBookDealer sharedDealer] imageForPhone:[phoneNumberField text]]];
}

#pragma mark Action


- (void)cancelButtonPress {
	[[[self navigationController] parentViewController] dismissModalViewControllerAnimated:YES];
}

-(void)sendMessage {
	NSString *phoneNumber = [phoneNumberField text];
	NSString *messageText = [messageTextView text];
	
	if ([phoneNumber isEqualToString:@"+"]) {
		[phoneNumberField becomeFirstResponder];
		return;
	}
	
	if ([messageText length] > 0) {
		[[BFConnectionController sharedController] sendMessage:messageText toNumber:phoneNumber];
		[[BFHistoryStorage sharedStorage] insertToHistoryNumber:phoneNumber 
														message:messageText 
														 atDate:[NSDate date] 
														 income:NO 
														 unread:NO];
		
		[[[self navigationController] parentViewController] dismissModalViewControllerAnimated:YES];
		
	}
	else {
		[messageTextView becomeFirstResponder];
	}
}

#pragma mark InterfaceBuilder Actions

- (IBAction)pickPhoneNumber:(id)sender {
	MRIMRecentNumbersViewController *recentNumbersViewController = [[MRIMRecentNumbersViewController alloc] init];
	[recentNumbersViewController setDelegate:self];
	[[self navigationController] presentModalViewController:recentNumbersViewController animated:YES];
	[recentNumbersViewController release];
}

#pragma mark -
#pragma mark RecentNumbersViewControllerDelegate methods

- (void)recentNumbersControllerDidCancel:(MRIMRecentNumbersViewController *)controller {
	[self.navigationController dismissModalViewControllerAnimated:YES];
}

- (void)recentNumbersControllerDidProceedToAddressBook:(MRIMRecentNumbersViewController *)controller {
	[self.navigationController dismissModalViewControllerAnimated:NO];
	ABPeoplePickerNavigationController *picker = [[ABPeoplePickerNavigationController alloc] init];
	picker.peoplePickerDelegate = self;
	[self.navigationController presentModalViewController:picker animated:NO];
	[picker release];
}

- (void)recentNumbersController:(MRIMRecentNumbersViewController *)controller didPickPhoneNumber:(NSString *)phoneNumber {
	[phoneNumberField setText:phoneNumber];
	[self setPersonNameFieldText];
	[self.navigationController dismissModalViewControllerAnimated:YES];
	[messageTextView becomeFirstResponder];
}

#pragma mark -
#pragma mark AddressBookUI methods

- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker
{
	[[self navigationController] dismissModalViewControllerAnimated:YES];
	[self setPersonNameFieldText];
	[messageTextView becomeFirstResponder];
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker 
	  shouldContinueAfterSelectingPerson:(ABRecordRef)person 
								property:(ABPropertyID)property 
							  identifier:(ABMultiValueIdentifier)identifier {
	if (property == kABPersonPhoneProperty) {
		ABMultiValueRef container = ABRecordCopyValue(person, property);
		CFStringRef contactData = ABMultiValueCopyValueAtIndex(container, identifier);
		CFRelease(container);
		NSString *contactString = [NSString stringWithString:(NSString *)contactData];
		CFRelease(contactData);
		[phoneNumberField setText:[[BFAddressBookDealer sharedDealer] cleanPhoneNumberForString:contactString]];
		[self setPersonNameFieldText];
		[[self navigationController] dismissModalViewControllerAnimated:YES];
		[messageTextView becomeFirstResponder];
	}
	return NO;
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker 
	  shouldContinueAfterSelectingPerson:(ABRecordRef)person {
	return YES;
}

#pragma mark -
#pragma mark Text fields delegates and Notifications

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range 
replacementString:(NSString *)string {
	if (range.location == 0)
		return NO;
	
	if (textField.text.length >= 13 && range.length == 0)
		return NO;
	return YES;
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range 
 replacementText:(NSString *)text
{
	NSInteger usernameLen = [[[NSUserDefaults standardUserDefaults] valueForKey:@"email_preference"] length] + 1;
	NSInteger allowedLen = 0;
	
	NSCharacterSet *russianSet = [NSCharacterSet characterSetWithCharactersInString:@"йцукенгшщзхъфывапролджэёячсмитьбю"];
	NSRange russianCharsRange = [[messageTextView text] rangeOfCharacterFromSet:russianSet options:NSCaseInsensitiveSearch];
	if (russianCharsRange.location != NSNotFound)
		allowedLen = 67 - usernameLen;
	else
		allowedLen = 150 - usernameLen;

	if (textView.text.length >= allowedLen && range.length == 0)
		return NO;
	return YES;
}

- (void)textDidChange:(NSNotification *)note 
{
	if (note.name == UITextViewTextDidChangeNotification)
	{
		// текст сообщения поменялся
		NSInteger usernameLen = [[[NSUserDefaults standardUserDefaults] valueForKey:@"email_preference"] length] + 1;
		NSInteger messageLen = [[messageTextView text] length];
		NSInteger resultLen = usernameLen + messageLen;
		[messageLengthLabel setText:[NSString stringWithFormat:@"%d", resultLen]];
	}
	
	if (note.name == UITextFieldTextDidChangeNotification)
	{
		// текст телефона поменялся
		[self setPersonNameFieldText];
	}
}


@end
