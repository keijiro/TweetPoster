#import <UIKit/UIKit.h>
#import "OAuthConsumer.h"

@interface TweetViewController : UIViewController <UIWebViewDelegate> {
    OAConsumer* consumer_;
    OAToken* requestToken_;
    OAToken* accessToken_;
    UIWebView *webView_;
    UITextView *textView_;
}

@property (nonatomic, retain) OAConsumer *consumer;
@property (nonatomic, retain) OAToken* requestToken;
@property (nonatomic, retain) OAToken* accessToken;

@property (nonatomic, retain) IBOutlet UIWebView *webView;
@property (nonatomic, retain) IBOutlet UITextView *textView;

@end
