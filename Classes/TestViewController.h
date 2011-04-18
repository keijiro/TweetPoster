#import <UIKit/UIKit.h>

@interface TestViewController : UIViewController {
}

@property (nonatomic, retain) IBOutlet UILabel *nameLabel;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *signButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *tweetButton;

- (void)updateSignInStatus;

- (IBAction)tweet;
- (IBAction)signInOrOut;

@end

