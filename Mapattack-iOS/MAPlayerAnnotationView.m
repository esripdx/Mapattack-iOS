//
//  MAPlayerAnnotationView.m
//  Mapattack-iOS
//
//  Created by Ryan Arana on 10/7/13.
//  Copyright (c) 2013 Geoloqi. All rights reserved.
//

#import "MAPlayerAnnotationView.h"

@implementation MAPlayerAnnotationView

- (id)initWithAnnotation:(id <MKAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
    if (self) {
        if ([annotation isKindOfClass:[MAPlayer class]]) {
            MAPlayer *player = (MAPlayer *)annotation;
            player.delegate = self;
            self.image = [player mapAvatar];
            self.centerOffset = CGPointMake(0, -self.image.size.height/2);
            self.canShowCallout = YES;
        }
    }

    return self;
}

- (void)didUpdateAvatar:(UIImage *)avatar {
    self.image = avatar;
    self.centerOffset = CGPointMake(0, -self.image.size.height/2);
}

@end
