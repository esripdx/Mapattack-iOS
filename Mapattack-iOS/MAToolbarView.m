//
//  MAToolbarView.m
//  Mapattack-iOS
//
//  Created by poeks on 10/14/13.
//  Copyright (c) 2013 Geoloqi. All rights reserved.
//

#import "MAToolbarView.h"

@implementation MAToolbarView

- (id)initWithFrame:(CGRect)frame
{
    if (self) {
        self = [super initWithFrame:frame];
        [self addStuffs];
    }
    
    return self;
}

- (void)addStuffs
{
    // TODO shit goes here
}

+ (void)addToView:(UIView *)view
{
    MAToolbarView *tb = [[MAToolbarView alloc] initWithFrame:[self frameForToolbar]];
    [view addSubview:tb];
}

+ (CGRect)frameForToolbar
{
    CGFloat x = 0;
    CGFloat width = 320;
    CGFloat height = 44;
    CGFloat y = 568-height;

    return CGRectMake(x, y, width, height);
}

@end
