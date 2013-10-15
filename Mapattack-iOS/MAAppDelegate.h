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

// TODO: HACK! We should refactor this to be stored somewhere else, but this is the easiest way to do it *right* now.
@property (strong, nonatomic) UIBarButtonItem *scoreButton;

+ (MAAppDelegate *)appDelegate;

@end
