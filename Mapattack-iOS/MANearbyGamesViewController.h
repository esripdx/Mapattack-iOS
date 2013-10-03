//
//  MANearbyGamesViewController.h
//  Mapattack-iOS
//
//  Created by Jen on 9/18/13.
//  Copyright (c) 2013 Geoloqi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@interface MANearbyGamesViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, MKMapViewDelegate, UIAlertViewDelegate>

@property (strong, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic) int activeHeaderIndex;
@property (nonatomic) int inActiveHeaderIndex;

@end
