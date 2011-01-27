#import <UIKit/UIKit.h>

@interface TweetPosterAuthViewController : UIViewController <UIWebViewDelegate> {
    UIWebView *webView_;
}

@property (nonatomic, retain) IBOutlet UIWebView *webView;

- (IBAction)cancel;

@end
