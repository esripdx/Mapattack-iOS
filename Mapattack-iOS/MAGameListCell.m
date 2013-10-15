//
//  MAGameListCell.m
//  Mapattack-iOS
//
//  Created by Ryan Arana on 9/24/13.
//  Copyright (c) 2013 Geoloqi. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import "MAGameListCell.h"
#import "MAGameManager.h"
#import "MABorderSetter.h"
#import "MABoard.h"

@interface MAGameListCell ()

@property (strong, nonatomic, readwrite) MABoard *board;

@end

@implementation MAGameListCell

#pragma mark - Helpers
- (UIFont *)fontType {
    return MA_FONT_KARLA_REGULAR;
}

#pragma mark - Cell Contents
- (void)styleAsActiveBoard {
    self.cellView.backgroundColor = MA_COLOR_BODYBLUE;
    self.playersLabel.textColor = MA_COLOR_WHITE;
    self.playersLabel.font = [self fontType];
    self.gameNameLabel.textColor = MA_COLOR_WHITE;
    self.gameNameLabel.font = [self fontType];
    [MABorderSetter setBottomBorderForView:self.cellView withColor:MA_COLOR_WHITE];
    [MABorderSetter setLeftBorderForView:self.cellView withColor:MA_COLOR_WHITE];

    self.mapView.tintColor = MA_COLOR_BLUE;
    [self.startButton setTitleColor:MA_COLOR_BLUE forState:UIControlStateNormal];
    [self.startButton setTitle:@"JOIN" forState:UIControlStateNormal];
}

- (void)styleAsInactiveBoard {
    self.cellView.backgroundColor = MA_COLOR_CREAM;
    self.playersLabel.textColor = MA_COLOR_RED;
    self.playersLabel.font = [self fontType];
    self.gameNameLabel.textColor = MA_COLOR_RED;
    self.gameNameLabel.font = [self fontType];
    [MABorderSetter setBottomBorderForView:self.cellView withColor:MA_COLOR_RED];
    [MABorderSetter setLeftBorderForView:self.cellView withColor:MA_COLOR_RED];

    self.mapView.tintColor = MA_COLOR_RED;
    [self.startButton setTitleColor:MA_COLOR_RED forState:UIControlStateNormal];
    [self.startButton setTitle:@"CREATE" forState:UIControlStateNormal];
}

#pragma mark - Custom setters
- (void)setBoard:(MABoard *)board withMapDelegate:(id <MKMapViewDelegate>)delegate annotations:(NSArray *)annotations {
    self.board = board;

    // Set labels
    self.gameNameLabel.text = self.board.name;
    if (self.board.game != nil) {
        self.playersLabel.text = [NSString stringWithFormat:@"%d", self.board.game.totalPlayers];
    } else {
        self.playersLabel.text = @"0";
    }

    // Style as active or inactive
    if (self.board.game.isActive) {
        [self styleAsActiveBoard];
    } else {
        [self styleAsInactiveBoard];
    }

    [self.startButton addTarget:delegate action:@selector(joinGame:) forControlEvents:UIControlEventTouchUpInside];
    self.mapView.delegate = delegate;
    [self.mapView removeAnnotations:self.mapView.annotations];
    [self.mapView addAnnotations:annotations];
}

- (void)setMapView:(MKMapView *)mapView {
    mapView.showsUserLocation = YES;

    // Join button
    UIButton *joinButton = [[UIButton alloc] init];
    joinButton.titleLabel.font = MA_FONT_MENSCH_HEADER;
    joinButton.contentEdgeInsets = UIEdgeInsetsMake(7.0, 0, 0, 0);
    joinButton.backgroundColor = MA_COLOR_CREAM;
    joinButton.alpha = 0.93f;
    joinButton.layer.cornerRadius = 10;
    joinButton.clipsToBounds = YES;

    CGSize btnSize = CGSizeMake(mapView.frame.size.width * 0.75f, 50);
    CGFloat btnPadding = 16;
    joinButton.frame = CGRectMake(mapView.frame.size.width/2 - btnSize.width/2, CGRectGetMaxY(mapView.bounds) - btnSize.height - btnPadding, btnSize.width, btnSize.height);

    self.startButton = joinButton;
    [mapView addSubview:self.startButton];
    _mapView = mapView;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    if (selected) {
        if (self.mapView.overlays.count == 0) {
            // use custom tiles mapView delegate will have to return a renderer! (GamesListVC should be mapView's delegate).
            NSString *template = [NSString stringWithFormat:@"http://mapattack-tiles-0.pdx.esri.com/%@/{z}/{y}/{x}", @"dark"];
            MKTileOverlay *overlay = [[MKTileOverlay alloc] initWithURLTemplate:template];
            overlay.canReplaceMapContent = YES;
            [self.mapView addOverlay:overlay level:MKOverlayLevelAboveLabels];
        }

        MKCoordinateRegion region = [[MAGameManager sharedManager] regionForBoard:self.board];
        if (self.mapView.region.center.latitude != region.center.latitude ||
                self.mapView.region.center.longitude != region.center.longitude) {
            [self.mapView setRegion:region animated:NO];
        }
    }
}

- (void)dealloc {
    _mapView = nil;
    self.startButton = nil;
}

@end
