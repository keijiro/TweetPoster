#import <QuartzCore/QuartzCore.h>
#import "TPSession.h"
#import "TPTweetViewController.h"
#import "TPAuthenticationViewController.h"

#pragma mark Private declaration

@interface TPTweetViewController (Private)
- (void)verifyAccount;
- (void)processError:(NSError *)error;
@end

#pragma mark -

@implementation TPTweetViewController

@synthesize fetcher = fetcher_;
@synthesize authenticationViewController = authenticationViewController_;

@synthesize postButton;
@synthesize tweetGroupView;
@synthesize textView;
@synthesize textCount;
@synthesize nameLabel;
@synthesize statusLabel;
@synthesize activityView;

#pragma mark Initialization and cleanup

- (id)initWithPostText:(NSString *)postText {
    if ((self = [super initWithNibName:@"TPTweetViewController" bundle:nil])) {
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

#pragma mark UIViewController

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
    if ([TPSession sharedInstance].accessToken != nil) {
        // アクセストークンがある：内容を確認する。
        [self verifyAccount];
    } else if (self.authenticationViewController == nil) {
        // アクセストークンが無い＆まだ認証画面を出していない：認証画面へと移行。
        self.authenticationViewController = [[[TPAuthenticationViewController alloc] init] autorelease];
        self.authenticationViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        [self presentModalViewController:self.authenticationViewController animated:YES];
    } else {
        // ここに来るのは認証がキャンセルされた場合：続いてこの画面もキャンセル。
        [self cancel];
    }
}

#pragma mark Private methods

// アカウントの確認の非同期処理を開始する。
- (void)verifyAccount {
    [[TPSession sharedInstance] verifyAccount:^(NSString *name) {
        // UIを入力用画面に遷移させる。
        self.nameLabel.text = [@"@" stringByAppendingString:name];
        self.statusLabel.text = nil;
        self.postButton.enabled = YES;
        self.activityView.hidden = YES;
        self.tweetGroupView.hidden = NO;
        [UIView animateWithDuration:0.5 animations:^{ self.tweetGroupView.alpha = 1.0f; }];
        [self.textView becomeFirstResponder];
    } failureBlock:^(NSError *error) { [self processError:error]; }];
}

// 汎用エラー処理。
- (void)processError:(NSError *)error {
    if (cancelled_) return; // キャンセルの過程ではエラーを無視する。
    NSLog(@"TPTweetViewController - %@", error);
    UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Network Error"
                                                     message:@"A network error occurred while communicating with the server."
                                                    delegate:self
                                           cancelButtonTitle:@"Back"
                                           otherButtonTitles:nil] autorelease];
    [alert show];
}

#pragma mark UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    // そのままキャンセル挙動に繋ぐ。
    [self cancel];
}

#pragma mark IBAction

- (IBAction)postTweet {
    // UIをポスト中表示に遷移させる。
    [self.textView resignFirstResponder];
    self.statusLabel.text = @"Posting...";
    self.activityView.hidden = NO;
    self.postButton.enabled = NO;
    self.textView.editable = NO;
    [UIView animateWithDuration:0.5 animations:^{ self.tweetGroupView.alpha = 0.0f; }];
    // 非同期処理の発行。
    [[TPSession sharedInstance] postTweet:self.textView.text resultBlock:^{
        self.statusLabel.text = @"Done!";
        self.activityView.hidden = YES;
        // 完了２秒後にクローズ（キャンセルで代用）。
        [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(cancel) userInfo:nil repeats:NO];
    } failureBlock:^(NSError *error) { [self processError:error]; }];
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
