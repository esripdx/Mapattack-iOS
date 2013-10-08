//
//  MACoinAnnotationView.m
//  Mapattack-iOS
//
//  Created by Ryan Arana on 10/7/13.
//  Copyright (c) 2013 Geoloqi. All rights reserved.
//

#import "MACoinAnnotationView.h"
#import "MACoin.h"

@implementation MACoinAnnotationView

- (id)initWithAnnotation:(id <MKAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
    if (self) {
        if ([annotation isKindOfClass:[MACoin class]]) {
            self.coin = (MACoin *)annotation;
            self.image = self.coin.image;
            [self.coin addObserver:self forKeyPath:@"team" options:NSKeyValueObservingOptionNew context:NULL];
        }
    }

    return self;
}

- (void)dealloc {
    [self.coin removeObserver:self forKeyPath:@"team"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"team"]) {
        self.image = ((MACoin *)object).image;
    }
}

@end
