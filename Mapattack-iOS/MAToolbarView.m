//
//  MAToolbarView.m
//  Mapattack-iOS
//
//  Created by poeks on 10/14/13.
//  Copyright (c) 2013 Geoloqi. All rights reserved.
//

#import "MAToolbarView.h"
#import "MAAppDelegate.h"
#import "MAConstants.h"

@interface MAToolbarView ()
{
    NSInteger _previousXPos;
    NSInteger _spacing;
    NSInteger _totalWidth;
}

@property (nonatomic, strong) NSMutableArray *buttons;

@end

@implementation MAToolbarView

- (id)initWithFrame:(CGRect)frame
{
    if (self) {
        self = [super initWithFrame:frame];
        self.buttons = [[NSMutableArray alloc] init];
        _totalWidth = 320;
        _previousXPos = 0;
        _spacing = 20;
        [self addToolbarItems];
    }
    
    return self;
}

- (void)addButtonWithTitle:(NSString *)title andTarget:(id)target andMethod:(SEL)method
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    UIFont *lovebit = [UIFont fontWithName:@"M41_LOVEBIT" size:18.0f];
    
    [button addTarget:target
               action:method
     forControlEvents:UIControlEventTouchUpInside];
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:MA_COLOR_RED forState:UIControlStateNormal];
    
    NSInteger width = _spacing+([title length]*14);
    NSInteger xPos = 0;
    if ([self.buttons count] > 0) {
        xPos = _previousXPos;
        DDLogInfo(@"xPos %d = _buttonCount %d + _previousXPos %d + _spacing %d", xPos, [self.buttons count], _previousXPos, _spacing);
    } else {
        DDLogInfo(@"First button %@", title);
    }
    NSInteger yPos = 0;
    NSInteger height = kMAToolbarHeight;
    button.frame = CGRectMake(xPos, yPos, width, height);
    DDLogInfo(@"Button %@ x:%d y:%d width:%d height:%d", title, xPos, yPos, width, height);
    
    button.tintColor = MA_COLOR_CREAM;
    button.backgroundColor = MA_COLOR_CREAM;
    button.titleLabel.font = lovebit;
    button.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    
    [self.buttons addObject:button];
    [self addSubview:button];
    
    _previousXPos = width + _previousXPos + _spacing;
    
}

- (void)addToolbarItems {
    
    NSString *username = [[NSUserDefaults standardUserDefaults] objectForKey:kMADefaultsUserNameKey];
    MAAppDelegate *appDelegate = (MAAppDelegate *)[[UIApplication sharedApplication] delegate];
    UINavigationController *nav = (UINavigationController *)appDelegate.window.rootViewController;
    
    [self addButtonWithTitle:@"<" andTarget:nav andMethod:@selector(popViewControllerAnimated:)];
    [self addButtonWithTitle:username andTarget:nil andMethod:nil];
    [self addButtonWithTitle:@"abc" andTarget:nil andMethod:nil];
    [self addButtonWithTitle:@"00" andTarget:nil andMethod:nil];
    [self addButtonWithTitle:@"?" andTarget:appDelegate andMethod:@selector(halp:)];
    
//    [UIButton alloc] initWithFrame:[backButtonFrame ]l
//                            initWithTitle:@"<"
//                                                                   style:UIBarButtonItemStylePlain
//                                                                  target:nav
//                                                                  action:@selector(popViewControllerAnimated:)];
    
    // TODO: UITextAttributeFont is deprecated, but way easier to use =P We'll want to fix this later.
//    NSDictionary *barButtonAppearanceDict = @{UITextAttributeFont: lovebit};
//    [backButton setTitleTextAttributes:barButtonAppearanceDict forState:UIControlStateNormal];
//
    
    

    
    //    [[UIBarButtonItem alloc] initWithTitle:username
//                                                                       style:UIBarButtonItemStylePlain
//                                                                      target:nil action:nil];
//    [usernameButton setTitleTextAttributes:barButtonAppearanceDict forState:UIControlStateNormal];
    
    //    NSData *avatarData = [[NSUserDefaults standardUserDefaults] dataForKey:kMADefaultsAvatarKey];
    //    UIBarButtonItem *avatarButton;
    //    if (avatarData) {
    //        UIImage *avatarImage = [UIImage imageWithData:avatarData];
    //        CGFloat avatarPadding = 4;
    //        CGFloat avatarHeight = nav.toolbar.frame.size.height - (avatarPadding/2.0f);
    //        if (avatarImage.size.height > avatarHeight) {
    //            UIGraphicsBeginImageContext(CGSizeMake(avatarHeight, avatarHeight));
    //            [avatarImage drawInRect:CGRectMake(0.0, avatarPadding, avatarHeight, avatarHeight)];
    //            avatarImage = UIGraphicsGetImageFromCurrentImageContext();
    //            UIGraphicsEndImageContext();
    //        }
    //        avatarButton = [[UIBarButtonItem alloc] initWithImage:avatarImage style:UIBarButtonItemStylePlain target:nil action:nil];
    //    }
    


    //    [[UIButton alloc] initWithTitle:@"00" style:UIBarButtonItemStylePlain target:nil action:nil];
//    [scoreButton setTitleTextAttributes:barButtonAppearanceDict forState:UIControlStateNormal];
    
    
    //    [[UIBarButtonItem alloc] initWithTitle:@"?"
//                                                                   style:UIBarButtonItemStylePlain
//                                                                  target:appDelegate
//                                                                  action:@selector(halp:)];
//    [helpButton setTitleTextAttributes:barButtonAppearanceDict forState:UIControlStateNormal];

    
}

+ (void)addToView:(UIView *)view
{
    MAToolbarView *tb = [[MAToolbarView alloc] initWithFrame:[self frameForToolbar]];
    tb.backgroundColor = MA_COLOR_BODYBLUE;
    tb.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    [view addSubview:tb];
}

+ (CGRect)frameForToolbar
{
    CGFloat x = 0;
    CGFloat width = 320;

    return CGRectMake(x, 0, width, 550);
}

@end
