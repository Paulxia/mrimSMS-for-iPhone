//
//  MRIMRecentNumbersViewController.h
//  mrimSMSm
//
//  Created by Алексеев Влад on 16.12.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MRIMHistoryViewController;

@interface MRIMRecentNumbersViewController : UIViewController {
	UITableView *tableView;
	IBOutlet UINavigationBar *navigationBar;
	NSArray *phoneNumbers;
	id delegate;
}

@property (nonatomic, retain) IBOutlet UITableView *tableView;
@property (nonatomic, retain) NSArray *phoneNumbers;
@property (nonatomic, assign) id delegate;

- (IBAction)cancel;
- (IBAction)proceedToAddressBook;

@end


@protocol MRIMRecentNumbersViewControllerDelegate
@required
- (void)recentNumbersController:(MRIMRecentNumbersViewController *)controller didPickPhoneNumber:(NSString *)phoneNumber;
- (void)recentNumbersControllerDidCancel:(MRIMRecentNumbersViewController *)controller;
- (void)recentNumbersControllerDidProceedToAddressBook:(MRIMRecentNumbersViewController *)controller;

@end