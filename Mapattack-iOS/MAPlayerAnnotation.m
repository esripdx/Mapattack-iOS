//
//  MAPlayerAnnotation.m
//  Mapattack-iOS
//
//  Created by Ryan Arana on 9/28/13.
//  Copyright (c) 2013 Geoloqi. All rights reserved.
//

#import "MAPlayerAnnotation.h"

@implementation MAPlayerAnnotation

- (UIImage *)image {
    NSData *avatarData = [[NSUserDefaults standardUserDefaults] dataForKey:kMADefaultsAvatarKey];
    UIImage *avatarImage = [UIImage imageWithData:avatarData];
    UIImage *markerImage = [UIImage imageNamed:@"player-red"];
    return markerImage;
}

@end
