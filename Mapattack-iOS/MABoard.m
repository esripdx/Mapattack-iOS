//
//  MABoard.m
//  Mapattack-iOS
//
//  Created by poeks on 10/3/13.
//  Copyright (c) 2013 Geoloqi. All rights reserved.
//

#import "MABoard.h"

@implementation MABoard

- (id)initWithDictionary:(NSDictionary *)board
{
    if (self) {
        self.boardId = board[@"board_id"];
        self.name = board[@"name"];
        self.meters = [board[@"meters"] intValue];
        self.bbox = board[@"bbox"];
        self.game = [[MAGame alloc] initWithDictionary:board[@"game"]];
    }
    
    return self;
}

- (NSDictionary *)toDictionary
{
    return @{
             @"board_id":self.boardId,
             @"name":self.name,
             @"meters": [NSNumber numberWithInt:self.meters],
             @"bbox":self.bbox,
             @"game":[self.game toDictionary]
             };
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ %@", self.name, (self.game.isActive ? @"active" : @"inactive") ];
}

@end
