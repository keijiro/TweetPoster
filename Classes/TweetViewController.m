#import "TweetViewController.h"
#import <QuartzCore/QuartzCore.h>

static NSString* kAccessKeyStore = @"TwitterAccessKey";
static NSString* kAccessSecretStore = @"TwitterAccessSecret";

static NSString* kConsumerKey = @"xxxxxxxxxxxxxxxxxxxx";
static NSString* kConsumerSecret = @"xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx";

@implementation TweetViewController

@synthesize consumer;
@synthesize requestToken;
@synthesize accessToken;
@synthesize webView;
@synthesize textView;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // 保存されたアクセストークンの取り出し。
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *accessKey = [defaults stringForKey:kAccessKeyStore];
        NSString *accessSecret = [defaults stringForKey:kAccessSecretStore];
        if (accessKey && accessSecret) {
            self.accessToken = [[[OAToken alloc] initWithKey:accessKey secret:accessSecret] autorelease];
        }
        // コンシューマーの初期化。
        self.consumer = [[[OAConsumer alloc] initWithKey:kConsumerKey secret:kConsumerSecret] autorelease];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // テキストビューの角を丸める。
    self.textView.layer.cornerRadius = 5;
    self.textView.clipsToBounds = YES;
    // アクセストークンが無ければ認証を開始する。
    if (!self.accessToken) {
        NSURL* requestTokenUrl = [NSURL URLWithString:@"http://api.twitter.com/oauth/request_token"];
        OAMutableURLRequest* requestTokenRequest = [[[OAMutableURLRequest alloc] initWithURL:requestTokenUrl consumer:self.consumer token:nil realm:nil signatureProvider:nil] autorelease];
        OARequestParameter* callbackParam = [[[OARequestParameter alloc] initWithName:@"oauth_callback" value:@"twitter://authorized"] autorelease];
        [requestTokenRequest setHTTPMethod:@"POST"];
        [requestTokenRequest setParameters:[NSArray arrayWithObject:callbackParam]];
        OADataFetcher* dataFetcher = [[[OADataFetcher alloc] init] autorelease];
        [dataFetcher fetchDataWithRequest:requestTokenRequest delegate:self didFinishSelector:@selector(didReceiveRequestToken:data:) didFailSelector:@selector(didFailOAuth:error:)];
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)dealloc {
    self.consumer = nil;
    self.requestToken = nil;
    self.accessToken = nil;
    [super dealloc];
}

- (void)didReceiveRequestToken:(OAServiceTicket*)ticket data:(NSData*)data {
 	NSString* httpBody = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
    self.requestToken = [[[OAToken alloc] initWithHTTPResponseBody:httpBody] autorelease];
    
    NSURL* authorizeUrl = [NSURL URLWithString:@"https://api.twitter.com/oauth/authorize"];
    OAMutableURLRequest* authorizeRequest = [[[OAMutableURLRequest alloc] initWithURL:authorizeUrl consumer:nil token:nil realm:nil signatureProvider:nil] autorelease];
    OARequestParameter* oauthTokenParam = [[[OARequestParameter alloc] initWithName:@"oauth_token" value:requestToken.key] autorelease];
    [authorizeRequest setParameters:[NSArray arrayWithObject:oauthTokenParam]];
    
    self.webView.hidden = FALSE;
    self.webView.delegate = self;
    [self.webView loadRequest:authorizeRequest];
}

- (void)didReceiveAccessToken:(OAServiceTicket*)ticket data:(NSData*)data {
    NSString* httpBody = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
    accessToken = [[OAToken alloc] initWithHTTPResponseBody:httpBody];
    // アクセストークンを保存。
    [[NSUserDefaults standardUserDefaults] setObject:accessToken.key forKey:kAccessKeyStore];
    [[NSUserDefaults standardUserDefaults] setObject:accessToken.secret forKey:kAccessSecretStore];
}

/*
- (void)postSomething {
    NSURL *url = [NSURL URLWithString:@"http://api.twitter.com/1/statuses/update.json"];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc] initWithURL:url
                                                                   consumer:consumer
                                                                      token:accessToken
                                                                      realm:nil
                                        				  signatureProvider:nil];
    
    [request setHTTPMethod:@"POST"];
    
    OARequestParameter *statusParam = [[OARequestParameter alloc] initWithName:@"status" value:@"Hey! OAuth."];
    NSArray *params = [NSArray arrayWithObjects:statusParam, nil];
    [request setParameters:params];
    
    OADataFetcher *fetcher = [[OADataFetcher alloc] init];
    [fetcher fetchDataWithRequest:request
                         delegate:self
                didFinishSelector:@selector(didFinishWithData:data:)
                  didFailSelector:@selector(didFailWithError:error:)];
}
*/

- (void)didFailOAuth:(OAServiceTicket*)ticket error:(NSError*)error {
    NSLog(@"err - %@", error);
}

- (void)didFinishWithData:(OAServiceTicket*)ticket data:(NSData*)data {
    NSLog(@"res - %@", data);
}

- (void)didFailWithError:(OAServiceTicket*)ticket error:(NSError*)error {
    NSLog(@"err - %@", error);
}

#pragma mark UIWebViewDelegate

- (BOOL)webView:(UIWebView*)webView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType {
    if ([[[request URL] scheme] isEqualToString:@"twitter"]) {
        NSString* verifier = nil;       
        NSArray* urlParams = [[[request URL] query] componentsSeparatedByString:@"&"];
        for (NSString* param in urlParams) {
            NSArray* keyValue = [param componentsSeparatedByString:@"="];
            NSString* key = [keyValue objectAtIndex:0];
            if ([key isEqualToString:@"oauth_verifier"]) {
                verifier = [keyValue objectAtIndex:1];
                break;
            }
        }
        
        if (verifier) {
            NSURL* accessTokenUrl = [NSURL URLWithString:@"https://api.twitter.com/oauth/access_token"];
            OAMutableURLRequest* accessTokenRequest = [[[OAMutableURLRequest alloc] initWithURL:accessTokenUrl consumer:self.consumer token:self.requestToken realm:nil signatureProvider:nil] autorelease];
            OARequestParameter* verifierParam = [[[OARequestParameter alloc] initWithName:@"oauth_verifier" value:verifier] autorelease];
            [accessTokenRequest setHTTPMethod:@"POST"];
            [accessTokenRequest setParameters:[NSArray arrayWithObject:verifierParam]];
            OADataFetcher* dataFetcher = [[[OADataFetcher alloc] init] autorelease];
            [dataFetcher fetchDataWithRequest:accessTokenRequest delegate:self didFinishSelector:@selector(didReceiveAccessToken:data:) didFailSelector:@selector(didFailOAuth:error:)];
        } else {
            // ERROR!
        }
        
        self.webView.hidden = YES;
        return NO;
    }
    return YES;
}

- (void)webView:(UIWebView*)webView didFailLoadWithError:(NSError*)error {
    NSLog(@"err - %@", error);
}

@end
