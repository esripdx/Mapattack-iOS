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
    }
    return self;
}

- (id)initWithUsername:(NSString *)username andTarget:(UIViewController *)target
{
    self = [super init];
    if (self) {
        self.target = target;
        self.username = username;
        self.items = [self getButtonItems];
    }
    return self;
}

- (NSArray *)getButtonItems
{
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStyleBordered target:self.target action:@selector(back)];
    UIBarButtonItem *usernameButton = [[UIBarButtonItem alloc] initWithTitle:self.username style:UIBarButtonItemStylePlain target:nil action:nil];
    UIBarButtonItem *helpButton = [[UIBarButtonItem alloc] initWithTitle:@"?" style:UIBarButtonItemStyleDone target:nil action:nil];
    NSArray *toolbarItems = @[backButton, usernameButton, helpButton];

    return toolbarItems;
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
