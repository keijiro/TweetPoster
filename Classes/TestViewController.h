#import <UIKit/UIKit.h>

@interface TestViewController : UIViewController {
}

@property (nonatomic, retain) IBOutlet UIButton *signButton;

- (void)updateSignButton;
- (IBAction)tweet;
- (IBAction)signInOrOut;

@end

