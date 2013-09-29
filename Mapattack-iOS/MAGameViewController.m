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
#import "MACoinAnnotation.h"
#import "MAPlayerAnnotation.h"

@interface MAGameViewController ()

@property (strong, nonatomic) UIButton *startStopButton;

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

    [self setupScoreLabels];

    if (self.createdGame) {
        self.startStopButton = [[UIButton alloc] initWithFrame:CGRectMake(42, self.view.frame.size.height - self.navigationController.toolbar.frame.size.height - 84, self.view.frame.size.width * 0.75f, 66)];
        [self.startStopButton setTitle:@"START" forState:UIControlStateNormal];
        self.startStopButton.titleLabel.font = [UIFont fontWithName:@"M41_LOVEBIT" size:24];
        self.startStopButton.titleLabel.textColor = MA_COLOR_WHITE;
        self.startStopButton.layer.borderColor = MA_COLOR_WHITE.CGColor;
        self.startStopButton.layer.borderWidth = 2;
        [self.startStopButton addTarget:self action:@selector(startGame:) forControlEvents:UIControlEventTouchUpInside];

        [self.view addSubview:self.startStopButton];
    }
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

- (void)setupScoreLabels {
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

- (void)startGame:(id)sender {
    [[MAGameManager sharedManager] startGame];
}

- (void)endGame:(id)sender {
    [[MAGameManager sharedManager] endGame];
}

#pragma mark MKMapViewDelegate

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {
    if ([annotation isKindOfClass:[MKUserLocation class]]) {
        return nil;
    }
    if ([annotation isKindOfClass:[MACoinAnnotation class]]) {
        MKPinAnnotationView *pin = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"coinAnnotation"];
        MACoinAnnotation *coinAnnotation = (MACoinAnnotation *)annotation;
        pin.image = coinAnnotation.image;
        return pin;
    }
    if ([annotation isKindOfClass:[MAPlayerAnnotation class]]) {
        MKPinAnnotationView *pin = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"coinAnnotation"];
        MAPlayerAnnotation *playerAnnotation = (MAPlayerAnnotation *)annotation;
        pin.image = playerAnnotation.image;
        return pin;
    }
    return nil;
}

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
    [self.startStopButton setTitle:@"END" forState:UIControlStateNormal];
    [self.startStopButton removeTarget:self action:@selector(startGame:) forControlEvents:UIControlEventTouchUpInside];
    [self.startStopButton addTarget:self action:@selector(endGame:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)gameDidEnd {
    [self.startStopButton setTitle:@"START" forState:UIControlStateNormal];
    [self.startStopButton removeTarget:self action:@selector(endGame:) forControlEvents:UIControlEventTouchUpInside];
    [self.startStopButton addTarget:self action:@selector(startGame:) forControlEvents:UIControlEventTouchUpInside];
}

@end
