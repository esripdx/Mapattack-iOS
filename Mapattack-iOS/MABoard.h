//
//  MABoard.h
//  Mapattack-iOS
//
//  Created by poeks on 10/3/13.
//  Copyright (c) 2013 Geoloqi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MAGame.h"

@interface MABoard : NSObject

//board_id
//name
//distance - meters
//bbox - [x,y,x,y]
//game

@property (nonatomic, strong) NSString *boardId;
@property (nonatomic, strong) NSString *name;
@property (nonatomic) int meters;
@property (nonatomic, strong) NSDictionary *bbox;
@property (nonatomic, strong) MAGame *game;

@property (nonatomic) int indexInBoardList;

- (id)initWithDictionary:(NSDictionary *)board;
- (NSDictionary *)toDictionary;

@end
