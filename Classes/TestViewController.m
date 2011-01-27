#import "TestViewController.h"

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
    self.tweetViewController = [[TweetPosterViewController alloc] initWithNibName:@"TweetPosterViewController" bundle:nil];
    [self presentModalViewController:self.tweetViewController animated:YES];
}

@end
