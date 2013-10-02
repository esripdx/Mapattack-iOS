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
#import "MACoinAnnotation.h"

@implementation MAGameListCell

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

#pragma mark - Borders
// Set slim borders on bottom and middle
- (void)setBorderType:(NSString *)borderType ForView:(UIView *)view withColor:(UIColor *)color
{
    float borderWidth = 2.0f;
    float frameX = 0.0f;
    float frameY = 0.0f;
    float frameHeight = 2.0f;
    float frameWidth = view.frame.size.width;
    
    if ([borderType isEqualToString:@"top"]) {
        // 0.0f, 0.0f, view.frame.size.width, borderWidth
        frameX = 0;
        frameY = 0;
        frameWidth = view.frame.size.width;
        frameHeight = borderWidth;
    }
    if ([borderType isEqualToString:@"bottom"]) {
        // 0.0f, 43.0f, view.frame.size.width, borderWidth
        frameX = 0;
        frameY = view.frame.size.height - 5;
        frameWidth = view.frame.size.width;
        frameHeight = borderWidth;
    }
    if ([borderType isEqualToString:@"left"]) {
        // 0, 0, borderWidth, view.frame.size.height
        frameX = 235;
        frameY = 0;
        frameWidth = borderWidth;
        frameHeight = view.frame.size.height;
    }
    CALayer *border = [CALayer layer];
    
    border.frame = CGRectMake(frameX, frameY, frameWidth, frameHeight);
    border.backgroundColor = color.CGColor;
    
    [view.layer addSublayer:border];
}

- (void)setLeftBorderForView:(UIView *)view withColor:(UIColor *)color
{
    [self setBorderType:@"left" ForView:view withColor:color];
}

- (void)setTopBorderForView:(UIView *)view withColor:(UIColor *)color
{
    [self setBorderType:@"top" ForView:view withColor:color];
}

- (void)setBottomBorderForView:(UIView *)view withColor:(UIColor *)color
{
    [self setBorderType:@"bottom" ForView:view withColor:color];

}

#pragma mark - Cell Contents
- (void)setActiveBoard:(BOOL)isHeader
{
    if (isHeader) {
        [self setActiveBoardHeader];
        return;
    }
    self.cellView.backgroundColor = MA_COLOR_BODYBLUE;
    self.bluePlayersLabel.textColor = MA_COLOR_WHITE;
    self.bluePlayersLabel.font = [self fontType];
    self.gameNameLabel.textColor = MA_COLOR_WHITE;
    self.gameNameLabel.font = [self fontType];
    [self setBottomBorderForView:self.cellView withColor:MA_COLOR_WHITE];
    [self setLeftBorderForView:self.cellView withColor:MA_COLOR_WHITE];

}

- (void)setHeaderWithText:(NSString *)text andBackgroundColor:(UIColor *)bgColor andTextColor:(UIColor *)textColor
{
    
    [self.gameNameLabel removeFromSuperview];
    [self.bluePlayersLabel removeFromSuperview];
    
    CGRect viewFrame = CGRectMake(self.cellView.frame.origin.x, self.cellView.frame.origin.y, self.cellView.frame.size.width, self.cellView.frame.size.height);
    UIView *view = [[UIView alloc] initWithFrame:viewFrame];
    view.backgroundColor = bgColor;
    [self setBottomBorderForView:view withColor:textColor];

    CGRect labelFrame = CGRectMake(self.gameNameLabel.frame.origin.x, self.gameNameLabel.frame.origin.y-4, self.cellView.frame.size.width, self.cellView.frame.size.height);
    
    UILabel *label = [[UILabel alloc] initWithFrame:labelFrame];
    label.font = MA_FONT_MENSCH_HEADER;
    label.text = text;
    label.textColor = textColor;
    self.userInteractionEnabled = NO;
    
    [view addSubview:label];
    [self addSubview:view];
    
}

- (void)setActiveBoardHeader
{
    self.isActiveHeader = YES;
    [self setHeaderWithText:@"CURRENT GAMES" andBackgroundColor:MA_COLOR_BODYBLUE andTextColor:MA_COLOR_WHITE];
}

- (void)setInactiveBoard:(BOOL)isHeader
{
    if (isHeader) {
        [self setInactiveBoardHeader];
    }
    self.cellView.backgroundColor = MA_COLOR_CREAM;
    self.bluePlayersLabel.textColor = MA_COLOR_RED;
    self.bluePlayersLabel.font = [self fontType];
    self.gameNameLabel.textColor = MA_COLOR_RED;
    self.gameNameLabel.font = [self fontType];
    [self setBottomBorderForView:self.cellView withColor:MA_COLOR_RED];
    [self setLeftBorderForView:self.cellView withColor:MA_COLOR_RED];

}

- (void)setInactiveBoardHeader
{
    NSLog(@"Is INActive Board header!");
    self.isInactiveHeader = YES;
    [self setHeaderWithText:@"NEARBY BOARDS" andBackgroundColor:MA_COLOR_CREAM andTextColor:MA_COLOR_RED];
}


- (void)setMapView:(MKMapView *)mapView {
    NSString *template = @"http://mapattack-tiles-0.pdx.esri.com/dark/{z}/{y}/{x}";
    MKTileOverlay *overlay = [[MKTileOverlay alloc] initWithURLTemplate:template];
    overlay.canReplaceMapContent = YES;
    [mapView addOverlay:overlay level:MKOverlayLevelAboveLabels];
    mapView.showsUserLocation = YES;
    _mapView = mapView;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
    if (selected) {
        [[MAGameManager sharedManager] fetchBoardStateForBoardId:self.board[@"board_id"]
                                                      completion:^(NSDictionary *board, NSArray *coins, NSError *error) {
                                                          if (error == nil) {
                                                              for (NSDictionary *coin in coins) {
                                                                  CLLocationCoordinate2D coord = CLLocationCoordinate2DMake([coin[@"latitude"] doubleValue], [coin[@"longitude"] doubleValue]);
                                                                  MACoinAnnotation *annotation = [[MACoinAnnotation alloc] initWithIdentifier:coin[@"coin_id"]
                                                                                                                                   coordinate:coord
                                                                                                                                   pointValue:[coin[@"value"] integerValue]
                                                                                                                                         team:coin[@"team"]];
                                                                  [self.mapView addAnnotation:annotation];
                                                              }
                                                          }
                                                      }];
        MKCoordinateRegion region = [[MAGameManager sharedManager] regionForBoard:self.board];
        [self.mapView setRegion:region animated:NO];
    }
}

@end
