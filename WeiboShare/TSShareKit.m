//
//  TSShareKit.m
//
//  Created by teng looyao on 12-9-4.
//
//

#import "TSShareKit.h"
#import "SBJson.h"
#import "NSString+URLEncoding.h"
#import "ASIFormDataRequest.h"

//修改为申请的新浪微博的key和secret
#define SINA_APP_KEY         @""
#define SINA_APP_SECRET      @""

#define SINA_REDIRECT_URI @""

//修改为申请的腾讯微博的key和secret
#define TX_APP_KEY           @""
#define TX_APP_SECRET        @""

#define TX_REDIREXT_URI @""

static TSShareKit *shareKit = nil;

@implementation TSShareKit

@synthesize webViewController = _webViewController;
@synthesize delegate;

+ (TSShareKit *)mainShare
{
    if (!shareKit) {
        shareKit = [[TSShareKit alloc] init];
    }
    
    return shareKit;
}

- (id)init
{
    self = [super init];
    if (self) {
        _webViewController = [[TSShareWebViewController alloc] init];
        _webViewController.delegate = self;
        requestSet = [[NSMutableSet set] retain];
    }
    return self;
}

- (void)dealloc
{
    [[requestSet allObjects] makeObjectsPerformSelector:@selector(clearDelegatesAndCancel)];
    [requestSet release];
    [_webViewController release];
    [super dealloc];
}

#pragma mark - 开始授权
- (void)startAuthorize:(TSShareKitType)type
{
    _webViewController.type = type;
    [_webViewController startRequest:[self urlOfAuthorization:type]];
    if ([delegate respondsToSelector:@selector(shareAuthorizationStart:type:)]) {
        [delegate shareAuthorizationStart:self type:type];
    }
}

- (NSString *)urlOfAuthorization:(TSShareKitType)type
{
    NSString *url = nil;
    switch (type) {
        case TSShareKitTypeSina:
            url = [NSString stringWithFormat:@"https://api.weibo.com/oauth2/authorize?client_id=%@&response_type=code&redirect_uri=%@", SINA_APP_KEY, SINA_REDIRECT_URI];
            break;
        case TSShareKitTypeTX:
            url = [NSString stringWithFormat:@"https://open.t.qq.com/cgi-bin/oauth2/authorize?client_id=%@&response_type=code&redirect_uri=%@", TX_APP_KEY, TX_REDIREXT_URI];
            break;
            
        default:
            break;
    }
    return url;
}

#pragma mark - 判断是否已经授权
- (BOOL)isAuthorized:(TSShareKitType)type
{
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    
    if (type == TSShareKitTypeSina) {
        NSString *accessToken = [userDefault objectForKey:@"SinaAccessToken"];
        if (accessToken) {
            if (![self authorizationExpires:type]) {
                return YES;
            }
        }
    } else if (type == TSShareKitTypeTX) {
        NSString *accessToken = [userDefault objectForKey:@"TXAccessToken"];
        if (accessToken) {
            if (![self authorizationExpires:type]) {
                return YES;
            }
        }
    }
    
    return NO;
}

#pragma mark - 取消授权
- (void)removeAuthorization:(TSShareKitType)type
{
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    if (type == TSShareKitTypeSina) {
        [userDefault removeObjectForKey:@"SinaAccessToken"];
        [userDefault removeObjectForKey:@"SinaExpiresIn"];
        [userDefault removeObjectForKey:@"SinaAuthorizedTime"];
        [userDefault removeObjectForKey:@"SinaUid"];
        [userDefault removeObjectForKey:@"SinaNick"];
        [userDefault synchronize];
    } else if (type == TSShareKitTypeTX) {
        [userDefault removeObjectForKey:@"TXAccessToken"];
        [userDefault removeObjectForKey:@"TXExpiresIn"];
        [userDefault removeObjectForKey:@"TXAuthorizedTime"];
        [userDefault removeObjectForKey:@"TXUid"];
        [userDefault removeObjectForKey:@"TXNick"];
        [userDefault synchronize];
    }
}

