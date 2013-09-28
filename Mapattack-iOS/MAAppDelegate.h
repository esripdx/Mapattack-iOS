//
//  MAAppDelegate.h
//  Mapattack-iOS
//
//  Created by Jen on 9/18/13.
//  Copyright (c) 2013 Geoloqi. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "DDASLLogger.h"
#import "DDTTYLogger.h"
#import "DDFileLogger.h"

@interface MAAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

+ (MAAppDelegate *)appDelegate;

- (NSArray *)toolbarItems;
@end
