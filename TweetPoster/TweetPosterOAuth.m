#import "TweetPosterOAuth.h"

// Twitter App 登録情報
static NSString* kConsumerKey = @"TqaWmqgwBdGQXiAlgEGqMg";
static NSString* kConsumerSecret = @"wLRgb1nncMNzMCXpyqXbvxtKaAiT4nIv9deNyEWQnQ";

// Keys for defaults system.
static NSString* kAccessKeyStore = @"TwitterAccessKey";
static NSString* kAccessSecretStore = @"TwitterAccessSecret";

// Shared instance.
static TweetPosterOAuth *s_sharedInstance;

@implementation TweetPosterOAuth;

@synthesize consumer = consumer_;
@synthesize requestToken = requestToken_;
@synthesize accessToken = accessToken_;

#pragma mark Property Accessors

- (void)setAccessToken:(OAToken *)token {
    [accessToken_ release];
    accessToken_ = [token retain];
    // アクセストークンの保存（あるいは破棄）。
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (token) {
        [defaults setObject:token.key forKey:kAccessKeyStore];
        [defaults setObject:token.secret forKey:kAccessSecretStore];
    } else {
        [defaults removeObjectForKey:kAccessKeyStore];
        [defaults removeObjectForKey:kAccessSecretStore];
    }
    [defaults synchronize];
}

#pragma mark Constructor / Destructor

- (id)init {
    if ((self = [super init])) {
        // 保存されたアクセストークンの取り出し。
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *accessKey = [defaults stringForKey:kAccessKeyStore];
        NSString *accessSecret = [defaults stringForKey:kAccessSecretStore];
        if (accessKey && accessSecret) {
            accessToken_ = [[OAToken alloc] initWithKey:accessKey secret:accessSecret];
        }
        // コンシューマーの初期化。
        consumer_ = [[OAConsumer alloc] initWithKey:kConsumerKey secret:kConsumerSecret];
    }
    return self;
}

- (void)dealloc {
    [consumer_ release];
    [requestToken_ release];
    [accessToken_ release];
    [super dealloc];
}

#pragma mark Shared Instance Methods

+ (TweetPosterOAuth *)sharedInstance {
    if (s_sharedInstance == nil) s_sharedInstance = [[TweetPosterOAuth alloc] init];
    return s_sharedInstance;
}

+ (void)disposeSharedInstance {
    [s_sharedInstance release];
    s_sharedInstance = nil;
}

@end
