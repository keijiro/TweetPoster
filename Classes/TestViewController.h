#import <UIKit/UIKit.h>
#import "TweetViewController.h"

@interface TestViewController : UIViewController {
    TweetViewController *tweetViewController_;
}

@property (nonatomic, retain) TweetViewController *tweetViewController;

- (IBAction)tweet;

@end

