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
    if (game == nil) {
        return nil;
    }

    self = [super init];
    if (self) {
        self.gameId = game[kMAApiGameIdKey];
        if ([game[kMAApiActiveKey] boolValue]) {
            self.isActive = YES;
        } else {
            self.isActive = NO;
        }
        self.redTeamPlayers =  [game[@"red_team"] intValue];
        self.blueTeamPlayers =  [game[@"blue_team"] intValue];
        self.totalPlayers = self.redTeamPlayers + self.blueTeamPlayers;
        self.redScore = [game[kMAApiRedScoreKey] intValue];
        self.blueScore = [game[kMAApiBlueScoreKey] intValue];
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

- (NSString *)description
{
    return [NSString stringWithFormat:@"%d %@", self.totalPlayers, (self.isActive ? @"active" : @"inactive") ];
}

@end
