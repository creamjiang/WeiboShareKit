//
//  RootViewController.h
//  WeiboShare
//
//  Created by teng looyao on 12-9-9.
//  Copyright (c) 2012年 teng looyao. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TSShareKit.h"

@interface RootViewController : UIViewController <TSShareKitDelegate>
{
    UITextView *_textView;
    TSShareKit *_shareKit;
}

@end
