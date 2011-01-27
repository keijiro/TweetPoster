#import <Foundation/Foundation.h>
#import "OAuthConsumer.h"

@interface TweetPosterOAuth : NSObject {
    OAConsumer* consumer_;
    OAToken* requestToken_;
    OAToken* accessToken_;
}

@property (nonatomic, readonly) OAConsumer *consumer;
@property (nonatomic, retain) OAToken* requestToken;
@property (nonatomic, retain) OAToken* accessToken;

+ (TweetPosterOAuth *)sharedInstance;
+ (void)disposeSharedInstance;

@end
