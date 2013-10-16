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
}

- (void)styleAsInactiveBoard {
    self.cellView.backgroundColor = MA_COLOR_CREAM;
    self.playersLabel.textColor = MA_COLOR_RED;
    self.playersLabel.font = [self fontType];
    self.gameNameLabel.textColor = MA_COLOR_RED;
    self.gameNameLabel.font = [self fontType];
    [MABorderSetter setBottomBorderForView:self.cellView withColor:MA_COLOR_RED];
    [MABorderSetter setLeftBorderForView:self.cellView withColor:MA_COLOR_RED];
}

#pragma mark - Custom setters
- (void)setBoard:(MABoard *)board {
    _board = nil;
    _board = board;

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
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    if (selected) {
        [self.contentView addSubview:self.mapView];

        MKMapRect rect = [[MAGameManager sharedManager] mapRectForBoard:self.board];
        if (self.mapView.visibleMapRect.origin.x != rect.origin.x || self.mapView.visibleMapRect.origin.y != rect.origin.y) {
            CGFloat padding = 12;
            UIEdgeInsets edgePadding = UIEdgeInsetsMake(padding, padding, padding + self.mapView.frame.size.height - CGRectGetMinY(self.joinButton.frame), padding);
            [self.mapView setVisibleMapRect:rect edgePadding:edgePadding animated:NO];
        }
    }
}

@end
