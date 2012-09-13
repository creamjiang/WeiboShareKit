//
//  SettingViewController.m
//  WeiboShare
//
//  Created by teng looyao on 12-9-10.
//  Copyright (c) 2012年 teng looyao. All rights reserved.
//

#import "SettingViewController.h"

@interface SettingViewController ()

@end

@implementation SettingViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        
        _shareKit = [[TSShareKit mainShare] retain];
        _shareKit.delegate = self;
        
        sinaNickLabel = [[UILabel alloc] initWithFrame:CGRectMake(170, 10, 130, 35)];
        sinaNickLabel.backgroundColor = [UIColor clearColor];
        
        txNickLabel = [[UILabel alloc] initWithFrame:CGRectMake(170, 60, 130, 35)];
        txNickLabel.backgroundColor = [UIColor clearColor];
        
        sinaButton = [[UIButton buttonWithType:UIButtonTypeRoundedRect] retain];
        sinaButton.frame = CGRectMake(10, 10, 150, 35);
        [sinaButton addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
        
        if ([_shareKit isAuthorized:TSShareKitTypeSina]) {
            [sinaButton setTitle:@"取消绑定新浪微博" forState:UIControlStateNormal];
            sinaButton.tag = 11;
            [_shareKit getUserNick:TSShareKitTypeSina];
        } else {
            [sinaButton setTitle:@"绑定新浪微博" forState:UIControlStateNormal];
            sinaButton.tag = 10;
        }
        
        txButton = [[UIButton buttonWithType:UIButtonTypeRoundedRect] retain];
        txButton.frame = CGRectMake(10, 60, 150, 35);
        [txButton addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
        
        if ([_shareKit isAuthorized:TSShareKitTypeTX]) {
            [txButton setTitle:@"取消绑定腾讯微博" forState:UIControlStateNormal];
            txButton.tag = 21;
            [_shareKit getUserNick:TSShareKitTypeTX];
        } else {
            [txButton setTitle:@"绑定腾讯微博" forState:UIControlStateNormal];
            txButton.tag = 20;
        }
    }
    return self;
}

- (void)dealloc
{
    [sinaButton release];
    [txButton release];
    [sinaNickLabel release];
    [txNickLabel release];
    
    _shareKit.delegate = nil;
    [_shareKit release];
    
    [super dealloc];
}

- (void)loadView
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 460)];
    self.view = view;
    [view release];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithTitle:@"返回" style:UIBarButtonItemStyleBordered target:self action:@selector(backButtonPressed:)];
    self.navigationItem.rightBarButtonItem = rightButton;
    [rightButton release];
    
    [self.view addSubview:sinaButton];
    [self.view addSubview:txButton];
    [self.view addSubview:sinaNickLabel];
    [self.view addSubview:txNickLabel];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)backButtonPressed:(id)sender
{
    [self dismissModalViewControllerAnimated:YES];
}

- (void)buttonPressed:(UIButton *)button
{
    if (button.tag == 10) {
        [_shareKit startAuthorize:TSShareKitTypeSina];
    } else if (button.tag == 11) {
        [_shareKit removeAuthorization:TSShareKitTypeSina];
        [sinaButton setTitle:@"绑定新浪微博" forState:UIControlStateNormal];
        sinaButton.tag = 10;
        sinaNickLabel.text = @"";
    } else if (button.tag == 20) {
        [_shareKit startAuthorize:TSShareKitTypeTX];
    } else if (button.tag = 21) {
        [_shareKit removeAuthorization:TSShareKitTypeTX];
        [txButton setTitle:@"绑定腾讯微博" forState:UIControlStateNormal];
        txButton.tag = 20;
        txNickLabel.text = @"";
    }
}


#pragma mark - TSShareKitDelegate
//用户授权
- (void)shareAuthorizationStart:(TSShareKit *)shareKit type:(TSShareKitType)type
{
    [self presentModalViewController:shareKit.webViewController animated:YES];
}

//授权完成, 取到Access Token
- (void)shareAuthorizationFinished:(TSShareKit *)shareKit type:(TSShareKitType)type
{
    if (type == TSShareKitTypeSina) {
        [sinaButton setTitle:@"取消绑定新浪微博" forState:UIControlStateNormal];
        sinaButton.tag = 11;
    } else if (type == TSShareKitTypeTX) {
        [txButton setTitle:@"取消绑定腾讯微博" forState:UIControlStateNormal];
        txButton.tag = 21;
    }
    
    [_shareKit getUserNick:type];
}

//获取到用户昵称
- (void)shareKitUserNick:(TSShareKit *)shareKit type:(TSShareKitType)type nick:(NSString *)nick
{
    if (type == TSShareKitTypeSina) {
        sinaNickLabel.text = nick;
    } else if (type == TSShareKitTypeTX) {
        txNickLabel.text = nick;
    }
}

@end
