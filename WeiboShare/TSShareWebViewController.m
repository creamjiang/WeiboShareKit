//
//  TSShareWebViewController.m
//
//  Created by teng looyao on 12-9-4.
//
//

#import "TSShareWebViewController.h"

@interface TSShareWebViewController ()

@end

@implementation TSShareWebViewController

@synthesize delegate;
@synthesize type;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        _webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 44, 320, 416)];
        _webView.scalesPageToFit = YES;
        _webView.delegate = self;
        
        indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    }
    return self;
}

- (void)dealloc
{
    [_webView release];
    [indicatorView release];
    [super dealloc];
}

- (void)loadView
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 460)];
    self.view = view;
    [view release];
    
    [self.view addSubview:_webView];
    
    UINavigationBar *navBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    [self.view addSubview:navBar];
    
    UINavigationItem *item = [[UINavigationItem alloc] init];
    [navBar pushNavigationItem:item animated:NO];
    
    UIBarButtonItem *buttonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(backButtonPressed:)];
    item.leftBarButtonItem = buttonItem;
    [buttonItem release];
    
    
    UIBarButtonItem *rightButtonItem = [[UIBarButtonItem alloc] initWithCustomView:indicatorView];
    item.rightBarButtonItem = rightButtonItem;
    [rightButtonItem release];
    
    [item release];
    [navBar release];
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

- (void)startRequest:(NSString *)url
{
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
    [_webView loadRequest:request];
    [request release];
}

- (void)backButtonPressed:(id)sender
{
    [_webView loadHTMLString:@"<html><head></head><body></body></html>" baseURL:nil];
    if ([delegate respondsToSelector:@selector(shareWebViewControllerCanceled:)]) {
        [delegate shareWebViewControllerCanceled:self];
    }
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - UIWebViewDelegate
- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [indicatorView stopAnimating];
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    [indicatorView startAnimating];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    [self dismissModalViewControllerAnimated:YES];
    if ([delegate respondsToSelector:@selector(shareWebViewControllerFailed:)]) {
        [delegate shareWebViewControllerFailed:self];
    }
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSString *url = request.URL.absoluteString;

    NSRange range = [url rangeOfString:@"code="];
    if (range.location != NSNotFound) {
        if ([delegate respondsToSelector:@selector(shareWebViewControllerFinished:withCode:withUid:)]) {
            
            NSString *code = [url substringFromIndex:range.location + range.length];
            
            range = [code rangeOfString:@"&"];
            if (range.location != NSNotFound) {
                code = [code substringToIndex:range.location];
            }
            
            NSString *uid = nil;
            //腾讯微博使用的是openid
            range = [url rangeOfString:@"openid="];
            if (range.location != NSNotFound) {
                uid = [url substringFromIndex:range.location + range.length];
                range = [uid rangeOfString:@"&"];
                if (range.location != NSNotFound) {
                    uid = [uid substringToIndex:range.location];
                }
            }
            
            if ([delegate respondsToSelector:@selector(shareWebViewControllerFinished:withCode:withUid:)]) {
                [delegate shareWebViewControllerFinished:self withCode:code withUid:uid];
            }
        }
        [self performSelector:@selector(dismissModalViewControllerAnimated:) withObject:[NSNumber numberWithBool:YES] afterDelay:0.5];
        [_webView loadHTMLString:@"<html><head></head><body></body></html>" baseURL:nil];
        return NO;
    }
    
    
    return YES;
}

@end