#pragma mark - 获取微博昵称
- (void)getUserNick:(TSShareKitType)type
{
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    if (type == TSShareKitTypeSina) {
        NSString *nick = [userDefault objectForKey:@"SinaNick"];
        
        if (nick) {
            if ([delegate respondsToSelector:@selector(shareKitUserNick:type:nick:)]) {
                [delegate shareKitUserNick:self type:type nick:nick];
            }
        } else {
            NSString *accessToken = [userDefault objectForKey:@"SinaAccessToken"];
            NSString *uid = [userDefault objectForKey:@"SinaUid"];
            if (accessToken && uid) {
                NSString *url = [NSString stringWithFormat:@"https://api.weibo.com/2/users/show.json?access_token=%@&uid=%@", accessToken, uid];
                
                ASIHTTPRequest *request = [[ASIHTTPRequest alloc] initWithURL:[NSURL URLWithString:url]];
                request.useCookiePersistence = NO;
                request.validatesSecureCertificate = NO;
                request.delegate = self;
                [request setDidFinishSelector:@selector(requestNickFinished:)];
                [request setDidFailSelector:@selector(requestNickFailed:)];
                request.tag = type;
                [request startAsynchronous];
                [request release];
            }
        }
    } else if (type == TSShareKitTypeTX) {
        //腾讯的昵称不需要单独请求, 在OAuth验证的时候可以获取
        NSString *nick = [userDefault objectForKey:@"TXNick"];
        if (nick) {
            if ([delegate respondsToSelector:@selector(shareKitUserNick:type:nick:)]) {
                [delegate shareKitUserNick:self type:type nick:nick];
            }
        }
    }
}

#pragma mark - 检查时候验证已过期
- (BOOL)authorizationExpires:(TSShareKitType)type
{
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    if (type == TSShareKitTypeSina) {
        if ([userDefault objectForKey:@"SinaExpiresIn"]) {
            NSTimeInterval expires_in = [[userDefault objectForKey:@"SinaExpiresIn"] doubleValue];
            NSTimeInterval authorizedTime = [[userDefault objectForKey:@"SinaAuthorizedTime"] doubleValue];
            if ([NSDate timeIntervalSinceReferenceDate] - authorizedTime < expires_in) {
                return NO;
            }
        }
    } else if (type == TSShareKitTypeTX) {
        if ([userDefault objectForKey:@"TXExpiresIn"]) {
            NSTimeInterval expires_in = [[userDefault objectForKey:@"TXExpiresIn"] doubleValue];
            NSTimeInterval authorizedTime = [[userDefault objectForKey:@"TXAuthorizedTime"] doubleValue];
            if ([NSDate timeIntervalSinceReferenceDate] - authorizedTime < expires_in) {
                return NO;
            }
        }
    }
    
    return YES;
}

#pragma mark - 发文字微博
- (void)sendStatus:(NSString *)status type:(TSShareKitType)type latitude:(float)latitude longitude:(float)longitude
{
    if (type == TSShareKitTypeSina) {
        NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
        NSString *accessToken = [userDefault objectForKey:@"SinaAccessToken"];
        
        if (accessToken) {
            NSString *url = @"https://api.weibo.com/2/statuses/update.json";
            
            if (![self authorizationExpires:type]) {
                //按照要求拼凑请求的报文
                ASIFormDataRequest *request = [[ASIFormDataRequest alloc] initWithURL:[NSURL URLWithString:url]];
                request.useCookiePersistence = NO;
                request.validatesSecureCertificate = NO;
                request.requestMethod = @"POST";
                [request setPostFormat:ASIURLEncodedPostFormat];
                [request setPostValue:status forKey:@"status"];
                [request setPostValue:accessToken forKey:@"access_token"];
                [request setPostValue:[NSNumber numberWithFloat:latitude] forKey:@"lat"];
                [request setPostValue:[NSNumber numberWithFloat:longitude] forKey:@"long"];
                request.delegate = self;
                [request setDidFinishSelector:@selector(requestSendStatusFinished:)];
                [request setDidFailSelector:@selector(requestSendStatusFailed:)];
                request.tag = type;
                [request startAsynchronous];
                [requestSet addObject:request];
                [request release];
            }
        }
    } else if (type == TSShareKitTypeTX) {
        NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
        NSString *accessToken = [userDefault objectForKey:@"TXAccessToken"];
        NSString *uid = [userDefault objectForKey:@"TXUid"];
        if (accessToken && uid) {
            NSString *url = @"https://open.t.qq.com/api/t/add";
            
            if (![self authorizationExpires:type]) {
                //按照文档要求拼凑报文
                ASIFormDataRequest *request = [[ASIFormDataRequest alloc] initWithURL:[NSURL URLWithString:url]];
                request.validatesSecureCertificate = NO;
                request.useCookiePersistence = NO;
                request.requestMethod = @"POST";
                request.postFormat = ASIMultipartFormDataPostFormat;
                [request setPostValue:@"json" forKey:@"format"];
                [request setPostValue:status forKey:@"content"];
                [request setPostValue:TX_APP_KEY forKey:@"oauth_consumer_key"];
                [request setPostValue:@"2.a" forKey:@"oauth_version"];
                [request setPostValue:@"all" forKey:@"scope"];
                [request setPostValue:accessToken forKey:@"access_token"];
                [request setPostValue:uid forKey:@"openid"];
                [request setPostValue:@"113.108.31.14" forKey:@"clientip"];
                [request setPostValue:[NSNumber numberWithFloat:latitude] forKey:@"latitude"];
                [request setPostValue:[NSNumber numberWithFloat:longitude] forKey:@"longitude"];
                request.delegate = self;
                [request setDidFinishSelector:@selector(requestSendStatusFinished:)];
                [request setDidFailSelector:@selector(requestSendStatusFailed:)];
                request.tag = type;
                [request startAsynchronous];
                [requestSet addObject:request];
                [request release];
            }
        }
    }
}

