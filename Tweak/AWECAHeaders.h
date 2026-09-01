// 抖音类声明
// @cookieodd | github.com/cookieodd | t.me/cookieodd

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <objc/runtime.h>

// 前向声明

@class AWECommentAudioModel;
@class AWECommentModel;
@class AWECommentAudioPlayer;
@class AWECommentAudioPlayerManager;
@class AWECommentAudioRecorder;
@class AWECommentAudioRecorderController;
@class AWECommentLongPressPanelParam;
@class AWECommentLongPressPanelCommonModel;
@class AWECommentLongPressPanelBizParam;

// 语音数据

@interface AWECommentAudioModel : NSObject
@property (copy, nonatomic) NSString *audioFilePath;
@property (copy, nonatomic) NSString *vID;
@property (copy, nonatomic) NSString *content;
@property (copy, nonatomic) NSString *wave;
@property (nonatomic) long long duration;
@property (copy, nonatomic) NSArray *waveArr;
@property (copy, nonatomic) NSArray *waveHeightArr;
@property (nonatomic) double currentTime;
@property (nonatomic) unsigned long long audioStatus;
@end

// 评论模型

@interface AWECommentModel : NSObject
@property (copy, nonatomic) NSString *commentID;
@property (strong, nonatomic) AWECommentAudioModel *audioModel;
@property (nonatomic) long long duration;
@end

// 播放器

@interface AWECommentAudioPlayer : NSObject
@property (copy, nonatomic) NSString *localUrlString;
@property (copy, nonatomic) NSString *videoModel;
@property (nonatomic) BOOL isPlaying;
@property (readonly, nonatomic) double currentTime;
@property (readonly, nonatomic) double duration;
- (void)startPlay;
- (void)stopPlay;
- (void)pausePlay;
@end

// 播放调度

@interface AWECommentAudioPlayerManager : NSObject
@property (strong, nonatomic) AWECommentAudioPlayer *player;
@property (nonatomic) double currentTime;
@property (nonatomic) double duration;
- (void)playAudioWithVideoModel:(id)arg1 startTime:(double)arg2;
- (void)playAudioWithLocalUrlString:(id)arg1 startTime:(double)arg2;
- (void)playAudioWithVideoModel:(id)arg1 startTime:(double)arg2 audioEffectExternInfo:(id)arg3;
- (void)stopAudioWithIsForce:(BOOL)arg1;
@end

// 录音器

@interface AWECommentAudioRecorder : NSObject
@property (strong, nonatomic) NSURL *url;
@property (strong, nonatomic) AVAudioRecorder *recorder;
@property (strong, nonatomic) NSMutableArray *averagePowerArr;
@property (nonatomic) double currentTime;
@property (nonatomic) double limitSecond;
@property (nonatomic) double minSecond;
@property (nonatomic) unsigned long long status;
- (void)record;
- (void)stop;
- (void)cancel;
@end

// 录音控制

@interface AWECommentAudioRecorderController : NSObject
@property (strong, nonatomic) AWECommentAudioRecorder *recorder;
@property (copy, nonatomic) NSString *audioFilePath;
@property (weak, nonatomic) id delegate;
- (void)audioRecorderDidFinishRecording:(id)arg1 success:(BOOL)arg2 error:(id)arg3;
- (void)audioRecorderStartRecord:(id)arg1 error:(id)arg2;
- (void)clear;
@end

// 长按菜单

@interface AWECommentLongPressPanelCommonModel : NSObject
@property (copy, nonatomic) NSString *tag;
@property (copy, nonatomic) NSString *commonID;
@property (copy, nonatomic) NSString *content;
@property (copy, nonatomic) NSString *iconUrl;
@property (nonatomic) long long style;
@property (strong, nonatomic) UIImage *icon;
@end

@interface AWECommentLongPressPanelParam : NSObject
@property (weak, nonatomic) AWECommentModel *selectdComment;
@property (weak, nonatomic) AWECommentModel *mainComment;
@end

@interface AWECommentLongPressPanelBizParam : NSObject
@property (nonatomic) double sheetHeight;
@end

@interface AWECommentLongPressPanelItemModel : NSObject
@property (copy, nonatomic) NSArray *elementList;
@end

@interface AWECommentLongPressPanelAdaptar : NSObject
- (void)showLongPressPanelWithParam:(id)arg1 config:(id)arg2 showSheetCompletion:(id)arg3 dismissSheetCompletion:(id)arg4;
- (id)containerSheet;
@end

// 长按上下文

@interface AWECommentLongPressPanelContext : NSObject
@property (strong, nonatomic) AWECommentLongPressPanelParam *params;
@end

// 菜单数据源

@interface AWEBaseListSectionViewModel : NSObject
@property (copy, nonatomic) NSArray *modelsArray;
- (void)appendModels:(id)arg1;
@end

@interface AWECommentLongPressDelegate : NSObject
@property (copy, nonatomic) id tappedBlock;
- (void)tappedCommonElementWithID:(id)arg1;
@end

// 输入栏

@interface AWECommentAudioContentView : UIView
@property (nonatomic) double duration;
@property (copy, nonatomic) NSArray *averagePowerArr;
@property (nonatomic) unsigned long long state;
@property (weak, nonatomic) id delegate;
- (id)initWithStyle:(unsigned long long)style isBGColorWhite:(BOOL)isBGColorWhite;
@end

@interface AWECommentAudioContentViewModel : NSObject
+ (id)averageWaveArrWithWave:(id)arg1;
@end

// 元素基类
@interface AWEBaseElement : NSObject
- (UIView *)view;
@end

// 元素视图
@interface AWEBaseElementView : UIView
@end

// 元素栈
@interface AWEElementStackView : UIView
@end

// 输入栏按钮

// 图片按钮
@interface AWECommentInputViewSwiftImpl_CommentImageIconElement : AWEBaseElement
@end

// @按钮
@interface AWECommentInputViewSwiftImpl_CommentAtIconElement : AWEBaseElement
@end

// 表情按钮
@interface AWECommentInputViewSwiftImpl_CommentEmojiIconElement : AWEBaseElement
@end

// 语音按钮
@interface AWECommentInputViewSwiftImpl_CommentAudioIconElement : AWEBaseElement
@end

// 定位按钮
@interface AWECommentInputViewSwiftImpl_CommentPoiIconElement : AWEBaseElement
@end

// 播放控制

@interface AWECommentListAudioPlayerController : NSObject
@property (strong, nonatomic) AWECommentAudioPlayerManager *playerManager;
@property (strong, nonatomic) AWECommentModel *currentCommentModel;
- (void)playAudioWithCommentModel:(id)arg1 audioEffectExternInfo:(id)arg2;
- (void)playAudioWithCommentModel:(id)arg1 seekToTime:(double)arg2;
- (void)stopAudioWithCommentModel:(id)arg1 isForce:(BOOL)arg2;
@end

// 上传管理

@interface AWECommentAudioUploadManager : NSObject
+ (id)sharedManager;
- (void)uploadAudioWithFilePath:(id)arg1 completion:(id)arg2;
- (void)uploadAudioWithFilePath:(id)arg1 authCompletion:(id)arg2 completion:(id)arg3;
- (void)startUploadAudioWithFilePath:(id)arg1;
@end

// 主题管理

@interface AWEUIThemeManager : NSObject
+ (id)sharedInstance;
+ (BOOL)isLightTheme;
- (id)currentTheme;
@end


