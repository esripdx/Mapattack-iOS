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
    self = [super init];
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
    NSMutableDictionary *dictionary = [NSMutableDictionary new];

    [dictionary setValue:self.boardId forKey:kMAApiBoardIdKey];
    [dictionary setValue:self.name forKey:kMAApiNameKey];
    [dictionary setValue:@(self.meters) forKey:@"meters"];
    [dictionary setValue:self.bbox forKey:kMAApiBoundingBoxKey];
    [dictionary setValue:[self.game toDictionary] forKey:kMAApiGameKey];

    return [NSDictionary dictionaryWithDictionary:dictionary];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ %@", self.name, (self.game.isActive ? @"active" : @"inactive") ];
}

@end
