#import <UIKit/UIKit.h>
#import "TweetPosterViewController.h"

@interface TestViewController : UIViewController {
    TweetPosterViewController *tweetViewController_;
}

@property (nonatomic, retain) TweetPosterViewController *tweetViewController;

- (IBAction)tweet;
- (IBAction)signOut;

@end

