//
// TPAuthenticationViewController - 認証画面ビューコントローラー
//
// ウェブビューとの連携によってOAuth認証を進めるビューコントローラー。
// モーダルビューとして表示すれば、あとは認証まで勝手に流れを処理する。
//

#import <UIKit/UIKit.h>
#import "TPAsynchronousDataFetcher.h"

@interface TPAuthenticationViewController : UIViewController <UIWebViewDelegate, UIAlertViewDelegate> {
    TPAsynchronousDataFetcher *fetcher_;
    BOOL cancelled_;
}

@property (nonatomic, retain) TPAsynchronousDataFetcher *fetcher;

@property (nonatomic, retain) IBOutlet UIWebView *webView;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *activityView;

- (IBAction)cancel;

@end
