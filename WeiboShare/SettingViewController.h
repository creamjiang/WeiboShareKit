//
//  SettingViewController.h
//  WeiboShare
//
//  Created by teng looyao on 12-9-10.
//  Copyright (c) 2012年 teng looyao. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TSShareKit.h"

@interface SettingViewController : UIViewController <TSShareKitDelegate>
{
    UIButton *sinaButton;
    UIButton *txButton;
    
    UILabel *sinaNickLabel;
    UILabel *txNickLabel;
    
    TSShareKit *_shareKit;
}

@end
