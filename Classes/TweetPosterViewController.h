#import <UIKit/UIKit.h>

@interface TweetPosterViewController : UIViewController {
    UITextView *textView_;
}

@property (nonatomic, retain) IBOutlet UITextView *textView;

- (IBAction)postTweet;
- (IBAction)cancel;
- (IBAction)switchLoginState;

@end
