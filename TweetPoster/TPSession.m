#import "TPSession.h"
#import "TPAsynchronousDataFetcher.h"

// Twitter App 登録情報
static NSString* kConsumerKey = @"TqaWmqgwBdGQXiAlgEGqMg";
static NSString* kConsumerSecret = @"wLRgb1nncMNzMCXpyqXbvxtKaAiT4nIv9deNyEWQnQ";

// Defaultsに保存する際に使うキー。
static NSString* kAccessKeyStore = @"TwitterAccessKey";
static NSString* kAccessSecretStore = @"TwitterAccessSecret";
static NSString* kUserNameStore = @"TwitterUserName";

// ユーザー名を取得するまでの間に使うダミー名。
static NSString* kDummyUserName = @"--";

// 共有インスタンス。
static TPSession *s_sharedInstance;

@implementation TPSession;

#pragma mark Property

@synthesize consumer = consumer_;
@synthesize requestToken = requestToken_;
@synthesize accessToken = accessToken_;

- (void)setAccessToken:(OAToken *)token {
    [accessToken_ release];
    accessToken_ = [token retain];
    // アクセストークンの保存（あるいは破棄）。
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (token) {
        [defaults setObject:token.key forKey:kAccessKeyStore];
        [defaults setObject:token.secret forKey:kAccessSecretStore];
        // ユーザー名の取得を開始。
        [defaults setObject:kDummyUserName forKey:kUserNameStore];
        [self verifyAccount:nil failureBlock:nil];
    } else {
        [defaults removeObjectForKey:kAccessKeyStore];
        [defaults removeObjectForKey:kAccessSecretStore];
    }
    [defaults synchronize];
}

- (BOOL)signedIn {
    return accessToken_ != nil;
}

- (NSString*)userNameCache {
    if (accessToken_) {
        return [[NSUserDefaults standardUserDefaults] objectForKey:kUserNameStore];
    } else {
        return nil;
    }
}

#pragma mark Initialization and cleanup

- (id)init {
    if ((self = [super init])) {
        consumer_ = [[OAConsumer alloc] initWithKey:kConsumerKey secret:kConsumerSecret];
        // 保存されたアクセストークンの取り出し。
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *accessKey = [defaults stringForKey:kAccessKeyStore];
        NSString *accessSecret = [defaults stringForKey:kAccessSecretStore];
        if (accessKey && accessSecret) {
            accessToken_ = [[OAToken alloc] initWithKey:accessKey secret:accessSecret];
        }
    }
    return self;
}

- (void)dealloc {
    [consumer_ release];
    [requestToken_ release];
    [accessToken_ release];
    [super dealloc];
}

#pragma mark Public methods

- (void)signOut {
    self.accessToken = nil;
}

- (void)verifyAccount:(void (^)(NSString *))resultBlock
         failureBlock:(void (^)(NSError *))failureBlock {
    NSURL *url = [NSURL URLWithString:@"http://api.twitter.com/1/account/verify_credentials.xml"];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc] initWithURL:url
                                                                   consumer:consumer_
                                                                      token:accessToken_
                                                                      realm:nil
                                        				  signatureProvider:nil];
    
    TPFetcherResultBlock resultBridge = ^(OAServiceTicket *ticket, NSData *data) {
        // verifyAccountの場合：データから名前部分を抽出してコールバックする。
        NSString *name = kDummyUserName;
        NSString *string = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
        NSUInteger begin = NSMaxRange([string rangeOfString:@"<screen_name>"]);
        NSUInteger end = [string rangeOfString:@"</screen_name>"].location;
        if (begin != NSNotFound && end != NSNotFound) {
            name = [string substringWithRange:NSMakeRange(begin, end - begin)];
            // ユーザー名のキャッシュ情報を更新する。
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setObject:name forKey:kUserNameStore];
            [defaults synchronize];
        }
        if (resultBlock) resultBlock(name);
    };
    
    TPFetcherFailureBlock failureBridge = ^(OAServiceTicket *ticket, NSError *error) {
        if (failureBlock) failureBlock(error);
    };
    
    TPAsynchronousDataFetcher *fetcher = [TPAsynchronousDataFetcher asynchronousFetcherWithRequest:request resultBlock:resultBridge failureBlock:failureBridge];
    [fetcher start];
}

- (void)postTweet:(NSString *)text
      resultBlock:(void (^)())resultBlock
     failureBlock:(void (^)(NSError *))failureBlock {
    NSURL *url = [NSURL URLWithString:@"http://api.twitter.com/1/statuses/update.xml"];
    OAMutableURLRequest *request = [[OAMutableURLRequest alloc] initWithURL:url
                                                                   consumer:consumer_
                                                                      token:accessToken_
                                                                      realm:nil
                                        				  signatureProvider:nil];
    [request setHTTPMethod:@"POST"];

    OARequestParameter *param = [[OARequestParameter alloc] initWithName:@"status" value:text];
    [request setParameters:[NSArray arrayWithObject:param]];
    
    TPFetcherResultBlock resultBridge = ^(OAServiceTicket *ticket, NSData *data) {
        if (resultBlock) resultBlock();
    };
    
    TPFetcherFailureBlock failureBridge = ^(OAServiceTicket *ticket, NSError *error) {
        if (failureBlock) failureBlock(error);
    };

    TPAsynchronousDataFetcher *fetcher = [TPAsynchronousDataFetcher asynchronousFetcherWithRequest:request resultBlock:resultBridge failureBlock:failureBridge];
    [fetcher start];
}

#pragma mark Shared instance method

+ (TPSession *)sharedInstance {
    if (s_sharedInstance == nil) s_sharedInstance = [[TPSession alloc] init];
    return s_sharedInstance;
}

+ (void)disposeSharedInstance {
    [s_sharedInstance release];
    s_sharedInstance = nil;
}

@end
