//
//  RootViewController.m
//  WeiboShare
//
//  Created by teng looyao on 12-9-9.
//  Copyright (c) 2012年 teng looyao. All rights reserved.
//

#import "RootViewController.h"
#import "SettingViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface RootViewController ()

@end

@implementation RootViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        
        _textView = [[UITextView alloc] initWithFrame:CGRectMake(10, 10, 300, 100)];
        _textView.contentInset = UIEdgeInsetsMake(5, 5, 5, 5);
        _textView.font = [UIFont systemFontOfSize:16];
        _textView.layer.borderColor = [UIColor grayColor].CGColor;
        _textView.layer.borderWidth = 1;
        _textView.text = @"Hello world, 这是一个测试 :)";
        
        
        _shareKit = [[TSShareKit mainShare] retain];
        _shareKit.delegate = self;
    }
    return self;
}

- (void)dealloc
{
    [_textView release];
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
    
    [self.view addSubview:_textView];
    [_textView becomeFirstResponder];
    
    self.navigationItem.title = @"微博测试";
    
    UIBarButtonItem *rightBtnItem = [[UIBarButtonItem alloc] initWithTitle:@"设置" style:UIBarButtonItemStyleBordered target:self action:@selector(settingButtonPressed:)];
    self.navigationItem.rightBarButtonItem = rightBtnItem;
    [rightBtnItem release];
    
    UIButton *sinaButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    sinaButton.frame = CGRectMake(30, 120, 120, 35);
    sinaButton.tag = 10;
    [sinaButton addTarget:self action:@selector(sendButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [sinaButton setTitle:@"发送到新浪微博" forState:UIControlStateNormal];
    [self.view addSubview:sinaButton];
    
    UIButton *txButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    txButton.frame = CGRectMake(170, 120, 120, 35);
    txButton.tag = 20;
    [txButton addTarget:self action:@selector(sendButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [txButton setTitle:@"发送到腾讯微博" forState:UIControlStateNormal];
    [self.view addSubview:txButton];
}

- (void)viewWillAppear:(BOOL)animated
{
    _shareKit.delegate = self;
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

- (void)settingButtonPressed:(id)sender
{ 
    SettingViewController *settingController = [[SettingViewController alloc] init];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:settingController];
    navController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    [self presentModalViewController:navController animated:YES];
    [settingController release];
    [navController release];
}

- (void)sendButtonPressed:(UIButton *)button
{
    _shareKit.delegate = self;
    if (button.tag == 10) {
        if ([_shareKit isAuthorized:TSShareKitTypeSina]) {
            [_shareKit sendStatus:_textView.text type:TSShareKitTypeSina latitude:0 longitude:0];
        } else {
            [_shareKit startAuthorize:TSShareKitTypeSina];
        }
    } else if (button.tag == 20) {
        if ([_shareKit isAuthorized:TSShareKitTypeTX]) {
            [_shareKit sendStatus:_textView.text type:TSShareKitTypeTX latitude:0 longitude:0];
        } else {
            [_shareKit startAuthorize:TSShareKitTypeTX];
        }
    }
}

#pragma mark - TSShareKitDelegate
- (void)shareAuthorizationStart:(TSShareKit *)shareKit type:(TSShareKitType)type
{
    [self presentModalViewController:shareKit.webViewController animated:YES];
}

- (void)shareAuthorizationFinished:(TSShareKit *)shareKit type:(TSShareKitType)type
{
    //授权成功发送微博
    [_shareKit sendStatus:_textView.text type:type latitude:0 longitude:0];
}

- (void)shareKitSendStatusFinished:(TSShareKit *)shareKit type:(TSShareKitType)type
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:@"发送成功!" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
    [alert show];
    [alert release];
}

- (void)shareKitSendStatusFailed:(TSShareKit *)shareKit type:(TSShareKitType)type
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:@"发送失败." delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
    [alert show];
    [alert release];
}

@end
