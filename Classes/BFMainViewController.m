//
//  BFMainViewController.m
//  mrimSMSm
//
//  Created by Алексеев Влад on 12.06.10.
//  Copyright 2010 МИИТ. All rights reserved.
//

#import "BFMainViewController.h"
#import "BFAllViewController.h"

#import "BFHistoryStorage.h"
#import "BFAddressBookDealer.h"

#import "mrimSMSmAppDelegate.h"

@implementation BFMainViewController

@synthesize tableView;
@synthesize phoneNumbers;
@synthesize messagesIndicator;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
		phoneNumbers = nil;
    }
    return self;
}


- (void)viewDidLoad {
    [super viewDidLoad];
	
	appDelegate = (mrimSMSmAppDelegate *)[[UIApplication sharedApplication] delegate];
	
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(didChangeHistoryNotification:)
												 name:MRIMDidChangeHistoryNotification 
											   object:nil];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
	
	[messagesIndicator release];
	messagesIndicator = nil;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[[self tableView] reloadData];
	
	[appDelegate setHeaderTitle:self.title];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    self.tableView = nil;
	
	[[NSNotificationCenter defaultCenter] removeObserver:self 
													name:MRIMDidChangeHistoryNotification 
												  object:nil];
}

- (void)dealloc {
	self.tableView = nil;
	
    [super dealloc];
}

- (void)didChangeHistoryNotification:(NSNotification *)n {
	[self.tableView reloadData];
}

- (UIImage *)messagesIndicator {
	if (messagesIndicator == nil) {
		messagesIndicator = [[UIImage imageNamed:@"messagesIndicator.png"] retain];
	}
	return messagesIndicator;
}


#pragma mark -
#pragma mark Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {	
	[self setPhoneNumbers:[[[BFHistoryStorage sharedStorage] historyPhoneNumbers] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)]];
	return 1;
}

- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section {
	return [[self phoneNumbers] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
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
	
//	UIImageView *indicatorBackground = (UIImageView *)[cell viewWithTag:50];
//	if (indicatorBackground == nil) {
//		indicatorBackground = [[UIImageView alloc] initWithImage:[self messagesIndicator]];
//		[indicatorBackground setFrame:CGRectMake(290, 16, 20, 13)];
//		[indicatorBackground setTag:50];
//		
//		[cell addSubview:indicatorBackground];
//	}
	
	UILabel *indicatorLabel = (UILabel *)[cell viewWithTag:51];
	if (indicatorLabel == nil) {
		indicatorLabel = [[UILabel alloc] initWithFrame:CGRectMake(283, 14, 16, 16)];
		[indicatorLabel setFont:[UIFont boldSystemFontOfSize:15]];
		[indicatorLabel setTextColor:[UIColor grayColor]];
		[indicatorLabel setBackgroundColor:[UIColor clearColor]];
		[indicatorLabel setAdjustsFontSizeToFitWidth:NO];
		[indicatorLabel setTextAlignment:UITextAlignmentRight];
		[indicatorLabel setTag:51];
		[indicatorLabel setHighlightedTextColor:[UIColor whiteColor]];
		
		[cell addSubview:indicatorLabel];
	}
	NSInteger messagesCount = [[BFHistoryStorage sharedStorage] numberOfMessagesForPhoneNumber:phoneNumber];
	
	[indicatorLabel setText:[NSString stringWithFormat:@"%d", messagesCount]];
	
	[cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
	
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	NSString *phoneNumber = [[self phoneNumbers] objectAtIndex:indexPath.row];
	NSString *contactName = [[BFAddressBookDealer sharedDealer] fullNameForPhone:phoneNumber 
															 withAlternativeText:phoneNumber];
	
	BFAllViewController *allViewController = [[BFAllViewController alloc] initWithNibName:@"BFAllViewController" bundle:nil];
	[allViewController setPhoneNumber:phoneNumber];
	[allViewController setTitle:contactName];
	[[self navigationController] pushViewController:allViewController animated:YES];
	[allViewController release];
}

@end
