//
//  MAHelpViewController.m
//  Mapattack-iOS
//
//  Created by Jen on 9/18/13.
//  Copyright (c) 2013 Geoloqi. All rights reserved.
//

#import "MAHelpViewController.h"
#import "MAAppDelegate.h"

@interface MAHelpViewController ()

@end

@implementation MAHelpViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    
    [self makeTitleWithText:self.creditsLabel];
    [self makeTitleWithText:self.technologyLabel];
    [self makeTitleWithText:self.historyLabel];
    [self makeNiceNiceText:self.creditsTextView];
    [self makeNiceNiceText:self.technologyTextView];
    [self makeNiceNiceText:self.historyTextView];

}

- (void)makeTitleWithText:(UILabel *)thing
{
    thing.font = [UIFont fontWithName:@"M41_LOVEBIT" size:18.0f];
    thing.textColor = MA_COLOR_RED;
    thing.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
}

- (void)makeNiceNiceText:(UITextView *)thing
{
    thing.font = [UIFont fontWithName:@"Karla" size:9];
    thing.textColor = MA_COLOR_DARKGRAY;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.

    self.toolbarItems = [MAAppDelegate appDelegate].toolbarItems;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