#pragma mark - 发带图片的微博
- (void)sendStatus:(NSString *)status type:(TSShareKitType)type withImage:(UIImage *)image latitude:(float)latitude longitude:(float)longitude
{
    NSData *data = UIImageJPEGRepresentation(image, 0.5);
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    if (type == TSShareKitTypeSina) {
        
        NSString *accessToken = [userDefault objectForKey:@"SinaAccessToken"];
        
        if (accessToken) {
            NSString *url = @"https://upload.api.weibo.com/2/statuses/upload.json";
            if (![self authorizationExpires:type]) {
                
                ASIFormDataRequest *request = [[ASIFormDataRequest alloc] initWithURL:[NSURL URLWithString:url]];
                [request setValidatesSecureCertificate:NO];
                request.requestMethod = @"POST";
                [request setPostFormat:ASIMultipartFormDataPostFormat];
                [request setPostValue:accessToken forKey:@"access_token"];
                [request setPostValue:[status URLEncodedString] forKey:@"status"];
                [request setPostValue:[NSNumber numberWithFloat:latitude] forKey:@"lat"];
                [request setPostValue:[NSNumber numberWithFloat:longitude] forKey:@"long"];
                [request setData:data withFileName:@"image.jpg" andContentType:@"Content-Type: image/jpeg" forKey:@"pic"];
                request.delegate = self;
                [request setDidFinishSelector:@selector(requestSendStatusWithPicFinished:)];
                [request setDidFailSelector:@selector(requestSendStatusWithPicFailed:)];
                request.tag = type;
                [request startAsynchronous];
                [requestSet addObject:request];
                [request release];
            }
        }
    } else if (type == TSShareKitTypeTX) {
        NSString *accessToken = [userDefault objectForKey:@"TXAccessToken"];
        NSString *uid = [userDefault objectForKey:@"TXUid"];
        if (accessToken && uid) {
            
            NSString *url = @"https://open.t.qq.com/api/t/add_pic";
            
            if (![self authorizationExpires:type]) {
                //按照文档要求拼凑报文
                ASIFormDataRequest *request = [[ASIFormDataRequest alloc] initWithURL:[NSURL URLWithString:url]];
                request.validatesSecureCertificate = NO;
                request.useCookiePersistence = NO;
                request.requestMethod = @"POST";
                request.postFormat = ASIMultipartFormDataPostFormat;
                [request setPostValue:@"json" forKey:@"format"];
                [request setPostValue:status forKey:@"content"];
                [request setPostValue:TX_APP_KEY forKey:@"oauth_consumer_key"];
                [request setPostValue:@"2.a" forKey:@"oauth_version"];
                [request setPostValue:@"all" forKey:@"scope"];
                [request setPostValue:accessToken forKey:@"access_token"];
                [request setPostValue:uid forKey:@"openid"];
                [request setPostValue:@"113.108.31.14" forKey:@"clientip"];
                [request setPostValue:[NSNumber numberWithFloat:latitude] forKey:@"latitude"];
                [request setPostValue:[NSNumber numberWithFloat:longitude] forKey:@"longitude"];
                [request setData:data withFileName:@"image.jpg" andContentType:@"Content-Type: image/jpeg" forKey:@"pic"];
                request.delegate = self;
                [request setDidFinishSelector:@selector(requestSendStatusWithPicFinished:)];
                [request setDidFailSelector:@selector(requestSendStatusWithPicFailed:)];
                request.tag = type;
                [request startAsynchronous];
                [requestSet addObject:request];
                [request release];
            }
        }
    }
}

