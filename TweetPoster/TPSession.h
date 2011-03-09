//
// TPSession - Twitterサービスへの接続を担うクラス。
//
// 認証以外の基本敵な機能はこのクラスから提供される。
// 認証の手続きはGUIと一体化しているため、別のクラスにまとめた。
//

#import <Foundation/Foundation.h>
#import "OAuthConsumer.h"

@interface TPSession : NSObject {
    OAConsumer* consumer_;
    OAToken* requestToken_;
    OAToken* accessToken_;
}

// これらのプロパティは基本的にTPAuthenticationViewControllerのみがアクセスする。
@property (nonatomic, readonly) OAConsumer *consumer;
@property (nonatomic, retain) OAToken* requestToken;
@property (nonatomic, retain) OAToken* accessToken;

// サインイン状態の取得。
@property (nonatomic, readonly) BOOL signedIn;

// サインアウト。
- (void)signOut;

// アカウントの確認およびユーザー名の取得（非同期）。
- (void)verifyAccount:(void (^)(NSString *userName))resultBlock
         failureBlock:(void (^)(NSError *error))failureBlock;

// ツイートの投稿（非同期）。
- (void)postTweet:(NSString *)text
      resultBlock:(void (^)())resultBlock
     failureBlock:(void (^)(NSError *error))failureBlock;

// 共有インスタンスの操作。
+ (TPSession *)sharedInstance;
+ (void)disposeSharedInstance;

@end
