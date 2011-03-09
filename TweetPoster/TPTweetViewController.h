//
// TPTweetViewController - メインの投稿画面を制御するビューコントローラー
//
// initWithPostTextで、テキストボックスの中身を設定しつつ初期化する。
// あとはモーダルビューとして表示するだけでよい。認証がまだの場合は
// 勝手に認証画面を呼び出して処理する。
//

#import <UIKit/UIKit.h>
#import "TPAsynchronousDataFetcher.h"
#import "TPAuthenticationViewController.h"

@interface TPTweetViewController : UIViewController <UITextViewDelegate, UIAlertViewDelegate> {
    BOOL cancelled_;
	NSString *initialPostText_;
    TPAsynchronousDataFetcher *fetcher_;
    TPAuthenticationViewController *authenticationViewController_;
}

@property (nonatomic, retain) TPAsynchronousDataFetcher *fetcher;
@property (nonatomic, retain) TPAuthenticationViewController *authenticationViewController;

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
