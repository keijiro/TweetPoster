//
// メインの投稿画面を制御するビューコントローラー。
//

#import <QuartzCore/QuartzCore.h>
#import "TweetPosterViewController.h"
#import "TweetPosterOAuth.h"
#import "TweetPosterAuthViewController.h"

@interface TweetPosterViewController ()
- (void)verifyAccount;
@end

@implementation TweetPosterViewController

@synthesize fetcher = fetcher_;
@synthesize authViewController = authViewController_;

@synthesize postButton;
@synthesize tweetGroupView;
@synthesize textView;
@synthesize textCount;
@synthesize nameLabel;
@synthesize statusLabel;
@synthesize activityView;

#pragma mark UIView

- (id)initWithPostText:(NSString *)postText {
    if ((self = [super initWithNibName:@"TweetPosterViewController" bundle:nil])) {
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

- (void)viewDidAppear:(BOOL)animated {
    if ([TweetPosterOAuth sharedInstance].accessToken != nil) {
        // アクセストークンがある：内容を確認する。
        [self verifyAccount];
    } else if (self.authViewController == nil) {
        // アクセストークンが無い＆まだ認証画面を出していない：認証画面へと移行。
        self.authViewController = [[[TweetPosterAuthViewController alloc] init] autorelease];
        self.authViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        [self presentModalViewController:self.authViewController animated:YES];
    } else {
        // ここに来るのは認証がキャンセルされた場合：続いてこの画面もキャンセル。
        [self cancel];
    }
}

#pragma mark Private

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
}

#pragma mark OAuth Callback

- (void)didFinishVerifyAccount:(OAServiceTicket*)ticket data:(NSData*)data {
    self.fetcher = nil; // release
   // データから名前部分を抽出。
    NSString *string = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
    NSUInteger begin = NSMaxRange([string rangeOfString:@"<screen_name>"]);
    NSUInteger end = [string rangeOfString:@"</screen_name>"].location;
    if (begin != NSNotFound && end != NSNotFound) {
        NSString *name = [string substringWithRange:NSMakeRange(begin, end - begin)];
        self.nameLabel.text = [@"@" stringByAppendingString:name];
    }
    // UIを入力用画面に遷移させる。
    self.statusLabel.text = nil;
    self.postButton.enabled = YES;
    self.activityView.hidden = YES;
    self.tweetGroupView.hidden = NO;
    [UIView animateWithDuration:0.5 animations:^{ self.tweetGroupView.alpha = 1.0f; }];
    [self.textView becomeFirstResponder];
}

- (void)didFailVerifyAccount:(OAServiceTicket*)ticket error:(NSError*)error {
    self.fetcher = nil; // release
    // キャンセル挙動中でなければエラーの表示を行う。
    if (!cancelled_) {
        NSLog(@"didFailVerifyAccount - %@", error);
        UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Network Error"
                                                         message:@"A network error occurred while communicating with the server."
                                                        delegate:self
                                               cancelButtonTitle:@"Back"
                                               otherButtonTitles:nil] autorelease];
        [alert show];
    }
}

- (void)didFinishPostTweet:(OAServiceTicket*)ticket data:(NSData*)data {
    self.fetcher = nil; // release
    // 完了の旨をUIに表示する。
	self.statusLabel.text = @"Done!";
	self.activityView.hidden = YES;
    // ２秒後にクローズ（キャンセルで代用）。
    [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(cancel) userInfo:nil repeats:NO];
}

- (void)didFailPostTweet:(OAServiceTicket*)ticket error:(NSError*)error {
    self.fetcher = nil; // release
    // キャンセル挙動中でなければエラーの表示を行う。
    if (!cancelled_) {
        NSLog(@"didFailPostTweet - %@", error);
        UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Network Error"
                                                         message:@"A network error occurred while communicating with the server."
                                                        delegate:self
                                               cancelButtonTitle:@"Ok"
                                               otherButtonTitles:nil] autorelease];
        [alert show];
    }
}

#pragma mark UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    // そのままキャンセル挙動に繋ぐ。
    [self cancel];
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
    // UIをポスト中表示に遷移させる。
    [self.textView resignFirstResponder];
    self.statusLabel.text = @"Posting...";
    self.activityView.hidden = NO;
    self.postButton.enabled = NO;
    self.textView.editable = NO;
    [UIView animateWithDuration:0.5 animations:^{ self.tweetGroupView.alpha = 0.0f; }];
}

- (IBAction)cancel {
    cancelled_ = YES;
	[self dismissModalViewControllerAnimated:YES];
}

- (void)textViewDidChange:(UITextView *)textView {
    // 残り文字数の更新。
    self.textCount.text = [NSString stringWithFormat:@"%d", 140 - self.textView.text.length];
}

@end