#pragma mark - TSShareWebViewControllerDelegate
- (void)shareWebViewControllerFinished:(TSShareWebViewController *)shareWebViewController withCode:(NSString *)code withUid:(NSString *)uid
{
    //请求access token
    NSString *url = nil;
    TSShareKitType type = shareWebViewController.type;
    switch (type) {
        case TSShareKitTypeSina:
            url = [NSString stringWithFormat:@"https://api.weibo.com/oauth2/access_token?client_id=%@&client_secret=%@&grant_type=authorization_code&redirect_uri=%@&code=%@", SINA_APP_KEY, SINA_APP_SECRET, SINA_REDIRECT_URI, code];
            break;
        case TSShareKitTypeTX:
        {
            NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
            if (uid) {
                [userDefault setObject:uid forKey:@"TXUid"];
                [userDefault synchronize];
            }
            
            url = [NSString stringWithFormat:@"https://open.t.qq.com/cgi-bin/oauth2/access_token?client_id=%@&client_secret=%@&redirect_uri=%@&grant_type=authorization_code&code=%@", TX_APP_KEY, TX_APP_SECRET, TX_REDIREXT_URI, code];
        }
            break;
            
        default:
            break;
    }
    
    ASIHTTPRequest *request = [[ASIHTTPRequest alloc] initWithURL:[NSURL URLWithString:url]];
    request.validatesSecureCertificate = NO;
    request.useCookiePersistence = NO;
    request.delegate = self;
    [request setDidFinishSelector:@selector(requestAccessTokenFinished:)];
    [request setDidFailSelector:@selector(requestAccessTokenFailed:)];
    request.requestMethod = @"POST";
    request.tag = type;
    [request startAsynchronous];
    [requestSet addObject:request];
    [request release];
}

- (void)shareWebViewControllerCanceled:(TSShareWebViewController *)shareWebViewController
{
    if ([delegate respondsToSelector:@selector(shareAuthorizationCanceled:type:)]) {
        [delegate shareAuthorizationCanceled:self type:shareWebViewController.type];
    }
}

