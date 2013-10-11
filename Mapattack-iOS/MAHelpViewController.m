//
//  MAHelpViewController.m
//  Mapattack-iOS
//
//  Created by Jen on 9/18/13.
//  Copyright (c) 2013 Geoloqi. All rights reserved.
//

#import "MAHelpViewController.h"
#import "MAAppDelegate.h"
#import "MBProgressHUD.h"

@interface MAHelpViewController () {

    MBProgressHUD *_hud;

}

@end

@implementation MAHelpViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{

    _hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    _hud.dimBackground = YES;
    _hud.square = NO;
    _hud.labelText = @"Loading...";

    NSURL *url =[NSURL URLWithString:[NSString stringWithFormat:@"%@%@", kMapAttackWebHostname, kMAWebHelpPath]];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url];

    [self.webView setDelegate:self];
    self.webView.scrollView.delegate = self;
    self.webView.scrollView.contentInset = UIEdgeInsetsMake(-20, 0, 0, 0);
    self.webView.backgroundColor = MA_COLOR_DARKGRAY;
    [self.webView loadRequest:request];
    self.statusBarBG.alpha = 0.75;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    if (navigationType == UIWebViewNavigationTypeLinkClicked) {
        NSURL *url = request.URL;
        if ([url.host isEqualToString:@"twitter.com"]) {
            NSString *userName = request.URL.lastPathComponent;
            NSURL *nativeUrl = [NSURL URLWithString:[NSString stringWithFormat:@"twitter://user?screen_name=%@", userName]];
            if ([[UIApplication sharedApplication] canOpenURL:nativeUrl]) {
                url = nativeUrl;
            }
        }
        [[UIApplication sharedApplication] openURL:url];
        return NO;
    } else {
        return YES;
    }
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [_hud hide:YES];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.

    self.toolbarItems = [MAAppDelegate appDelegate].toolbarItems;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self.webView scrollViewDidScroll:scrollView];

    if (scrollView.contentOffset.y > 910) {
        self.statusBarBG.backgroundColor = MA_COLOR_DARKGRAY;
    } else {
        self.statusBarBG.backgroundColor = MA_COLOR_BLUE;
    }

    if (scrollView.contentOffset.y < 0) {
        scrollView.contentOffset = CGPointMake(0, 0);
    }
}

@end
