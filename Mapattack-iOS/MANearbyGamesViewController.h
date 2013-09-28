//
//  MANearbyGamesViewController.h
//  Mapattack-iOS
//
//  Created by Jen on 9/18/13.
//  Copyright (c) 2013 Geoloqi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@interface MANearbyGamesViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, MKMapViewDelegate>

@property (strong, nonatomic) IBOutlet UITableView *tableView;

- (void)showGameViewController:(BOOL)created;

@end
