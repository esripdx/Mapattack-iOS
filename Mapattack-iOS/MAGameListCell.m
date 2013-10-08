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
#import "MACoin.h"

@implementation MAGameListCell

- (void)populateBoardWithDictionary:(NSDictionary *)board andIndex:(int)boardIndex andInactiveHeaderIndex:(int)inActiveHeaderIndex andTableView:(UITableView *)tableView
{

    self.board = [[MABoard alloc] initWithDictionary:board];
    self.parent = tableView;
    
    // First one...
    if (!boardIndex) {
        self.board.indexInBoardList = 0;
    } else {
        self.board.indexInBoardList = boardIndex;
    }
    
    // Set labels
    self.gameNameLabel.text = self.board.name;
    if (self.board.game != nil) {
        self.bluePlayersLabel.text = [NSString stringWithFormat:@"%d", self.board.game.totalPlayers];
    } else {
        self.bluePlayersLabel.text = @"0";
    }
    
    // Style as active or inactive
    if (self.board.game.isActive) {
        [self setActiveBoard];
    } else {
        [self setInactiveBoard];
    }

}

- (void)populateBoardWithDictionary:(NSDictionary *)board
{
    self.board = [[MABoard alloc] initWithDictionary:board];
    
    // Set labels
    self.gameNameLabel.text = self.board.name;
    if (self.board.game != nil) {
        self.bluePlayersLabel.text = [NSString stringWithFormat:@"%d", self.board.game.totalPlayers];
    } else {
        self.bluePlayersLabel.text = @"0";
    }
    
    // Style as active or inactive
    if (self.board.game.isActive) {
        [self setActiveBoard];
    } else {
        [self setInactiveBoard];
    }
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
    }
    return self;
}

#pragma mark - Helpers
- (UIFont *)headerFontType
{
    return MA_FONT_MENSCH_HEADER;
}

- (UIFont *)fontType
{
    return MA_FONT_KARLA_REGULAR;
}

#pragma mark - Cell Contents
- (void)setActiveBoard
{

    self.cellView.backgroundColor = MA_COLOR_BODYBLUE;
    self.bluePlayersLabel.textColor = MA_COLOR_WHITE;
    self.bluePlayersLabel.font = [self fontType];
    self.gameNameLabel.textColor = MA_COLOR_WHITE;
    self.gameNameLabel.font = [self fontType];
    [MABorderSetter setBottomBorderForView:self.cellView withColor:MA_COLOR_WHITE];
    [MABorderSetter setLeftBorderForView:self.cellView withColor:MA_COLOR_WHITE];

}

- (void)setInactiveBoard
{

    self.cellView.backgroundColor = MA_COLOR_CREAM;
    self.bluePlayersLabel.textColor = MA_COLOR_RED;
    self.bluePlayersLabel.font = [self fontType];
    self.gameNameLabel.textColor = MA_COLOR_RED;
    self.gameNameLabel.font = [self fontType];
    [MABorderSetter setBottomBorderForView:self.cellView withColor:MA_COLOR_RED];
    [MABorderSetter setLeftBorderForView:self.cellView withColor:MA_COLOR_RED];

}

- (void)setMapTemplateWithTileColor:(NSString *)color
{
    NSString *template = [NSString stringWithFormat:@"http://mapattack-tiles-0.pdx.esri.com/%@/{z}/{y}/{x}", color];
    MKTileOverlay *overlay = [[MKTileOverlay alloc] initWithURLTemplate:template];
    overlay.canReplaceMapContent = YES;
    
    [_mapView addOverlay:overlay level:MKOverlayLevelAboveLabels];
}

- (void)setMapView:(MKMapView *)mapView {
    mapView.showsUserLocation = YES;
    
    // Join button
    UIButton *joinButton = [[UIButton alloc] initWithFrame:CGRectMake(42, kMACellExpandedHeight-100, mapView.frame.size.width * 0.75f, 66)];
    joinButton.titleLabel.font = [UIFont fontWithName:@"M41_LOVEBIT" size:24];
    joinButton.titleLabel.textColor = MA_COLOR_RED;
    joinButton.layer.borderColor = MA_COLOR_WHITE.CGColor;
    joinButton.layer.borderWidth = 2;
    
    // We'll change this in cellForRow later, if necessary
    [joinButton setTitle:@"JOIN" forState:UIControlStateNormal];
    [joinButton addTarget:self.parent action:@selector(joinGame:) forControlEvents:UIControlEventTouchUpInside];
    
    self.startButton = joinButton;
    [mapView addSubview:self.startButton
     ];
    _mapView = mapView;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
    if (selected) {
        [[MAGameManager sharedManager] fetchBoardStateForBoardId:self.board.boardId
                                                      completion:^(NSDictionary *board, NSArray *coins, NSError *error) {
                                                          if (error == nil) {
                                                              for (NSDictionary *coin in coins) {
                                                                  MACoin *annotation = [MACoin coinWithDictionary:coin];
                                                                  [self.mapView addAnnotation:annotation];
                                                              }
                                                          }
                                                      }];
        MKCoordinateRegion region = [[MAGameManager sharedManager] regionForBoard:[self.board toDictionary]];
        [self.mapView setRegion:region animated:NO];
    }
}

@end
