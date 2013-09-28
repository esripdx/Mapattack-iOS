//
//  MAGameViewController.m
//  Mapattack-iOS
//
//  Created by Jen on 9/18/13.
//  Copyright (c) 2013 Geoloqi. All rights reserved.
//

#import "MAGameManager.h"
#import "MAGameViewController.h"
#import "MAAppDelegate.h"

@interface MAGameViewController ()

@end

@implementation MAGameViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.toolbarItems = [MAAppDelegate appDelegate].toolbarItems;
}

- (void)viewWillAppear:(BOOL)animated {
    NSString *template = [NSString stringWithFormat:@"http://mapattack-tiles-0.pdx.esri.com/%@/{z}/{y}/{x}", [MAGameManager sharedManager].joinedTeamColor];
    MKTileOverlay *overlay = [[MKTileOverlay alloc] initWithURLTemplate:template];
    overlay.canReplaceMapContent = YES;
    [self.mapView addOverlay:overlay level:MKOverlayLevelAboveLabels];
    self.mapView.showsUserLocation = YES;
    MKCoordinateRegion region = [[MAGameManager sharedManager] regionForBoard:[MAGameManager sharedManager].joinedGameBoard];
    [self.mapView setRegion:region animated:YES];

    [MAGameManager sharedManager].delegate = self;

    [self refreshScoreLabels];
}

- (void)viewWillDisappear:(BOOL)animated {
    [MAGameManager sharedManager].delegate = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

#pragma mark Score Label Styling
- (void)refreshScoreLabels {
    MAGameManager *manager = [MAGameManager sharedManager];
    UIFont *mensch = [UIFont fontWithName:@"MenschRegular" size:24];
    UIFont *karla = [UIFont fontWithName:@"Karla" size:19];
    self.gameNameLabel.font = mensch;
    self.gameNameLabel.textColor = MA_COLOR_CREAM;
    self.gameNameLabel.text = manager.joinedGameName;
    self.gameNameLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;

    self.redScoreLabel.font = karla;
    self.redScoreLabel.layer.borderWidth = 2;
    self.redScoreLabel.layer.borderColor = MA_COLOR_RED.CGColor;
    self.redScoreContainer.backgroundColor = [UIColor clearColor];

    self.blueScoreLabel.font = karla;
    self.blueScoreLabel.layer.borderWidth = 2;
    self.blueScoreLabel.layer.borderColor = MA_COLOR_BLUE.CGColor;
    self.blueScoreContainer.backgroundColor = [UIColor clearColor];

    if ([manager.joinedTeamColor isEqualToString:@"red"]) {
        self.redScoreContainer.backgroundColor = MA_COLOR_RED;
        self.redScoreLabel.textColor = MA_COLOR_WHITE;
        self.redScoreLabel.layer.borderColor = MA_COLOR_WHITE.CGColor;
    } else {
        self.blueScoreContainer.backgroundColor = MA_COLOR_BLUE;
        self.blueScoreLabel.textColor = MA_COLOR_WHITE;
        self.blueScoreLabel.layer.borderColor = MA_COLOR_WHITE.CGColor;
    }
}

#pragma mark MKMapViewDelegate

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id <MKOverlay>)overlay {
    return [[MKTileOverlayRenderer alloc] initWithTileOverlay:(MKTileOverlay *)overlay];
}

#pragma mark Game Manager Delegate

- (void)coin:(NSString *)identifier didChangeState:(BOOL)claimable {

}

- (void)player:(NSString *)identifier didMoveToLocation:(CLLocation *)location {

}

- (void)team:(int)teamNumber didReceivePoints:(int)points {

}

- (void)gameDidStart {

}

- (void)gameDidEnd {

}

@end
