#import <UIKit/UIKit.h>
#import "OAuthConsumer.h"
#import "TweetPosterAuthViewController.h"

@interface TweetPosterViewController : UIViewController <UITextViewDelegate, UIAlertViewDelegate> {
    BOOL cancelled_;
	NSString *initialPostText_;
    OAAsynchronousDataFetcher *fetcher_;
    TweetPosterAuthViewController *authViewController_;
}

@property (nonatomic, retain) OAAsynchronousDataFetcher *fetcher;
@property (nonatomic, retain) TweetPosterAuthViewController *authViewController;

@property (nonatomic, retain) IBOutlet UIBarButtonItem *postButton;
@property (nonatomic, retain) IBOutlet UIView *tweetGroupView;
@property (nonatomic, retain) IBOutlet UITextView *textView;
@property (nonatomic, retain) IBOutlet UILabel *textCount;
@property (nonatomic, retain) IBOutlet UILabel *nameLabel;
@property (nonatomic, retain) IBOutlet UILabel *statusLabel;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *activityView;

- (id)initWithPostText:(NSString *)postText;

- (IBAction)postTweet;
- (IBAction)cancel;

@end
