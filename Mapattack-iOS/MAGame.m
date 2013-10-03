//
//  MAGame.m
//  Mapattack-iOS
//
//  Created by poeks on 10/3/13.
//  Copyright (c) 2013 Geoloqi. All rights reserved.
//

#import "MAGame.h"

@implementation MAGame

- (id)initWithDictionary:(NSDictionary *)game
{
    if (self) {
        self.gameId = game[@"game_id"];
        self.isActive = [game[@"active"] boolValue];
        self.redTeamPlayers =  [game[@"red_team"] intValue];
        self.blueTeamPlayers =  [game[@"blue_team"] intValue];
        self.totalPlayers = self.redTeamPlayers + self.blueTeamPlayers;
        self.redScore = [game[@"red_score"] intValue];
        self.blueScore = [game[@"blue_score"] intValue];
    }
    
    return self;
}

- (NSDictionary *)toDictionary
{
    return @{
             @"game_id":self.gameId,
             @"active": [NSNumber numberWithBool:self.isActive],
             @"red_team": [NSNumber numberWithInt:self.redTeamPlayers],
             @"red_score": [NSNumber numberWithInt:self.redScore],
             @"blue_team": [NSNumber numberWithInt:self.blueTeamPlayers],
             @"blue_score": [NSNumber numberWithInt:self.blueScore],
             };
}

@end
