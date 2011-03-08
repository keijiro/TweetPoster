#import "TestViewController.h"
#import "TweetPosterAuthViewController.h"
#import "TweetPosterViewController.h"
#import "TweetPosterOAuth.h"

@implementation TestViewController

@synthesize signButton;

- (void)viewDidLoad {
    [super viewDidLoad];
    [self updateSignButton];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)viewDidUnload {
}

- (void)dealloc {
    [super dealloc];
}

// ツイートを試す。
- (IBAction)tweet {
    // ツイート内容をランダムに決める。
    NSString *postText = [NSString stringWithFormat:@"I just got %d points! This game is really fun! http://goo.gl/U98s #example", arc4random() % 100000];
    // ツイート画面の呼び出し。
    TweetPosterViewController *viewController = [[[TweetPosterViewController alloc] initWithPostText:postText] autorelease];
    [self presentModalViewController:viewController animated:YES];
}

// サインイン・サインアウト。
- (IBAction)signInOrOut {
    // アクセストークンから状態を調べる。
    if ([TweetPosterOAuth sharedInstance].accessToken == nil) {
        // サインイン画面の呼び出し。
        TweetPosterAuthViewController *viewController = [[[TweetPosterAuthViewController alloc] init] autorelease];
        [self presentModalViewController:viewController animated:YES];
    } else {
        // サインアウト。
        [TweetPosterOAuth sharedInstance].accessToken = nil;
        // ダイアログでお知らせ。
        UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Done"
                                                         message:@"Successfully signed out."
                                                        delegate:nil
                                               cancelButtonTitle:@"Ok"
                                               otherButtonTitles:nil] autorelease];
        [alert show];
    }
    // ボタンの更新。
    [self updateSignButton];
}

// ボタンのラベルの表記("Sign In" / "Sign"Out")の入れ替え。
- (void)updateSignButton {
    if ([TweetPosterOAuth sharedInstance].accessToken) {
        [signButton setTitle:@"Sign Out" forState:UIControlStateNormal];
    } else {
        [signButton setTitle:@"Sign In" forState:UIControlStateNormal];
    }
}

@end
