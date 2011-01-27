#import <UIKit/UIKit.h>

@interface TweetPosterViewController : UIViewController <UITextViewDelegate> {
}

@property (nonatomic, retain) IBOutlet UITextView *textView;
@property (nonatomic, retain) IBOutlet UILabel *textCount;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *postButton;
@property (nonatomic, retain) IBOutlet UIButton *loginButton;
@property (nonatomic, retain) IBOutlet UILabel *statusLabel;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *activityView;

- (IBAction)postTweet;
- (IBAction)cancel;
- (IBAction)switchLoginState;

@end
