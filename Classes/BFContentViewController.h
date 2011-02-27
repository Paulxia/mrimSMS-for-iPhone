//
//  BFContentViewController.h
//  mrimSMSm
//
//  Created by Алексеев Влад on 13.06.10.
//  Copyright 2010 МИИТ. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <iAd/iAd.h>
#import <AudioToolbox/AudioToolbox.h>

@class BFHeaderController;

@interface BFContentViewController : UIViewController <ADBannerViewDelegate, UITabBarControllerDelegate, UINavigationControllerDelegate> {
	BFHeaderController *headerController;
	UIView *contentView;
	UITabBarController *tabBarController;
	
	SystemSoundID newMessagesSound;
	
	ADBannerView *adView;
}

@property (nonatomic, retain, readwrite) UIView *contentView; 
@property (nonatomic, retain, readonly) IBOutlet BFHeaderController *headerController;
@property (nonatomic, retain, readonly) UITabBarController *tabBarController;

- (void)playNewMessagesSound;

@end
