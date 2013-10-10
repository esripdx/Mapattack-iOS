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
    // Changing this all to dark for now...
    NSString *template = [NSString stringWithFormat:@"http://mapattack-tiles-0.pdx.esri.com/%@/{z}/{y}/{x}", @"dark"];
    MKTileOverlay *overlay = [[MKTileOverlay alloc] initWithURLTemplate:template];
    overlay.canReplaceMapContent = YES;
    if ([color isEqualToString:@"blue"]) {
        self.mapView.tintColor = MA_COLOR_BLUE;
        [self.startButton setTitleColor:MA_COLOR_BLUE forState:UIControlStateNormal];
    }
    else {
        self.mapView.tintColor = MA_COLOR_RED;
        [self.startButton setTitleColor:MA_COLOR_RED forState:UIControlStateNormal];
    }
    [self.mapView addOverlay:overlay level:MKOverlayLevelAboveLabels];
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
    [joinButton addTarget:self.parent.delegate action:@selector(joinGame:) forControlEvents:UIControlEventTouchUpInside];

    CGSize btnSize = CGSizeMake(mapView.frame.size.width * 0.75f, 50);
    CGFloat btnPadding = 16;
    joinButton.frame = CGRectMake(mapView.frame.size.width/2 - btnSize.width/2, CGRectGetMaxY(mapView.bounds) - btnSize.height - btnPadding, btnSize.width, btnSize.height);

    // We'll change these in cellForRow later, if necessary
    [joinButton setTitle:@"JOIN" forState:UIControlStateNormal];
    [joinButton setTitleColor:MA_COLOR_RED forState:UIControlStateNormal];

    self.startButton = joinButton;
    [mapView addSubview:self.startButton];
    _mapView = mapView;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
    if (selected) {
        if (self.board.game.gameId) {
            // TODO: We may want to set this up to poll game state while the board is selected. Maybe not though: lotsa data and... meh.
            [[MAGameManager sharedManager] fetchGameStateForGameId:self.board.game.gameId
                                                        completion:^(NSArray *coins, NSError *error) {
                                                            if (error == nil) {
                                                                [self.mapView addAnnotations:coins];
                                                            }
                                                        }];
        } else {
            [[MAGameManager sharedManager] fetchBoardStateForBoardId:self.board.boardId
                                                          completion:^(NSDictionary *board, NSArray *coins, NSError *error) {
                                                              if (error == nil) {
                                                                  for (NSDictionary *coin in coins) {
                                                                      MACoin *annotation = [MACoin coinWithDictionary:coin];
                                                                      [self.mapView addAnnotation:annotation];
                                                                  }
                                                              }
                                                          }];
        }
        MKCoordinateRegion region = [[MAGameManager sharedManager] regionForBoard:[self.board toDictionary]];
        [self.mapView setRegion:region animated:NO];
    }
}

@end
