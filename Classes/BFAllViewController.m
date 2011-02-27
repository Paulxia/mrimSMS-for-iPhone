//
//  BFAllViewController.m
//  mrimSMSm
//
//  Created by Алексеев Влад on 13.06.10.
//  Copyright 2010 МИИТ. All rights reserved.
//

#import "BFAllViewController.h"
#import "BFHistoryStorage.h"
#import "BFAddressBookDealer.h"

#import "MRIMMessageDetailController.h"

#import "BFSMSCell.h"

#import "mrimSMSmAppDelegate.h"

@implementation BFAllViewController

@synthesize tableView;
@synthesize completeHistory;
@synthesize phoneNumber;

@synthesize todayDateFormatter, messageDateFormatter, messageTimeFormatter;

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
    }
    return self;
}
*/

- (void)viewDidLoad {
    [super viewDidLoad];
	
	appDelegate = (mrimSMSmAppDelegate *)[[UIApplication sharedApplication] delegate];
	
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(didChangeHistoryNotification:)
												 name:MRIMDidChangeHistoryNotification 
											   object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[[self tableView] reloadData];
	
	[appDelegate setHeaderTitle:self.title];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
	
	[sentIcon release];
	sentIcon = nil;
	
	[receivedIcon release];
	receivedIcon = nil;
}

- (void)viewDidUnload {
    [super viewDidUnload];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self 
													name:MRIMDidChangeHistoryNotification 
												  object:nil];
}

- (void)dealloc {
    [super dealloc];
}

- (void)didChangeHistoryNotification:(NSNotification *)n {
	[self.tableView reloadData];
}

- (UIImage *)sentIcon {
	if (sentIcon == nil) {
		sentIcon = [[UIImage imageNamed:@"SentMailbox.png"] retain];
	}
	return sentIcon;
}

- (UIImage *)receivedIcon {
	if (receivedIcon == nil) {
		receivedIcon = [[UIImage imageNamed:@"InMailbox.png"] retain];
	}
	return receivedIcon;
}

#pragma mark Date Formatters

- (NSDateFormatter *)messageDateFormatter {
	if (messageDateFormatter == nil) {
		messageDateFormatter = [[NSDateFormatter alloc] init];
		[messageDateFormatter setDateStyle:NSDateFormatterMediumStyle];
		[messageDateFormatter setTimeStyle:NSDateFormatterShortStyle];
	}
	return messageDateFormatter;
}

- (NSDateFormatter *)messageTimeFormatter {
	if (messageTimeFormatter == nil) {
		messageTimeFormatter = [[NSDateFormatter alloc] init];
		[messageTimeFormatter setDateStyle:NSDateFormatterNoStyle];
		[messageTimeFormatter setTimeStyle:NSDateFormatterShortStyle];
	}
	return messageTimeFormatter;
}

- (NSDateFormatter *)todayDateFormatter {
	if (todayDateFormatter == nil) {
		todayDateFormatter = [[NSDateFormatter alloc] init];
		[todayDateFormatter setDateStyle:NSDateFormatterMediumStyle];
		[todayDateFormatter setTimeStyle:NSDateFormatterNoStyle];
	}
	return todayDateFormatter;
}

- (NSString *)stringDateForDate:(NSDate *)date {
	NSDate *messageDate = date;
	
	NSString *todayDateString = [self.todayDateFormatter stringFromDate:[NSDate date]];
	NSString *messageDateString = [self.todayDateFormatter stringFromDate:messageDate];
	NSString *messageDateToDisplay = nil;
	
	if ([messageDateString isEqualToString:todayDateString]) {
		// only show time, because this message was sent/received today
		messageDateToDisplay = [self.messageTimeFormatter stringFromDate:messageDate];
	}
	else {
		// show full date
		messageDateToDisplay = [self.messageDateFormatter stringFromDate:messageDate];
	}
	return messageDateToDisplay;
}

#pragma mark -
#pragma mark Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	[self setCompleteHistory:[[BFHistoryStorage sharedStorage] completeHistoryForPhoneNumber:[self phoneNumber]]];
	return 1;
}

- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section {
	return [[self completeHistory] count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	CGFloat cellWidth = 320;
	if (UIInterfaceOrientationIsLandscape([self interfaceOrientation])) {
		cellWidth = 480;
	}
	
	NSManagedObject *historyObject = [[self completeHistory] objectAtIndex:indexPath.row];
	NSString *messageText = [historyObject valueForKey:@"message"];
	
	CGFloat height = [BFSMSCell cellHeightForText:messageText cellWidth:cellWidth];
	return height;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *cellID = @"smsCellID";
	BFSMSCell *cell = (BFSMSCell *)[[self tableView] dequeueReusableCellWithIdentifier:cellID];
	
	if (cell == nil) {
		cell = [[[BFSMSCell alloc] initWithStyle:UITableViewCellStyleDefault
									   reuseIdentifier:cellID] autorelease];
	}
	
	NSManagedObject *historyObject = [[self completeHistory] objectAtIndex:indexPath.row];
	
	NSString *messagePhoneNumber = [historyObject valueForKey:@"phoneNumber"];
	NSString *messageContactName = [[BFAddressBookDealer sharedDealer] fullNameForPhone:messagePhoneNumber 
																	withAlternativeText:messagePhoneNumber];
	UIImage *messageContactPhoto = [[BFAddressBookDealer sharedDealer] imageForPhone:messagePhoneNumber];
	NSString *messageText = [historyObject valueForKey:@"message"];
	NSDate *messageDate = [historyObject valueForKey:@"date"];
	BOOL income = [[historyObject valueForKey:@"income"] boolValue];
	BOOL unread = [[historyObject valueForKey:@"unread"] boolValue];
	
	if (income) {
		[cell setMailboxIcon:[self receivedIcon]];
	}
	else {
		[cell setMailboxIcon:[self sentIcon]];
	}

	
	[cell setMessageDate:[self stringDateForDate:messageDate]];
	[cell setMessageText:messageText];
	[cell setContactName:messageContactName];
	[cell setPhoneNumber:messagePhoneNumber];
	[cell setContactPhoto:messageContactPhoto];
	[cell setUnread:unread];
	[cell setIncome:income];
	
	[cell setContentMode:UIViewContentModeRedraw];
	cell.selectedBackgroundView = [[[UIImageView alloc] init] autorelease];
	
	[cell setNeedsDisplay];
	
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[[self tableView] deselectRowAtIndexPath:indexPath animated:NO];
	
	MRIMMessageDetailController *detailController = [[MRIMMessageDetailController alloc] initWithNibName:@"MRIMMessageDetailController" 
																								  bundle:nil];
	[[self navigationController] pushViewController:detailController animated:YES];
	[detailController release];
	
	NSManagedObject *historyObject = [[self completeHistory] objectAtIndex:indexPath.row];
	
	[historyObject setValue:[NSNumber numberWithBool:NO] forKey:@"unread"];
	
	BFSMSCell *cell = (BFSMSCell *)[[self tableView] cellForRowAtIndexPath:indexPath];
	[cell setUnread:NO];
	[cell setNeedsDisplay];
	
	NSString *messagePhoneNumber = [historyObject valueForKey:@"phoneNumber"];
	NSString *messageContactName = [[BFAddressBookDealer sharedDealer] fullNameForPhone:messagePhoneNumber 
																	withAlternativeText:messagePhoneNumber];
	UIImage *messageContactPhoto = [[BFAddressBookDealer sharedDealer] imageForPhone:messagePhoneNumber];
	NSString *messageText = [historyObject valueForKey:@"message"];
	
	[detailController setPersonName:messageContactName
						phoneNumber:messagePhoneNumber 
							message:messageText 
							  photo:messageContactPhoto];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle 
forRowAtIndexPath:(NSIndexPath *)indexPath {
	NSManagedObject *historyObject = [[self completeHistory] objectAtIndex:indexPath.row];
	[[BFHistoryStorage sharedStorage] deleteHistoryObject:historyObject];
}

#pragma mark -
#pragma mark Menu actions

- (void)copyActionPress:(UIMenuController *)controller {
	[controller setMenuVisible:NO animated:YES];
	NSLog(@"%@", controller);
}

- (void)replyActionPress:(UIMenuController *)controller {
	[controller setMenuVisible:NO animated:YES];
	NSLog(@"%@", controller);
}

@end
