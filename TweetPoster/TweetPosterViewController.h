#import <UIKit/UIKit.h>
#import "OAuthConsumer.h"

@interface TweetPosterViewController : UIViewController <UITextViewDelegate> {
    BOOL cancelled_;
	NSString *initialPostText_;
    OAAsynchronousDataFetcher *fetcher_;
}

@property (nonatomic, retain) OAAsynchronousDataFetcher *fetcher;

@property (nonatomic, retain) IBOutlet UITextView *textView;
@property (nonatomic, retain) IBOutlet UILabel *textCount;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *postButton;
@property (nonatomic, retain) IBOutlet UIButton *loginButton;
@property (nonatomic, retain) IBOutlet UILabel *statusLabel;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *activityView;

- (id)initWithPostText:(NSString *)postText;

- (IBAction)postTweet;
- (IBAction)cancel;
- (IBAction)switchLoginState;

@end
