//
//  TSShareKit.h
//
//  Created by teng looyao on 12-9-4.
//
//

#import <Foundation/Foundation.h>
#import "TSShareWebViewController.h"
#import "ASIHTTPRequest.h"


///
@protocol TSShareKitDelegate;


///
@interface TSShareKit : NSObject <ASIHTTPRequestDelegate, TSShareWebViewControllerDelegate>
{
    NSMutableSet *requestSet;
}


//web授权
@property (nonatomic, retain) TSShareWebViewController *webViewController;

@property (nonatomic, assign) id<TSShareKitDelegate> delegate;

+ (TSShareKit *)mainShare;

//开始授权
- (void)startAuthorize:(TSShareKitType)type;

//获取用户昵称, 异步
- (void)getUserNick:(TSShareKitType)type;
//发布微博
- (void)sendStatus:(NSString *)status type:(TSShareKitType)type latitude:(float)latitude longitude:(float)longitude;
//发布带图片微博
- (void)sendStatus:(NSString *)status type:(TSShareKitType)type withImage:(UIImage *)image latitude:(float)latitude longitude:(float)longitude;
//验证是否授权
- (BOOL)isAuthorized:(TSShareKitType)type;
//取消授权
- (void)removeAuthorization:(TSShareKitType)type;
//检查授权是否过期
- (BOOL)authorizationExpires:(TSShareKitType)type;
@end

///
@protocol TSShareKitDelegate <NSObject>

@optional
//授权开始
- (void)shareAuthorizationStart:(TSShareKit *)shareKit type:(TSShareKitType)type;
//授权完成
- (void)shareAuthorizationFinished:(TSShareKit *)shareKit type:(TSShareKitType)type;
//授权失败
- (void)shareAuthorizationFailed:(TSShareKit *)shareKit type:(TSShareKitType)type;
//取消授权
- (void)shareAuthorizationCanceled:(TSShareKit *)shareKit type:(TSShareKitType)type;
//获取微博昵称
- (void)shareKitUserNick:(TSShareKit *)shareKit type:(TSShareKitType)type nick:(NSString *)nick;
//微博发送完成
- (void)shareKitSendStatusFinished:(TSShareKit *)shareKit type:(TSShareKitType)type;
//微博发送失败
- (void)shareKitSendStatusFailed:(TSShareKit *)shareKit type:(TSShareKitType)type;

@end