#import <UIKit/UIKit.h>
#import "OAuthConsumer.h"

@interface TweetPosterAuthViewController : UIViewController <UIWebViewDelegate, UIAlertViewDelegate> {
    OAAsynchronousDataFetcher *fetcher_;
    BOOL cancelled_;
}

@property (nonatomic, retain) OAAsynchronousDataFetcher *fetcher;

@property (nonatomic, retain) IBOutlet UIWebView *webView;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *activityView;

- (IBAction)cancel;

@end
