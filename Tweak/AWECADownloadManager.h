// 语音下载
// @cookieodd | github.com/cookieodd | t.me/cookieodd

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "AWECAHeaders.h"

@interface AWECADownloadManager : NSObject

+ (instancetype)shared;

- (void)cacheURL:(NSString *)url forVID:(NSString *)vID;
- (NSString *)cachedURLForVID:(NSString *)vID;

- (void)parseAndCacheVideoModelJSON:(NSString *)jsonStr;

- (void)showSaveDialogAndDownload:(AWECommentModel *)comment;

- (NSArray<NSString *> *)downloadedAudioFiles;
- (NSArray<NSString *> *)downloadedAudioDisplayNames;

@end
