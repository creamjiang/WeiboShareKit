//
//  TSShareWebViewController.h
//
//  Created by teng looyao on 12-9-4.
//
//

#import <UIKit/UIKit.h>


typedef enum TSShareKitType_enum {
    TSShareKitTypeSina = 0,
    TSShareKitTypeTX = 1
} TSShareKitType;


@protocol TSShareWebViewControllerDelegate;

@interface TSShareWebViewController : UIViewController <UIWebViewDelegate>
{
    UIWebView *_webView;
    UIActivityIndicatorView *indicatorView;
}

@property (nonatomic, assign) TSShareKitType type;
@property (nonatomic, assign) id<TSShareWebViewControllerDelegate> delegate;

- (void)startRequest:(NSString *)url;

@end

@protocol TSShareWebViewControllerDelegate <NSObject>

@optional
- (void)shareWebViewControllerFinished:(TSShareWebViewController *)shareWebViewController withCode:(NSString *)code withUid:(NSString *)uid;
- (void)shareWebViewControllerFailed:(TSShareWebViewController *)shareWebViewController;
- (void)shareWebViewControllerCanceled:(TSShareWebViewController *)shareWebViewController;

@end