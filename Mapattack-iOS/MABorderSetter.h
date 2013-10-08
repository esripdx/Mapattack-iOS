//
//  MABorderSetter.h
//  Mapattack-iOS
//
//  Created by poeks on 10/7/13.
//  Copyright (c) 2013 Geoloqi. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MABorderSetter : NSObject

+ (void)setLeftBorderForView:(UIView *)view withColor:(UIColor *)color;
+ (void)setTopBorderForView:(UIView *)view withColor:(UIColor *)color;
+ (void)setBottomBorderForView:(UIView *)view withColor:(UIColor *)color;

@end
