#import "TweetPosterViewController.h"
#import "TweetPosterOAuth.h"
#import "TweetPosterAuthViewController.h"
#import <QuartzCore/QuartzCore.h>

@implementation TweetPosterViewController

@synthesize textView;

- (void)viewDidLoad {
    [super viewDidLoad];
    // テキストビューの角を丸める。
    self.textView.layer.cornerRadius = 5;
    self.textView.clipsToBounds = YES;
    // アクセストークンの有無によりUIの状態を変更する。
    if ([TweetPosterOAuth sharedInstance].accessToken) {
    }
}

- (void)dealloc {
    [super dealloc];
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

/*
- (void)didFinishWithData:(OAServiceTicket*)ticket data:(NSData*)data {
    NSLog(@"res - %@", data);
}

- (void)didFailWithError:(OAServiceTicket*)ticket error:(NSError*)error {
    NSLog(@"err - %@", error);
}
*/

- (IBAction)postTweet {
}

- (IBAction)cancel {
	[self dismissModalViewControllerAnimated:YES];
}

- (IBAction)switchLoginState {
    TweetPosterAuthViewController *authViewController = [[[TweetPosterAuthViewController alloc] init] autorelease];
    authViewController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    [self presentModalViewController:authViewController animated:YES];
}

@end
