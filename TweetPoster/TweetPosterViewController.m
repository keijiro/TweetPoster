#import "TweetPosterViewController.h"
#import "TweetPosterOAuth.h"
#import "TweetPosterAuthViewController.h"
#import <QuartzCore/QuartzCore.h>

@implementation TweetPosterViewController

@synthesize textView;
@synthesize textCount;
@synthesize postButton;
@synthesize loginButton;
@synthesize statusLabel;
@synthesize activityView;

- (void)viewDidLoad {
    [super viewDidLoad];
    // テキストビューの角を丸める。
    self.textView.layer.cornerRadius = 5;
    self.textView.clipsToBounds = YES;
    // テキスト内容の初期設定。
    self.textView.text = [NSString stringWithFormat:@"I just got %d points! This game is really fun! http://goo.gl/U98s #example", rand() % 100000];
    [self textViewDidChange:self.textView];
}

- (void)verifyAccount {
    TweetPosterOAuth *auth = [TweetPosterOAuth sharedInstance];

    NSURL *url = [NSURL URLWithString:@"http://api.twitter.com/1/account/verify_credentials.xml"];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc] initWithURL:url
                                                                   consumer:auth.consumer
                                                                      token:auth.accessToken
                                                                      realm:nil
                                        				  signatureProvider:nil];
    
    OAAsynchronousDataFetcher *fetcher = [OAAsynchronousDataFetcher asynchronousFetcherWithRequest:request
                         delegate:self
                didFinishSelector:@selector(didFinishWithData:data:)
                  didFailSelector:@selector(didFailWithError:error:)];
    [fetcher start];
    [fetcher retain];
    
    self.statusLabel.text = @"Connecting...";
    self.loginButton.enabled = NO;
    self.activityView.hidden = NO;
}

- (void)didFinishWithData:(OAServiceTicket*)ticket data:(NSData*)data {
    NSString *string = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
    NSRange begin = [string rangeOfString:@"<screen_name>"];
    NSRange end = [string rangeOfString:@"</screen_name>"];
    if (begin.location != NSNotFound && end.location != NSNotFound) {
        NSString *name = [string substringWithRange:NSMakeRange(begin.location + begin.length, end.location - begin.location - begin.length)];
        self.statusLabel.text = [@"@" stringByAppendingString:name];
        //name;
        self.postButton.enabled = YES;
        [self.loginButton setTitle:@"Logout" forState:UIControlStateNormal];
        self.loginButton.enabled = YES;
        self.activityView.hidden = YES;
    }
}

- (void)didFailWithError:(OAServiceTicket*)ticket error:(NSError*)error {
    NSLog(@"err - %@", error);
}

- (void)viewWillAppear:(BOOL)animated {
    // アクセストークンの有無によりUIの状態を変更する。
    if ([TweetPosterOAuth sharedInstance].accessToken) {
        [self verifyAccount];
    } else {
        self.statusLabel.text = nil;
        self.postButton.enabled = NO;
        [self.loginButton setTitle:@"Login" forState:UIControlStateNormal];
        self.loginButton.enabled = YES;
        self.activityView.hidden = YES;
    }
    [self.textView becomeFirstResponder];
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
    TweetPosterOAuth *auth = [TweetPosterOAuth sharedInstance];
    
    NSURL *url = [NSURL URLWithString:@"http://api.twitter.com/1/statuses/update.xml"];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc] initWithURL:url
                                                                   consumer:auth.consumer
                                                                      token:auth.accessToken
                                                                      realm:nil
                                        				  signatureProvider:nil];
    [request setHTTPMethod:@"POST"];
    OARequestParameter *param = [[OARequestParameter alloc] initWithName:@"status"
                                                                   value:self.textView.text];
    [request setParameters:[NSArray arrayWithObject:param]];

    OAAsynchronousDataFetcher *fetcher = [OAAsynchronousDataFetcher asynchronousFetcherWithRequest:request
                                                                                          delegate:self
                                                                                 didFinishSelector:@selector(didFinishPostWithData:data:)
                                                                                   didFailSelector:@selector(didFailWithError:error:)];
    [fetcher start];
    [fetcher retain];
    
    self.statusLabel.text = @"Sending...";
    self.loginButton.enabled = NO;
    self.activityView.hidden = NO;
    self.postButton.enabled = NO;
}

- (void)didFinishPostWithData:(OAServiceTicket*)ticket data:(NSData*)data {
    self.statusLabel.text = @"Done!";
    self.activityView.hidden = YES;
    // １．５秒後にクローズ（キャンセルで代用）。
    [NSTimer scheduledTimerWithTimeInterval:1.5f target:self selector:@selector(cancel) userInfo:nil repeats:NO];
}

- (IBAction)cancel {
	[self dismissModalViewControllerAnimated:YES];
}

- (IBAction)switchLoginState {
    if ([TweetPosterOAuth sharedInstance].accessToken) {
        // アクセストークンが有る：ログアウト。
        [TweetPosterOAuth sharedInstance].accessToken = nil;
        [self viewWillAppear:NO];
    } else {
        // アクセストークンが無い：認証画面へ移行。
        TweetPosterAuthViewController *authViewController = [[[TweetPosterAuthViewController alloc] init] autorelease];
        authViewController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
        [self presentModalViewController:authViewController animated:YES];
    }
}

- (void)textViewDidChange:(UITextView *)textView {
    // 残り文字数の更新。
    self.textCount.text = [NSString stringWithFormat:@"%d", 140 - self.textView.text.length];
}

@end
