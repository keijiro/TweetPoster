#import <UIKit/UIKit.h>

@interface TestViewController : UIViewController {
}

@property (nonatomic, retain) IBOutlet UILabel *nameLabel;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *signButton;

- (void)updateSignInStatus;

- (IBAction)tweet;
- (IBAction)signInOrOut;

@end

