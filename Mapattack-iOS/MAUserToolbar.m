//
//  MAUserToolbar.m
//  Mapattack-iOS
//
//  Created by Jen on 9/26/13.
//  Copyright (c) 2013 Geoloqi. All rights reserved.
//

#import "MAUserToolbar.h"

@implementation MAUserToolbar

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.items = [self getButtonItems];
    }
    return self;
}

- (id)initWithTarget:(UIViewController *)target
{
    self = [super init];
    if (self) {
        self.target = target;
        self.items = [self getButtonItems];
    }
    return self;
}

- (NSArray *)getButtonItems
{
    self.username = [[NSUserDefaults standardUserDefaults] objectForKey:kUserNameKey];

    UIBarButtonItem *space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];

    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStyleBordered target:self.target.navigationController action:@selector(popViewControllerAnimated:)];
    UIBarButtonItem *usernameButton = [[UIBarButtonItem alloc] initWithTitle:self.username style:UIBarButtonItemStylePlain target:nil action:nil];
    UIBarButtonItem *helpButton = [[UIBarButtonItem alloc] initWithTitle:@"?" style:UIBarButtonItemStyleDone target:[[UIApplication sharedApplication] delegate] action:@selector(halp:)];

    NSArray *toolbarItems = @[backButton, space, usernameButton, space, helpButton];

    return toolbarItems;
}

@end
