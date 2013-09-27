//
//  MAUserToolbar.h
//  Mapattack-iOS
//
//  Created by Jen on 9/26/13.
//  Copyright (c) 2013 Geoloqi. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MAUserToolbar : UIToolbar

@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) UIViewController *target;

- (id)initWithTarget:(UIViewController *)target;
@end
