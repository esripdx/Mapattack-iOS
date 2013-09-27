//
//  MALovebitTextField.m
//  Mapattack-iOS
//
//  Created by Ryan Arana on 9/27/13.
//  Copyright (c) 2013 Geoloqi. All rights reserved.
//

#import "MALovebitTextField.h"

@implementation MALovebitTextField

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (CGRect)textRectForBounds:(CGRect)bounds {
    CGRect origValue = [super textRectForBounds:bounds];

    return CGRectOffset(origValue, 0.0f, 4.0f);
}

- (CGRect)editingRectForBounds:(CGRect)bounds {
    CGRect origValue = [super textRectForBounds:bounds];

    return CGRectOffset(origValue, 0.0f, 4.0f);
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
