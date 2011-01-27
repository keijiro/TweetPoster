#import "TweetPosterAuthViewController.h"
#import "TweetPosterOAuth.h"

@implementation TweetPosterAuthViewController

@synthesize fetcher = fetcher_;
@synthesize webView;
@synthesize activityView;

- (void)dealloc {
    [fetcher_ release];
    [super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // リクエストトークンの非同期取得を開始。
    TweetPosterOAuth *auth = [TweetPosterOAuth sharedInstance];
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

- (void)didReceiveRequestToken:(OAServiceTicket*)ticket data:(NSData*)data {
    // フェッチャーはこの時点で不要。
    self.fetcher = nil;
    // リクエストトークンの取得結果を回収。
    TweetPosterOAuth *auth = [TweetPosterOAuth sharedInstance];
    NSString *httpBody = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
    auth.requestToken = [[[OAToken alloc] initWithHTTPResponseBody:httpBody] autorelease];
    // 認証画面をウェブビューで開く。
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
    self.activityView.hidden = YES;
}

- (BOOL)webView:(UIWebView*)webView shouldStartLoadWithRequest:(NSURLRequest*)urlRequest navigationType:(UIWebViewNavigationType)navigationType {
	// URLのスキーム部分からコールバックであることを確認する。
    if (![[[urlRequest URL] scheme] isEqualToString:@"twitter"]) return YES;
    // oauth_verifierの抽出。
    NSString *verifier = nil;       
    NSArray *urlParams = [[[urlRequest URL] query] componentsSeparatedByString:@"&"];
    for (NSString *param in urlParams) {
        NSArray *keyValue = [param componentsSeparatedByString:@"="];
        if ([[keyValue objectAtIndex:0] isEqualToString:@"oauth_verifier"]) {
            verifier = [keyValue objectAtIndex:1];
            break;
        }
    }
    if (!verifier) return NO; // FIXME エラー処理
    // アクセストークンの非同期取得を開始。    
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
    // 既に入力は完了しているので、以後の余計なインタラクションは無効化する。
    self.webView.userInteractionEnabled = NO;
    return NO;
}

- (void)didReceiveAccessToken:(OAServiceTicket*)ticket data:(NSData*)data {
    // フェッチャーはこの時点で不要。
    self.fetcher = nil;
    // アクセストークン取得結果の回収。
    NSString* httpBody = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
    OAToken *accessToken = [[[OAToken alloc] initWithHTTPResponseBody:httpBody] autorelease];
    [TweetPosterOAuth sharedInstance].accessToken = accessToken;
    // １．５秒後にクローズ（キャンセルで代用）。
    [NSTimer scheduledTimerWithTimeInterval:1.5f target:self selector:@selector(cancel) userInfo:nil repeats:NO];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    // 何かしらロード完了したタイミングでアクティビティインジケーターは消してよい。
    [[UIApplication sharedApplication]
     setNetworkActivityIndicatorVisible:NO];
}


- (void)webViewDidStartLoad:(UIWebView *)webView {
    [[UIApplication sharedApplication]
     setNetworkActivityIndicatorVisible:YES];
}

- (void)didFailOAuth:(OAServiceTicket*)ticket error:(NSError*)error {
    // FIXME まともなエラー処理
    NSLog(@"err - %@", error);
}

- (void)webView:(UIWebView*)webView didFailLoadWithError:(NSError*)error {
    // FIXME まともなエラー処理
    NSLog(@"err - %@", error);
    [[UIApplication sharedApplication]
     setNetworkActivityIndicatorVisible:NO];
}

- (IBAction)cancel {
    [self.fetcher cancel];
    [self dismissModalViewControllerAnimated:YES];
}

@end
