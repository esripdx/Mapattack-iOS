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
#import "MAPlayer.h"
#import "MAPlayerAnnotationView.h"
#import "MACoin.h"
#import "MACoinAnnotationView.h"
#import "MABoard.h"

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
    [super viewWillAppear:animated];
    
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
        CGSize btnSize = CGSizeMake(self.mapView.frame.size.width * 0.75f, 50);
        CGFloat btnPadding = 16;
        CGRect btnFrame = CGRectMake(self.mapView.frame.size.width/2 - btnSize.width/2, self.mapView.frame.size.height - self.navigationController.toolbar.frame.size.height - btnSize.height - btnPadding, btnSize.width, btnSize.height);
        // self.startStopButton = [[UIButton alloc] initWithFrame:CGRectMake(42, self.view.frame.size.height - self.navigationController.toolbar.frame.size.height - 84, self.view.frame.size.width * 0.75f, 66)];
        self.startStopButton = [[UIButton alloc] initWithFrame:btnFrame];
        [self.startStopButton setTitle:@"START" forState:UIControlStateNormal];
        self.startStopButton.titleLabel.font = MA_FONT_MENSCH_HEADER;
        self.startStopButton.contentEdgeInsets = UIEdgeInsetsMake(7, 0, 0, 0);
        if ([[MAGameManager sharedManager].joinedTeamColor isEqualToString:@"blue"]) {
            [self.startStopButton setTitleColor:MA_COLOR_BLUE forState:UIControlStateNormal];
        } else {
            [self.startStopButton setTitleColor:MA_COLOR_RED forState:UIControlStateNormal];
        }
        self.startStopButton.alpha = 0.93f;
        self.startStopButton.layer.cornerRadius = 10;
        self.startStopButton.clipsToBounds = YES;
        self.startStopButton.backgroundColor = MA_COLOR_CREAM;
        [self.startStopButton addTarget:self action:@selector(startGame:) forControlEvents:UIControlEventTouchUpInside];
        [self.mapView addSubview:self.startStopButton];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    for (MKTileOverlay *overlay in self.mapView.overlays) {
        [self.mapView removeOverlay:overlay];
    }
    [MAGameManager sharedManager].delegate = nil;
    [[MAGameManager sharedManager] leaveGame];
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
    self.gameNameLabel.text = manager.joinedGameBoard.name;
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
    if ([annotation isKindOfClass:[MACoin class]]) {
        MACoinAnnotationView *annotationView = [[MACoinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"coinAnnotation"];
        return annotationView;
    }
    if ([annotation isKindOfClass:[MAPlayer class]]) {
        MAPlayerAnnotationView *annotationView = [[MAPlayerAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"playerAnnotation"];
        return annotationView;
    }

    return nil;
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id <MKOverlay>)overlay {
    return [[MKTileOverlayRenderer alloc] initWithTileOverlay:(MKTileOverlay *)overlay];
}

#pragma mark - MAGameManagerDelegate

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

- (void)updateStateForCoin:(MACoin *)coin {
    BOOL found = NO;
    for (id <MKAnnotation> annotation in self.mapView.annotations) {
        if ([annotation isKindOfClass:[MACoin class]]) {
            MACoin *coinAnnotation = (MACoin *)annotation;
            if ([coinAnnotation.coinId isEqualToString:coin.coinId]) {
                [coinAnnotation updateWithCoin:coin];
                found = YES;
                break;
            }
        }
    }

    if (!found) {
        [self.mapView addAnnotation:coin];
    }
}

- (void)updateStateForPlayer:(MAPlayer *)player {
    BOOL found = NO;
    for (id <MKAnnotation> annotation in self.mapView.annotations) {
        if ([annotation isKindOfClass:[MAPlayer class]]) {
            MAPlayer *playerAnnotation = (MAPlayer *)annotation;
            if ([playerAnnotation.playerId isEqualToString:player.playerId]) {
                [playerAnnotation updateWithPlayer:player];
                found = YES;
                break;
            }
        }
    }

    if (!found) {
        [self.mapView addAnnotation:player];
    }

    if (player.isSelf) {
        [MAAppDelegate appDelegate].scoreButton.title = [NSString stringWithFormat:@"%d", player.score];
    }
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

    NSString *victoryString;
    NSInteger teamScore;
    NSInteger opponentScore;
    MAGameManager *manager = [MAGameManager sharedManager];
    if ([manager.joinedTeamColor isEqualToString:@"blue"]) {
        teamScore = manager.blueScore;
        opponentScore = manager.redScore;
    } else {
        teamScore = manager.redScore;
        opponentScore = manager.blueScore;
    }

    if (teamScore > opponentScore) {
        victoryString = @"Your team won!";
    } else if (teamScore < opponentScore) {
        victoryString = @"Your team lost!";
    } else {
        victoryString = @"It's a tie!";
    }
    [[[UIAlertView alloc] initWithTitle:@"Game Over" message:[NSString stringWithFormat:@"The game has ended. %@!", victoryString]
                               delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
}

@end
