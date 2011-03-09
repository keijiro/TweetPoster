#import "TPAuthenticationViewController.h"
#import "TPSession.h"

#pragma mark Private declarations

@interface TPAuthenticationViewController (Private)
- (void)fetchAsyncRequestToken;
- (void)openAuthorizePage;
- (NSString *)verifierFromURLRequest:(NSURLRequest *)request;
- (void)fetchAsyncAccessTokenWithVerifier:(NSString *)verifier;
- (void)showCommonAlert;
@end

#pragma mark -

@implementation TPAuthenticationViewController

@synthesize fetcher = fetcher_;
@synthesize webView;
@synthesize activityView;

#pragma mark Initialization and cleanup

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        cancelled_ = NO;
    }
    return self;
}

- (void)dealloc {
    [fetcher_ release];
    [super dealloc];
}

#pragma mark UIViewController methods

- (void)viewDidLoad {
    [super viewDidLoad];
    // リクエストトークンの取得を開始する。
    [self fetchAsyncRequestToken];
}

#pragma mark Private methods

// リクエストトークンの非同期取得を開始する。
- (void)fetchAsyncRequestToken {
    TPSession *session = [TPSession sharedInstance];
    
    NSURL *url = [NSURL URLWithString:@"http://api.twitter.com/oauth/request_token"];

    OAMutableURLRequest *request = [[[OAMutableURLRequest alloc] initWithURL:url
                                                                    consumer:session.consumer
                                                                       token:nil
                                                                       realm:nil
                                                           signatureProvider:nil] autorelease];
    [request setHTTPMethod:@"POST"];
    
    OARequestParameter *param = [[[OARequestParameter alloc] initWithName:@"oauth_callback"
                                                                    value:@"twitter://authorized"] autorelease];
    [request setParameters:[NSArray arrayWithObject:param]];
    
    TPFetcherResultBlock resultBlock = ^(OAServiceTicket *ticket, NSData *data) {
        self.fetcher = nil; // release
        // リクエストトークンの取得結果を回収。
        NSString *httpBody = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
        OAToken *token = [[[OAToken alloc] initWithHTTPResponseBody:httpBody] autorelease];
        session.requestToken = token;
        // 認証画面をウェブビューで開く。
        [self openAuthorizePage];
    };
    
    TPFetcherFailureBlock failureBlock = ^(OAServiceTicket *ticket, NSError *error) {
        self.fetcher = nil; // release
        // キャンセル挙動中でなければエラーの表示を行う。
        if (!cancelled_) {
            NSLog(@"didFailOAuth - %@", error);
            [self showCommonAlert];
        }
    };
    
    self.fetcher = [TPAsynchronousDataFetcher asynchronousFetcherWithRequest:request resultBlock:resultBlock failureBlock:failureBlock];
    [self.fetcher start];
}

// 認証ページをウェブビューで開く。
- (void)openAuthorizePage {
    TPSession *session = [TPSession sharedInstance];
    
    NSURL *url = [NSURL URLWithString:@"https://api.twitter.com/oauth/authorize"];

    OAMutableURLRequest *request = [[[OAMutableURLRequest alloc] initWithURL:url
                                                                    consumer:nil
                                                                       token:nil
                                                                       realm:nil
                                                           signatureProvider:nil] autorelease];
    
    OARequestParameter *param = [[[OARequestParameter alloc] initWithName:@"oauth_token"
                                                                    value:session.requestToken.key] autorelease];
    [request setParameters:[NSArray arrayWithObject:param]];
    
    [self.webView loadRequest:request];
}

// NSURLRequestからoauth_verifierを抽出する。
- (NSString*)verifierFromURLRequest:(NSURLRequest *)request {
    NSArray *urlParams = [[[request URL] query] componentsSeparatedByString:@"&"];
    for (NSString *param in urlParams) {
        NSArray *keyValue = [param componentsSeparatedByString:@"="];
        if ([[keyValue objectAtIndex:0] isEqualToString:@"oauth_verifier"]) {
            return [keyValue objectAtIndex:1];
        }
    }
    return nil;
}

// アクセストークンの非同期取得を開始する。
- (void)fetchAsyncAccessTokenWithVerifier:(NSString *)verifier {
    TPSession *session = [TPSession sharedInstance];
    
    NSURL *url = [NSURL URLWithString:@"https://api.twitter.com/oauth/access_token"];
    
    OAMutableURLRequest *request = [[[OAMutableURLRequest alloc] initWithURL:url
                                                                    consumer:session.consumer
                                                                       token:session.requestToken
                                                                       realm:nil signatureProvider:nil] autorelease];
    [request setHTTPMethod:@"POST"];
    
    OARequestParameter *param = [[[OARequestParameter alloc] initWithName:@"oauth_verifier"
                                                                    value:verifier] autorelease];
    [request setParameters:[NSArray arrayWithObject:param]];
    
    TPFetcherResultBlock resultBlock = ^(OAServiceTicket *ticket, NSData *data) {
        self.fetcher = nil; // release
        // アクセストークン取得結果の回収。
        NSString* httpBody = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
        OAToken *accessToken = [[[OAToken alloc] initWithHTTPResponseBody:httpBody] autorelease];
        session.accessToken = accessToken;
        // 2.5秒後にクローズ（キャンセルで代用）。
        [NSTimer scheduledTimerWithTimeInterval:2.5f target:self selector:@selector(cancel) userInfo:nil repeats:NO];
    };
    
    TPFetcherFailureBlock failureBlock = ^(OAServiceTicket *ticket, NSError *error) {
        self.fetcher = nil; // release
        // キャンセル挙動中でなければエラーの表示を行う。
        if (!cancelled_) {
            NSLog(@"didFailOAuth - %@", error);
            [self showCommonAlert];
        }
    };
    
    self.fetcher = [TPAsynchronousDataFetcher asynchronousFetcherWithRequest:request resultBlock:resultBlock failureBlock:failureBlock];
    [self.fetcher start];
}

// 共通エラーメッセージの表示。
- (void)showCommonAlert {
    UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Network Error"
                                                     message:@"A network error occurred while communicating with the server."
                                                    delegate:self
                                           cancelButtonTitle:@"Back"
                                           otherButtonTitles:nil] autorelease];
    [alert show];
}

#pragma mark UIWebViewDelegate

- (BOOL)webView:(UIWebView*)webView shouldStartLoadWithRequest:(NSURLRequest*)urlRequest navigationType:(UIWebViewNavigationType)navigationType {
	// URLのスキーム部分の判定によって、Twitterからのコールバックであることを確認する。
    if ([[[urlRequest URL] scheme] isEqualToString:@"twitter"]) {
        // アクセストークンの取得を開始する。
        [self fetchAsyncAccessTokenWithVerifier:[self verifierFromURLRequest:urlRequest]];
        return NO;
    }
    return YES;
}

- (void)webView:(UIWebView*)webView didFailLoadWithError:(NSError*)error {
    // キャンセル挙動中でなければエラーの表示を行う。
    if (!cancelled_) {
        NSLog(@"didFailLoadWithError - %@", error);
        [self showCommonAlert];
    }
    // インジケーターを消す。
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    self.activityView.hidden = YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    // インジケーターを消す。
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    self.activityView.hidden = YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    // インジケーターを出す。
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    self.activityView.hidden = NO;
}

#pragma mark UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    // そのままキャンセル挙動に繋ぐ。
    [self cancel];
}

#pragma mark IBAction

- (IBAction)cancel {
    cancelled_ = YES;
    [self.webView stopLoading];
    [self.fetcher cancel];
    [self dismissModalViewControllerAnimated:YES];
}

@end
