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
#import <AudioToolbox/AudioToolbox.h>

@interface MAGameViewController ()

@property (strong, nonatomic) UIButton *startStopButton;
@property (strong, nonatomic) NSMutableDictionary *avatars;

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
    self.avatars = [NSMutableDictionary new];
}

- (void)viewWillAppear:(BOOL)animated {
    NSString *template = [NSString stringWithFormat:@"http://mapattack-tiles-0.pdx.esri.com/%@/{z}/{y}/{x}", [MAGameManager sharedManager].joinedTeamColor];
    DDLogVerbose(@"using template: %@", template);
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

    // TODO: This smells bad, should probably do something smarter here.
    [[MAGameManager sharedManager].locationManager stopUpdatingLocation];
    [[MAGameManager sharedManager].udpConnection disconnect];
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
        MKPinAnnotationView *pin = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"playerAnnotation"];
        MAPlayerAnnotation *playerAnnotation = (MAPlayerAnnotation *)annotation;
        UIImage *avatarImage = self.avatars[playerAnnotation.identifier];
        if (avatarImage == nil) {
            avatarImage = [UIImage imageNamed:[NSString stringWithFormat:@"player_%@", playerAnnotation.team]];
            [[MAGameManager sharedManager] fetchIconForPlayerId:playerAnnotation.identifier];
        }
        pin.image = avatarImage;
        return pin;
    }
    
    
    return nil;
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id <MKOverlay>)overlay {
    return [[MKTileOverlayRenderer alloc] initWithTileOverlay:(MKTileOverlay *)overlay];
}

#pragma mark - MAGameManagerDelegate

- (void)player:(NSString *)identifier didMoveToLocation:(CLLocation *)location {
    MAPlayerAnnotation *pa = [self playerAnnotationForIdentifier:identifier];
    if (pa) {
        [self.mapView removeAnnotation:pa];
        pa.location = location;
        [self.mapView addAnnotation:pa];
    }
}

- (void)team:(NSString *)color didReceivePoints:(int)points {
    UILabel *scoreLabel;
    if ([color isEqualToString:@"red"]) {
        scoreLabel = self.redScoreLabel;
    } else {
        scoreLabel = self.blueScoreLabel;
    }

    int currentScore = [scoreLabel.text integerValue];
    scoreLabel.text = [NSString stringWithFormat:@"%d", currentScore+points];
}

- (void)team:(NSString *)color setScore:(int)score {
    NSString *scoreText = [NSString stringWithFormat:@"%d", score];
    if ([color isEqualToString:@"red"]) {
        self.redScoreLabel.text = scoreText;
    } else {
        self.blueScoreLabel.text = scoreText;
    }
}

- (void)coin:(NSString *)identifier wasClaimedByPlayerWithId:(NSString *)playerId score:(NSInteger)playerScore forTeam:(NSString *)teamColor {
    for (id <MKAnnotation> annotation in self.mapView.annotations) {
        if ([annotation isKindOfClass:[MACoinAnnotation class]]) {
            MACoinAnnotation *coinAnnotation = (MACoinAnnotation *)annotation;
            if ([coinAnnotation.identifier isEqualToString:identifier]) {
                [self.mapView removeAnnotation:annotation];
            }
            coinAnnotation.team = teamColor;
            [self.mapView addAnnotation:coinAnnotation];
        }
    }

    if ([playerId isEqualToString:[[NSUserDefaults standardUserDefaults] objectForKey:kMADefaultsDeviceIdKey]]) {
        [MAAppDelegate appDelegate].scoreButton.title = [NSString stringWithFormat:@"%d", playerScore];
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    }
}

- (void)team:(NSString *)color addPlayerWithIdentifier:(NSString *)identifier name:(NSString *)name score:(int)score location:(CLLocation *)location {
    MAPlayerAnnotation *playerAnnotation = [self playerAnnotationForIdentifier:identifier];
    if (playerAnnotation) {
        [self.mapView removeAnnotation:playerAnnotation];
    }
    
    MAPlayerAnnotation *annotation = [[MAPlayerAnnotation alloc] initWithIdentifier:identifier
                                                                               name:name
                                                                              score:score
                                                                           location:location
                                                                               team:color];

    if ([[[NSUserDefaults standardUserDefaults] objectForKey:kMADefaultsDeviceIdKey] isEqualToString:identifier]) {
        [MAAppDelegate appDelegate].scoreButton.title = [NSString stringWithFormat:@"%d", score];
    }

    [self.mapView addAnnotation:annotation];
}

- (void)team:(NSString *)color addCoinWithIdentifier:(NSString *)identifier location:(CLLocation *)location points:(NSInteger)points {
    for (id <MKAnnotation> annotation in self.mapView.annotations) {
        if ([annotation isKindOfClass:[MACoinAnnotation class]]) {
            MACoinAnnotation *coinAnnotation = (MACoinAnnotation *)annotation;
            if ([coinAnnotation.identifier isEqualToString:identifier]) {
                [self.mapView removeAnnotation:annotation];
            }
        }
    }

    MACoinAnnotation *annotation = [[MACoinAnnotation alloc] initWithIdentifier:identifier
                                                                     coordinate:location.coordinate
                                                                     pointValue:points
                                                                           team:color];
    
    [self.mapView addAnnotation:annotation];
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

- (void)didFetchIcon:(UIImage *)icon forPlayerId:(NSString *)playerId {
    DDLogVerbose(@"got avatar image sized %fx%f", icon.size.width, icon.size.height);
    
    UIGraphicsBeginImageContext(CGSizeMake(kMAAvatarIconSize, kMAAvatarIconSize));
    [icon drawInRect:CGRectMake(0.0, 0.0, kMAAvatarIconSize, kMAAvatarIconSize)];
    UIImage *resizedIcon = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    DDLogVerbose(@"setting avatar image sized %fx%f", resizedIcon.size.width, resizedIcon.size.height);
    [self.avatars setObject:resizedIcon forKey:playerId];
    MAPlayerAnnotation *pa = [self playerAnnotationForIdentifier:playerId];
    if (pa) {
        [self.mapView removeAnnotation:pa];
        [self.mapView addAnnotation:pa];
    }
}

- (MAPlayerAnnotation *)playerAnnotationForIdentifier:(NSString *)identifier {
    MAPlayerAnnotation *pa;
    for (id <MKAnnotation> annotation in self.mapView.annotations) {
        if ([annotation isKindOfClass:[MAPlayerAnnotation class]]) {
            MAPlayerAnnotation *playerAnnotation = (MAPlayerAnnotation *)annotation;
            if ([playerAnnotation.identifier isEqualToString:identifier]) {
                pa = playerAnnotation;
                break;
            }
        }
    }
    return pa;
}

@end
