#import "TweetPosterAuthViewController.h"
#import "TweetPosterOAuth.h"

@implementation TweetPosterAuthViewController

@synthesize webView;

- (void)viewDidLoad {
    [super viewDidLoad];

    self.webView.delegate = self;

    TweetPosterOAuth *auth = [TweetPosterOAuth sharedInstance];
    NSURL* requestTokenUrl = [NSURL URLWithString:@"http://api.twitter.com/oauth/request_token"];
    OAMutableURLRequest* requestTokenRequest = [[[OAMutableURLRequest alloc] initWithURL:requestTokenUrl consumer:auth.consumer token:nil realm:nil signatureProvider:nil] autorelease];
    OARequestParameter* callbackParam = [[[OARequestParameter alloc] initWithName:@"oauth_callback" value:@"twitter://authorized"] autorelease];
    [requestTokenRequest setHTTPMethod:@"POST"];
    [requestTokenRequest setParameters:[NSArray arrayWithObject:callbackParam]];
    OADataFetcher* dataFetcher = [[[OADataFetcher alloc] init] autorelease];
    [dataFetcher fetchDataWithRequest:requestTokenRequest delegate:self didFinishSelector:@selector(didReceiveRequestToken:data:) didFailSelector:@selector(didFailOAuth:error:)];
}

- (void)dealloc {
    [super dealloc];
}

- (void)didReceiveRequestToken:(OAServiceTicket*)ticket data:(NSData*)data {
    TweetPosterOAuth *auth = [TweetPosterOAuth sharedInstance];
    NSString* httpBody = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
    auth.requestToken = [[[OAToken alloc] initWithHTTPResponseBody:httpBody] autorelease];

    NSURL* authorizeUrl = [NSURL URLWithString:@"https://api.twitter.com/oauth/authorize"];
    OAMutableURLRequest* authorizeRequest = [[[OAMutableURLRequest alloc] initWithURL:authorizeUrl consumer:nil token:nil realm:nil signatureProvider:nil] autorelease];
    OARequestParameter* oauthTokenParam = [[[OARequestParameter alloc] initWithName:@"oauth_token" value:auth.requestToken.key] autorelease];
    [authorizeRequest setParameters:[NSArray arrayWithObject:oauthTokenParam]];
    [self.webView loadRequest:authorizeRequest];
}

- (void)didReceiveAccessToken:(OAServiceTicket*)ticket data:(NSData*)data {
    NSString* httpBody = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
    OAToken *accessToken = [[OAToken alloc] initWithHTTPResponseBody:httpBody];
    [TweetPosterOAuth sharedInstance].accessToken = accessToken;
}

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
            TweetPosterOAuth *auth = [TweetPosterOAuth sharedInstance];
            NSURL* accessTokenUrl = [NSURL URLWithString:@"https://api.twitter.com/oauth/access_token"];
            OAMutableURLRequest* accessTokenRequest = [[[OAMutableURLRequest alloc] initWithURL:accessTokenUrl consumer:auth.consumer token:auth.requestToken realm:nil signatureProvider:nil] autorelease];
            OARequestParameter* verifierParam = [[[OARequestParameter alloc] initWithName:@"oauth_verifier" value:verifier] autorelease];
            [accessTokenRequest setHTTPMethod:@"POST"];
            [accessTokenRequest setParameters:[NSArray arrayWithObject:verifierParam]];
            OADataFetcher* dataFetcher = [[[OADataFetcher alloc] init] autorelease];
            [dataFetcher fetchDataWithRequest:accessTokenRequest delegate:self didFinishSelector:@selector(didReceiveAccessToken:data:) didFailSelector:@selector(didFailOAuth:error:)];
        } else {
            // ERROR!
        }
        return NO;
    }
    return YES;
}

- (void)didFailOAuth:(OAServiceTicket*)ticket error:(NSError*)error {
    NSLog(@"err - %@", error);
}

- (void)webView:(UIWebView*)webView didFailLoadWithError:(NSError*)error {
    NSLog(@"err - %@", error);
}

- (IBAction)cancel {
    [self dismissModalViewControllerAnimated:YES];
}

@end
