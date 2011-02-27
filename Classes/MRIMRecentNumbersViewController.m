//
//  MRIMRecentNumbersViewController.m
//  mrimSMSm
//
//  Created by Алексеев Влад on 16.12.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MRIMRecentNumbersViewController.h"

#import "BFAddressBookDealer.h"
#import "BFHistoryStorage.h"

@implementation MRIMRecentNumbersViewController

@synthesize tableView;
@synthesize phoneNumbers;
@synthesize delegate;

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
    }
    return self;
}
*/

- (void)viewDidLoad {
    [super viewDidLoad];
	[[navigationBar topItem] setTitle:NSLocalizedString(@"mRecentNumbersTitle", nil)];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	if (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown) {
		return YES;
	}
    return NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
	self.phoneNumbers = nil;
}


- (void)dealloc {
    [super dealloc];
}

#pragma mark -
#pragma mark tableView Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	[self setPhoneNumbers:[[[BFHistoryStorage sharedStorage] historyPhoneNumbers] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)]];
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [[self phoneNumbers] count];
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *nameCellID = @"nameCellID";
	static NSString *phoneCellID = @"phoneCellID";
	
	NSString *phoneNumber = [[self phoneNumbers] objectAtIndex:indexPath.row];
	NSString *contactName = [[BFAddressBookDealer sharedDealer] fullNameForPhone:phoneNumber 
															 withAlternativeText:phoneNumber];
	UIImage *contactImage = [[BFAddressBookDealer sharedDealer] imageForPhone:phoneNumber];
	
	UITableViewCell *cell = nil;
	
	if (phoneNumber == contactName) {
		cell = [[self tableView] dequeueReusableCellWithIdentifier:phoneCellID];
		
		if (cell == nil) {
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault 
										   reuseIdentifier:phoneCellID] autorelease];
		}
	}
	else {
		cell = [[self tableView] dequeueReusableCellWithIdentifier:nameCellID];
		
		if (cell == nil) {
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle 
										   reuseIdentifier:nameCellID] autorelease];
		}
		[[cell detailTextLabel] setText:phoneNumber];
	}
	
	[[cell imageView] setImage:contactImage]; 
	[[cell textLabel] setText:contactName];
	
	[cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
	
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	NSString *phoneNumber = [[self phoneNumbers] objectAtIndex:indexPath.row];
	[delegate recentNumbersController:self didPickPhoneNumber:phoneNumber];
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

#pragma mark -
#pragma mark Actions

- (IBAction)cancel {
	[delegate recentNumbersControllerDidCancel:self];
}

- (IBAction)proceedToAddressBook {
	[delegate recentNumbersControllerDidProceedToAddressBook:self];
}

@end
