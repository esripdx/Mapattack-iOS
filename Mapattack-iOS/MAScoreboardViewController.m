//
//  MAScoreboardViewController.m
//  Mapattack-iOS
//
//  Created by poeks on 10/14/13.
//  Copyright (c) 2013 Geoloqi. All rights reserved.
//

#import "MAScoreboardViewController.h"
#import "MAAppDelegate.h"

@implementation MAScoreboardViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.toolbarItems = [MAAppDelegate appDelegate].toolbarItems;
}

@end
