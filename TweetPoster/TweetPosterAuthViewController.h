#import <UIKit/UIKit.h>
#import "OAuthConsumer.h"

@interface TweetPosterAuthViewController : UIViewController <UIWebViewDelegate> {
    OAAsynchronousDataFetcher *fetcher_;
}

@property (nonatomic, retain) OAAsynchronousDataFetcher *fetcher;

@property (nonatomic, retain) IBOutlet UIWebView *webView;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *activityView;

- (IBAction)cancel;

@end
