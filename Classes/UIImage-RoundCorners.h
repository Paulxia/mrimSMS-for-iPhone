//
//  UIImage-RoundCorners.h
//  mrimSMSm
//
//  Created by Алексеев Влад on 15.06.10.
//  Copyright 2010 МИИТ. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface UIImage (RoundCorners) 

+ (UIImage *)makeRoundCornerImage:(UIImage*)img cornerWidth:(int)cornerWidth cornerHeight:(int)cornerHeight;

@end