#pragma mark - 获取AccessToken  delegate
- (void)requestAccessTokenFinished:(ASIHTTPRequest *)request
{
    TSShareKitType type = request.tag;
    
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    if (type == TSShareKitTypeSina) {
        SBJsonParser *parser = [[SBJsonParser alloc] init];
        id jsonObj = [parser objectWithData:request.responseData];
        if ([jsonObj isKindOfClass:[NSDictionary class]]) {
            id accessToken = [jsonObj objectForKey:@"access_token"];
            id expiresIn = [jsonObj objectForKey:@"expires_in"];
            id uid = [jsonObj objectForKey:@"uid"];
            if (accessToken && expiresIn && uid) {
                //保存授权信息
                [userDefault setObject:accessToken forKey:@"SinaAccessToken"];
                [userDefault setObject:expiresIn forKey:@"SinaExpiresIn"];
                [userDefault setObject:uid forKey:@"SinaUid"];
                [userDefault setObject:[NSString stringWithFormat:@"%f", [NSDate timeIntervalSinceReferenceDate]] forKey:@"SinaAuthorizedTime"];
                [userDefault synchronize];
                
                if ([delegate respondsToSelector:@selector(shareAuthorizationFinished:type:)]) {
                    [delegate shareAuthorizationFinished:self type:type];
                }
            } else {
                if ([delegate respondsToSelector:@selector(shareAuthorizationFailed:type:)]) {
                    [delegate shareAuthorizationFailed:self type:type];
                }
            }
        }
        [parser release];
    } else if (type == TSShareKitTypeTX) {
        NSRange range = [request.responseString rangeOfString:@"access_token="];
        if (range.location == NSNotFound) {
            if ([delegate respondsToSelector:@selector(shareAuthorizationFailed:type:)]) {
                [delegate shareAuthorizationFailed:self type:type];
            }
            return;
        }
        NSString *accessToken = [request.responseString substringFromIndex:range.location + range.length];
        range = [accessToken rangeOfString:@"&"];
        if (range.location != NSNotFound) {
            accessToken = [accessToken substringToIndex:range.location];
        }
        
        range = [request.responseString rangeOfString:@"expires_in="];
        if (range.location == NSNotFound) {
            if ([delegate respondsToSelector:@selector(shareAuthorizationFailed:type:)]) {
                [delegate shareAuthorizationFailed:self type:type];
            }
            return;
        }
        NSString *expiresIn = [request.responseString substringFromIndex:range.location + range.length];
        range = [expiresIn rangeOfString:@"&"];
        if (range.location != NSNotFound) {
            expiresIn = [expiresIn substringToIndex:range.location];
        }
        
        range = [request.responseString rangeOfString:@"nick="];
        if (range.location == NSNotFound) {
            if ([delegate respondsToSelector:@selector(shareAuthorizationFailed:type:)]) {
                [delegate shareAuthorizationFailed:self type:type];
            }
            return;
        }
        NSString *nick = [request.responseString substringFromIndex:range.location + range.length];
        range = [nick rangeOfString:@"&"];
        if (range.location != NSNotFound) {
            nick = [nick substringToIndex:range.location];
        }
        
        [userDefault setObject:accessToken forKey:@"TXAccessToken"];
        [userDefault setObject:expiresIn forKey:@"TXExpiresIn"];
        [userDefault setObject:nick forKey:@"TXNick"];
        [userDefault setObject:[NSString stringWithFormat:@"%f", [NSDate timeIntervalSinceReferenceDate]] forKey:@"TXAuthorizedTime"];
        [userDefault synchronize];
        if ([delegate respondsToSelector:@selector(shareAuthorizationFinished:type:)]) {
            [delegate shareAuthorizationFinished:self type:type];
        }
    }
    
    [requestSet removeObject:request];
}

- (void)requestAccessTokenFailed:(ASIHTTPRequest *)request
{
    TSShareKitType type = request.tag;
    if ([delegate respondsToSelector:@selector(shareAuthorizationFailed:type:)]) {
        [delegate shareAuthorizationFailed:self type:type];
    }
    
    [requestSet removeObject:request];
}

#pragma mark - 获取微博昵称 delegate
- (void)requestNickFinished:(ASIHTTPRequest *)request
{
    TSShareKitType type = request.tag;
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    if (type == TSShareKitTypeSina) {
        SBJsonParser *parser = [[SBJsonParser alloc] init];
        id jsonObj = [parser objectWithData:request.responseData];
        if ([jsonObj isKindOfClass:[NSDictionary class]]) {
            NSString *nick = [jsonObj objectForKey:@"screen_name"];
            if (nick) {
                [userDefault setObject:nick forKey:@"SinaNick"];
                [userDefault synchronize];
                if ([delegate respondsToSelector:@selector(shareKitUserNick:type:nick:)]) {
                    [delegate shareKitUserNick:self type:type nick:nick];
                }
            }
        }
        [parser release];
    }
    [requestSet removeObject:request];
}

- (void)requestNickFailed:(ASIHTTPRequest *)request
{
    [requestSet removeObject:request];
}

