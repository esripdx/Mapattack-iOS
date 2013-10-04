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
        self.boardId = board[kMAApiBoardIdKey];
        self.name = board[kMAApiNameKey];
        self.meters = [board[@"meters"] intValue];
        self.bbox = board[kMAApiBoundingBoxKey];
        self.game = [[MAGame alloc] initWithDictionary:board[kMAApiGameKey]];
    }
    
    return self;
}

- (NSDictionary *)toDictionary
{
    return @{
             kMAApiBoardIdKey:self.boardId,
             kMAApiNameKey:self.name,
             @"meters": [NSNumber numberWithInt:self.meters],
             kMAApiBoundingBoxKey:self.bbox,
             kMAApiGameKey:[self.game toDictionary]
             };
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ %@", self.name, (self.game.isActive ? @"active" : @"inactive") ];
}

@end
