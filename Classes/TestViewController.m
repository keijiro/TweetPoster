#import "TestViewController.h"
#import "TweetPosterOAuth.h"

@implementation TestViewController

@synthesize tweetViewController;

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)viewDidUnload {
    self.tweetViewController = nil;
}

- (void)dealloc {
    [super dealloc];
}

- (IBAction)tweet {
    NSString *postText = [NSString stringWithFormat:@"I just got %d points! This game is really fun! http://goo.gl/U98s #example", arc4random() % 100000];
    self.tweetViewController = [[[TweetPosterViewController alloc] initWithPostText:postText] autorelease];
    [self presentModalViewController:self.tweetViewController animated:YES];
}

- (IBAction)signOut {
	[TweetPosterOAuth sharedInstance].accessToken = nil;
    UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Done"
                                                     message:@"Successfully signed out."
                                                    delegate:nil
                                           cancelButtonTitle:@"Ok"
                                           otherButtonTitles:nil] autorelease];
    [alert show];
}

@end
