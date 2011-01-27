//
// メインの投稿画面を制御するビューコントローラー。
//

#import <QuartzCore/QuartzCore.h>
#import "TweetPosterViewController.h"
#import "TweetPosterOAuth.h"
#import "TweetPosterAuthViewController.h"

@interface TweetPosterViewController ()
- (void)setLoginState:(BOOL)flag;
- (void)verifyAccount;
@end

@implementation TweetPosterViewController

@synthesize fetcher = fetcher_;
@synthesize textView;
@synthesize textCount;
@synthesize postButton;
@synthesize loginButton;
@synthesize statusLabel;
@synthesize activityView;

#pragma mark UIView

- (id)initWithPostText:(NSString *)postText {
    if (self = [super initWithNibName:@"TweetPosterViewController" bundle:nil]) {
        cancelled_ = NO;
	    initialPostText_ = [postText copy];
    }
    return self;
}

- (void)dealloc {
    [initialPostText_ release];
    [fetcher_ release];
    [super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // テキストビューの角を丸める。
    self.textView.layer.cornerRadius = 5;
    self.textView.clipsToBounds = YES;
    // 初期文字列の設定。
    self.textView.text = initialPostText_;
    [self textViewDidChange:self.textView];
}

- (void)viewWillAppear:(BOOL)animated {
    // アクセストークンの有無によりログイン状態を判別する。
    [self setLoginState:([TweetPosterOAuth sharedInstance].accessToken != nil)];
    // キーボードを出す。
    [self.textView becomeFirstResponder];
}

#pragma mark Private

- (void)setLoginState:(BOOL)flag {
    if (flag) {
        // ログインしているっぽい：アカウントの確認へ移行。
        [self verifyAccount];
    } else {
        // ログインしていない：UIをログアウト状態に変更。
        [self.loginButton setTitle:@"Login" forState:UIControlStateNormal];
        self.statusLabel.text = nil;
        self.postButton.enabled = NO;
        self.loginButton.enabled = YES;
        self.activityView.hidden = YES;
    }
}

- (void)verifyAccount {
    // アカウント（アクセストークン）の確認を非同期に発行する。
    TweetPosterOAuth *auth = [TweetPosterOAuth sharedInstance];
    NSURL *url = [NSURL URLWithString:@"http://api.twitter.com/1/account/verify_credentials.xml"];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc] initWithURL:url
                                                                   consumer:auth.consumer
                                                                      token:auth.accessToken
                                                                      realm:nil
                                        				  signatureProvider:nil];
    self.fetcher = [OAAsynchronousDataFetcher asynchronousFetcherWithRequest:request
                                                                    delegate:self
                                                           didFinishSelector:@selector(didFinishVerifyAccount:data:)
                                                             didFailSelector:@selector(didFailVerifyAccount:error:)];
    [self.fetcher start];
    // UIを接続中状態に変更。
    self.statusLabel.text = @"Connecting...";
    self.loginButton.enabled = NO;
    self.activityView.hidden = NO;
}

#pragma mark OAuth Callback

- (void)didFinishVerifyAccount:(OAServiceTicket*)ticket data:(NSData*)data {
    // フェッチャーはこの時点で不要になる。
    self.fetcher = nil;
    // データから名前部分を抽出。
    NSString *string = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
    NSUInteger begin = NSMaxRange([string rangeOfString:@"<screen_name>"]);
    NSUInteger end = [string rangeOfString:@"</screen_name>"].location;
    if (begin != NSNotFound && end != NSNotFound) {
        NSString *name = [string substringWithRange:NSMakeRange(begin, end - begin)];
        // UIをログイン状態に変更。
        [self.loginButton setTitle:@"Logout" forState:UIControlStateNormal];
      	self.statusLabel.text = [@"@" stringByAppendingString:name];
        self.postButton.enabled = YES;
        self.loginButton.enabled = YES;
        self.activityView.hidden = YES;
    } else {
        // 名前取得失敗：静かにログアウト状態へ移行する。
        [self setLoginState:NO];
    }
}

- (void)didFailVerifyAccount:(OAServiceTicket*)ticket error:(NSError*)error {
    // キャンセル挙動中でなければ、静かにログアウト状態へ移行する。
    if (!cancelled_) {
        NSLog(@"didFailVerifyAccount - %@", error);
        [self setLoginState:NO];
    }
    self.fetcher = nil;
}

- (void)didFinishPostTweet:(OAServiceTicket*)ticket data:(NSData*)data {
    // フェッチャーはこの時点で不要になる。
    self.fetcher = nil;
    // UIをツイート完了状態に変更。
    self.statusLabel.text = @"Done!";
    self.activityView.hidden = YES;
    // １．５秒後にクローズ（キャンセルで代用）。
    [NSTimer scheduledTimerWithTimeInterval:1.5f target:self selector:@selector(cancel) userInfo:nil repeats:NO];
}

- (void)didFailPostTweet:(OAServiceTicket*)ticket error:(NSError*)error {
    // キャンセル挙動中でなければエラーの表示を行う。
    if (!cancelled_) {
        NSLog(@"didFailPostTweet - %@", error);
        UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Network Error"
                                                         message:@"A network error occurred while communicating with the server."
                                                        delegate:nil
                                               cancelButtonTitle:@"Ok"
                                               otherButtonTitles:nil] autorelease];
        [alert show];
        // ログアウト状態へ移行する。
        [self setLoginState:NO];
    }
    self.fetcher = nil;
}

#pragma mark IBAction

- (IBAction)postTweet {
    // ツイートのポストを非同期に発行する。
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
    self.fetcher = [OAAsynchronousDataFetcher asynchronousFetcherWithRequest:request
                                                                    delegate:self
                                                           didFinishSelector:@selector(didFinishPostTweet:data:)
                                                             didFailSelector:@selector(didFailPostTweet:error:)];
    [self.fetcher start];
    // UIをポスト中状態に変更。
    self.statusLabel.text = @"Sending...";
    self.loginButton.enabled = NO;
    self.activityView.hidden = NO;
    self.postButton.enabled = NO;
}

- (IBAction)cancel {
    cancelled_ = YES;
	[self dismissModalViewControllerAnimated:YES];
}

- (IBAction)switchLoginState {
    if ([TweetPosterOAuth sharedInstance].accessToken) {
        // アクセストークンが有る：ログアウト。
        [TweetPosterOAuth sharedInstance].accessToken = nil;
        [self setLoginState:NO];
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
