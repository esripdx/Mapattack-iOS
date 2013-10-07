//
//  MABorderSetter.m
//  Mapattack-iOS
//
//  Created by poeks on 10/7/13.
//  Copyright (c) 2013 Geoloqi. All rights reserved.
//

#import "MABorderSetter.h"

@implementation MABorderSetter

#pragma mark - Borders
// Set slim borders on bottom and middle
+ (void)setBorderType:(NSString *)borderType ForView:(UIView *)view withColor:(UIColor *)color
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

+ (void)setLeftBorderForView:(UIView *)view withColor:(UIColor *)color
{
    [self setBorderType:@"left" ForView:view withColor:color];
}

+ (void)setTopBorderForView:(UIView *)view withColor:(UIColor *)color
{
    [self setBorderType:@"top" ForView:view withColor:color];
}

+ (void)setBottomBorderForView:(UIView *)view withColor:(UIColor *)color
{
    [self setBorderType:@"bottom" ForView:view withColor:color];
    
}

@end
