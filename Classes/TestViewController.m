#import "TestViewController.h"
#import "TPSession.h"
#import "TPTweetViewController.h"
#import "TPAuthenticationViewController.h"

@implementation TestViewController

@synthesize nameLabel;
@synthesize signButton;

- (void)viewDidLoad {
    [super viewDidLoad];
    [self updateSignInStatus];
    // アクセストークンの
    [[TPSession sharedInstance] addObserver:self
                                 forKeyPath:@"accessToken"
                                    options:0
                                    context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if ([keyPath isEqual:@"accessToken"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateSignInStatus];
        });
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
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
        if ([TPSession sharedInstance].signedIn) {
     self.signButton.title = @"Sign Out";
     self.nameLabel.text = @"(Signed In)";
     // 名前の取得。
     [[TPSession sharedInstance] verifyAccount:^(NSString *userName) {
     self.nameLabel.text = userName;
     } failureBlock:nil];
     } else {
     self.signButton.title = @"Sign In";
     self.nameLabel.text = @"(Signed Out)";
     }
}

@end
