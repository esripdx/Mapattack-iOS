//
//  GLAppDelegate.h
//  Mapattack-iOS
//
//  Created by Jen on 9/18/13.
//  Copyright (c) 2013 Geoloqi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GCDAsyncUdpSocket.h"

@interface GLAppDelegate : UIResponder <UIApplicationDelegate, GCDAsyncUdpSocketDelegate>

@property (strong, nonatomic) UIWindow *window;

@end
