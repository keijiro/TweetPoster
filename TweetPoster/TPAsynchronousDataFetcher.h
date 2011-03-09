//
// TPAsynchronousDataFetcher - 非同期にOAConsumerへのリクエストを処理するクラス。
// 
// OAAsynchronousDataFetcherをBlockを使った設計に直したもの。
// 処理の内容はほぼ同じ。
//

#import <Foundation/Foundation.h>
#import "OAMutableURLRequest.h"
#import "OAServiceTicket.h"

typedef void (^TPFetcherResultBlock)(OAServiceTicket *, NSData *);
typedef void (^TPFetcherFailureBlock)(OAServiceTicket *, NSError *);

@interface TPAsynchronousDataFetcher : NSObject {
    OAMutableURLRequest *request;
    NSURLResponse *response;
    NSURLConnection *connection;
    NSMutableData *responseData;
    TPFetcherResultBlock resultBlock;
    TPFetcherFailureBlock failureBlock;
}

+ (id)asynchronousFetcherWithRequest:(OAMutableURLRequest *)aRequest
                         resultBlock:(TPFetcherResultBlock)aResultBlock
                        failureBlock:(TPFetcherFailureBlock)aFailureBlock;

- (id)initWithRequest:(OAMutableURLRequest *)aRequest
          resultBlock:(TPFetcherResultBlock)aResultBlock
         failureBlock:(TPFetcherFailureBlock)aFailureBlock;

- (void)start;
- (void)cancel;

@end