#pragma mark - 发送微博 delegate
- (void)requestSendStatusFinished:(ASIHTTPRequest *)request
{
    TSShareKitType type = request.tag;
    if (request == TSShareKitTypeSina) {
        BOOL success = NO;
        SBJsonParser *parser = [[SBJsonParser alloc] init];
        id jsonObj = [parser objectWithData:request.responseData];
        if ([jsonObj isKindOfClass:[NSDictionary class]]) {
            if (![jsonObj objectForKey:@"error"]) {
                success = YES;
            }
        }
        [parser release];
        
        if (success) {
            if ([delegate respondsToSelector:@selector(shareKitSendStatusFinished:type:)]) {
                [delegate shareKitSendStatusFinished:self type:type];
            }
        } else {
            if ([delegate respondsToSelector:@selector(shareKitSendStatusFailed:type:)]) {
                [delegate shareKitSendStatusFailed:self type:type];
            }
        }
    } else if (type == TSShareKitTypeTX) {
        SBJsonParser *parser = [[SBJsonParser alloc] init];
        id jsonObj = [parser objectWithData:request.responseData];
        
        BOOL success = NO;
        if ([jsonObj isKindOfClass:[NSDictionary class]]) {
            id errcode = [jsonObj objectForKey:@"errcode"];
            if ([errcode isKindOfClass:[NSString class]] || [errcode isKindOfClass:[NSNumber class]]) {
                if ([errcode intValue] == 0) {
                    success = YES;
                }
            }
        }
        
        if (success) {
            if ([delegate respondsToSelector:@selector(shareKitSendStatusFinished:type:)]) {
                [delegate shareKitSendStatusFinished:self type:type];
            }
        } else {
            if ([delegate respondsToSelector:@selector(shareKitSendStatusFailed:type:)]) {
                [delegate shareKitSendStatusFailed:self type:type];
            }
        }
        
        [parser release];
    }
    [requestSet removeObject:request];
}

- (void)requestSendStatusFailed:(ASIHTTPRequest *)request
{
    TSShareKitType type = request.tag;
    if ([delegate respondsToSelector:@selector(shareKitSendStatusFailed:type:)]) {
        [delegate shareKitSendStatusFailed:self type:type];
    }
    [requestSet removeObject:request];
}

#pragma mark - 发送图片微博 delegate
- (void)requestSendStatusWithPicFinished:(ASIHTTPRequest *)request
{
    TSShareKitType type = request.tag;
    
    if (type == TSShareKitTypeSina) {
        BOOL success = NO;
        SBJsonParser *parser = [[SBJsonParser alloc] init];
        id jsonObj = [parser objectWithData:request.responseData];
        if ([jsonObj isKindOfClass:[NSDictionary class]]) {
            if (![jsonObj objectForKey:@"error"]) {
                success = YES;
            }
        }
        [parser release];
        
        if (success) {
            if ([delegate respondsToSelector:@selector(shareKitSendStatusFinished:type:)]) {
                [delegate shareKitSendStatusFinished:self type:type];
            }
        } else {
            if ([delegate respondsToSelector:@selector(shareKitSendStatusFailed:type:)]) {
                [delegate shareKitSendStatusFailed:self type:type];
            }
        }
    } else if (type == TSShareKitTypeTX) {
        SBJsonParser *parser = [[SBJsonParser alloc] init];
        id jsonObj = [parser objectWithData:request.responseData];
        
        BOOL success = NO;
        if ([jsonObj isKindOfClass:[NSDictionary class]]) {
            id errcode = [jsonObj objectForKey:@"errcode"];
            if ([errcode isKindOfClass:[NSString class]] || [errcode isKindOfClass:[NSNumber class]]) {
                if ([errcode intValue] == 0) {
                    success = YES;
                }
            }
        }
        
        if (success) {
            if ([delegate respondsToSelector:@selector(shareKitSendStatusFinished:type:)]) {
                [delegate shareKitSendStatusFinished:self type:type];
            }
        } else {
            if ([delegate respondsToSelector:@selector(shareKitSendStatusFailed:type:)]) {
                [delegate shareKitSendStatusFailed:self type:type];
            }
        }
        
        [parser release];
    }
    
    [requestSet removeObject:request];
}

- (void)requestSendStatusWithPicFailed:(ASIHTTPRequest *)request
{
    TSShareKitType type = request.tag;
    if ([delegate respondsToSelector:@selector(shareKitSendStatusFailed:type:)]) {
        [delegate shareKitSendStatusFailed:self type:type];
    }
    
    [requestSet removeObject:request];
}

@end
