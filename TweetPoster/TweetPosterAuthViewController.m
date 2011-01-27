//
// ウェブビューとの連携によってOAuth認証を進めるビューコントローラー。
// 認証の流れについてはOAuthのドキュメントを参照すること。
//

#import "TweetPosterAuthViewController.h"
#import "TweetPosterOAuth.h"

@interface TweetPosterAuthViewController ()
- (void)fetchAsyncRequestToken;
- (void)openAuthorizePage;
- (NSString*)verifierFromURLRequest:(NSURLRequest *)request;
- (void)fetchAsyncAccessTokenWithVerifier:(NSString *)verifier;
@end

@implementation TweetPosterAuthViewController

@synthesize fetcher = fetcher_;
@synthesize webView;
@synthesize activityView;

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

- (void)viewDidLoad {
    [super viewDidLoad];
    // リクエストトークンの取得を開始する。
    [self fetchAsyncRequestToken];
}

#pragma mark OAuth Callback

- (void)didReceiveRequestToken:(OAServiceTicket*)ticket data:(NSData*)data {
    // フェッチャーはこの時点で不要になる。
    self.fetcher = nil;
    // リクエストトークンの取得結果を回収。
    NSString *httpBody = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
    OAToken *token = [[[OAToken alloc] initWithHTTPResponseBody:httpBody] autorelease];
    [TweetPosterOAuth sharedInstance].requestToken = token;
    // 認証画面をウェブビューで開く。
    [self openAuthorizePage];
}

- (void)didReceiveAccessToken:(OAServiceTicket*)ticket data:(NSData*)data {
    // フェッチャーはこの時点で不要になる。
    self.fetcher = nil;
    // アクセストークン取得結果の回収。
    NSString* httpBody = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
    OAToken *accessToken = [[[OAToken alloc] initWithHTTPResponseBody:httpBody] autorelease];
    [TweetPosterOAuth sharedInstance].accessToken = accessToken;
    // １．５秒後にクローズ（キャンセルで代用）。
    [NSTimer scheduledTimerWithTimeInterval:1.5f target:self selector:@selector(cancel) userInfo:nil repeats:NO];
}

- (void)didFailOAuth:(OAServiceTicket*)ticket error:(NSError*)error {
    // キャンセル挙動中でなければエラーの表示を行う。
    if (!cancelled_) {
        NSLog(@"didFailOAuth - %@", error);
        UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Network Error"
                                                         message:@"A network error occurred while communicating with the server."
                                                        delegate:self
                                               cancelButtonTitle:@"Back"
                                               otherButtonTitles:nil] autorelease];
        [alert show];
    }
    self.fetcher = nil;
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
        UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Network Error"
                                                         message:@"A network error occurred while communicating with the server."
                                                        delegate:self
                                               cancelButtonTitle:@"Back"
                                               otherButtonTitles:nil] autorelease];
        [alert show];
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

#pragma mark Private

- (void)fetchAsyncRequestToken {
    TweetPosterOAuth *auth = [TweetPosterOAuth sharedInstance];
    // リクエストトークンの非同期取得を開始する。
    NSURL *url = [NSURL URLWithString:@"http://api.twitter.com/oauth/request_token"];
    OAMutableURLRequest *request = [[[OAMutableURLRequest alloc] initWithURL:url
                                                                    consumer:auth.consumer
                                                                       token:nil
                                                                       realm:nil
                                                           signatureProvider:nil] autorelease];
    [request setHTTPMethod:@"POST"];
    OARequestParameter *param = [[[OARequestParameter alloc] initWithName:@"oauth_callback"
                                                                    value:@"twitter://authorized"] autorelease];
    [request setParameters:[NSArray arrayWithObject:param]];
    self.fetcher = [OAAsynchronousDataFetcher asynchronousFetcherWithRequest:request
                                                                    delegate:self
                                                           didFinishSelector:@selector(didReceiveRequestToken:data:)
                                                             didFailSelector:@selector(didFailOAuth:error:)];
    [self.fetcher start];
}

- (void)openAuthorizePage {
    // 認証ページをウェブビューで開く。
    TweetPosterOAuth *auth = [TweetPosterOAuth sharedInstance];
    NSURL *url = [NSURL URLWithString:@"https://api.twitter.com/oauth/authorize"];
    OAMutableURLRequest *request = [[[OAMutableURLRequest alloc] initWithURL:url
                                                                    consumer:nil
                                                                       token:nil
                                                                       realm:nil
                                                           signatureProvider:nil] autorelease];
    OARequestParameter *param = [[[OARequestParameter alloc] initWithName:@"oauth_token"
                                                                    value:auth.requestToken.key] autorelease];
    [request setParameters:[NSArray arrayWithObject:param]];
    [self.webView loadRequest:request];
}

- (NSString*)verifierFromURLRequest:(NSURLRequest *)request {
    // NSURLRequestからoauth_verifierを抽出する。
    NSArray *urlParams = [[[request URL] query] componentsSeparatedByString:@"&"];
    for (NSString *param in urlParams) {
        NSArray *keyValue = [param componentsSeparatedByString:@"="];
        if ([[keyValue objectAtIndex:0] isEqualToString:@"oauth_verifier"]) {
            return [keyValue objectAtIndex:1];
        }
    }
    return nil;
}

- (void)fetchAsyncAccessTokenWithVerifier:(NSString *)verifier {
    // アクセストークンの非同期取得を開始する。
    TweetPosterOAuth *auth = [TweetPosterOAuth sharedInstance];
    NSURL *url = [NSURL URLWithString:@"https://api.twitter.com/oauth/access_token"];
    OAMutableURLRequest *request = [[[OAMutableURLRequest alloc] initWithURL:url
                                                                    consumer:auth.consumer
                                                                       token:auth.requestToken
                                                                       realm:nil signatureProvider:nil] autorelease];
    [request setHTTPMethod:@"POST"];
    OARequestParameter *param = [[[OARequestParameter alloc] initWithName:@"oauth_verifier"
                                                                    value:verifier] autorelease];
    [request setParameters:[NSArray arrayWithObject:param]];
    self.fetcher = [OAAsynchronousDataFetcher asynchronousFetcherWithRequest:request
                                                                    delegate:self
                                                           didFinishSelector:@selector(didReceiveAccessToken:data:)
                                                             didFailSelector:@selector(didFailOAuth:error:)];
    [self.fetcher start];
}

@end
