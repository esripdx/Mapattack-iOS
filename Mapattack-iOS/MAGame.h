//
//  MAGame.h
//  Mapattack-iOS
//
//  Created by poeks on 10/3/13.
//  Copyright (c) 2013 Geoloqi. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MAGame : NSObject

@property (nonatomic, strong) NSString *gameId;
@property (nonatomic) BOOL isActive;
@property (nonatomic) int redTeamPlayers;
@property (nonatomic) int blueTeamPlayers;
@property (nonatomic) int totalPlayers;
@property (nonatomic) int redScore;
@property (nonatomic) int blueScore;

- (id)initWithDictionary:(NSDictionary *)game;
- (NSDictionary *)toDictionary;

@end
