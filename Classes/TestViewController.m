#import "TestViewController.h"
#import "TPSession.h"
#import "TPTweetViewController.h"
#import "TPAuthenticationViewController.h"

@implementation TestViewController

@synthesize nameLabel;
@synthesize signButton;
@synthesize tweetButton;

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updateSignInStatus];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self updateSignInStatus];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)dealloc {
    [super dealloc];
}

// ツイートを試す。
- (IBAction)tweet {
    // ツイート内容をランダムに決める。
    NSString *postText = [NSString stringWithFormat:@"I just got %d points! This game is really fun! http://goo.gl/U98s #example", arc4random() % 100000];
    // ツイート画面の呼び出し。
    TPTweetViewController *viewController = [[[TPTweetViewController alloc] initWithPostText:postText] autorelease];
    [self presentModalViewController:viewController animated:YES];
}

// サインイン・サインアウト。
- (IBAction)signInOrOut {
    if ([TPSession sharedInstance].signedIn) {
        // サインアウト。
        [[TPSession sharedInstance] signOut];
        [self updateSignInStatus];
        // ダイアログでお知らせ。
        UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Done"
                                                         message:@"Successfully signed out."
                                                        delegate:nil
                                               cancelButtonTitle:@"Ok"
                                               otherButtonTitles:nil] autorelease];
        [alert show];
    } else {
        // サインイン画面の呼び出し。
        TPAuthenticationViewController *viewController = [[[TPAuthenticationViewController alloc] init] autorelease];
        [self presentModalViewController:viewController animated:YES];
    }
}

// サインイン状態の更新。
- (void)updateSignInStatus {
    // iOS 4.0 バージョン確認。
    if (NSClassFromString(@"NSBlockOperation")) {
        TPSession *session = [TPSession sharedInstance];
        if (session.signedIn) {
            self.signButton.title = @"Sign Out";
            self.nameLabel.text = [@"Signed in as @" stringByAppendingString:session.userNameCache];
        } else {
            self.signButton.title = @"Sign In";
            self.nameLabel.text = @"(Signed Out)";
        }
    } else {
        // 非対応デバイスでは機能を封じる。
        self.nameLabel.text = @"(pre-4.0 iOS devices are not supported)";
        self.signButton.enabled = NO;
        self.tweetButton.enabled = NO;
    }
}

@end
