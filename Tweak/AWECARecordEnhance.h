// 录音转音色
// @cookieodd | github.com/cookieodd | t.me/cookieodd

#import <Foundation/Foundation.h>

#define kAWECAEnhanceEnabled @"AWECAEnhanceEnabled"
#define kAWECAStatusDotTag   19527

@interface AWECARecordEnhance : NSObject

+ (instancetype)shared;

@property (nonatomic, assign) BOOL enhanceEnabled;
@property (nonatomic, assign, readonly) BOOL armed;

+ (BOOL)shouldShowStatusDot;
+ (void)refreshStatusDots;

- (void)armFromCommentButton;
- (void)markCommentTakeStarted;
- (void)markCommentTakeCancelled;

- (BOOL)shouldRunForCommentRecording;
- (BOOL)shouldSkipStickyReplaceForPath:(NSString *)path;

- (void)beginIfNeededAtPath:(NSString *)path;
- (void)waitForEnhancedPath:(NSString *)path
                 completion:(void(^)(BOOL ok, NSString *message))completion;

@end
