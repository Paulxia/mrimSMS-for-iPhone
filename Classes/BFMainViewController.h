//
//  BFMainViewController.h
//  mrimSMSm
//
//  Created by Алексеев Влад on 12.06.10.
//  Copyright 2010 МИИТ. All rights reserved.
//

#import <UIKit/UIKit.h>
@class mrimSMSmAppDelegate;

@interface BFMainViewController : UIViewController <UITableViewDelegate, UITableViewDataSource> {
	mrimSMSmAppDelegate *appDelegate;
	UITableView *tableView;
	NSArray *phoneNumbers;
	
	UIImage *messagesIndicator;
}
@property (nonatomic, retain) IBOutlet UITableView *tableView;
@property (nonatomic, retain) NSArray *phoneNumbers;
@property (nonatomic, retain) UIImage *messagesIndicator;

@end
