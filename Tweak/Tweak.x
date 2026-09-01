// 评论语音 Hook
// @cookieodd | github.com/cookieodd | t.me/cookieodd

#import "AWECAHeaders.h"
#import "AWECAUtils.h"
#import "AWECADownloadManager.h"
#import "AWECAAudioReplacer.h"
#import "AWECACommentHeaderButton.h"
#import "AWECARecordEnhance.h"
#import <objc/runtime.h>
#import <objc/message.h>

static void setupAudioIconElementHook(void);
static void setupAudioInputElementHook(void);

// 录音结束替换

%hook AWECommentAudioRecorderController

- (void)audioRecorderStartRecord:(id)recorder error:(id)error {
    %orig;
    if (!error) {
        [[AWECARecordEnhance shared] markCommentTakeStarted];
    }
}

- (void)clear {
    [[AWECARecordEnhance shared] markCommentTakeCancelled];
    %orig;
}

- (void)audioRecorderDidFinishRecording:(id)recorder success:(BOOL)success error:(id)error {
    NSString *path = self.audioFilePath.length ? self.audioFilePath : self.recorder.url.path;
    AWECARecordEnhance *enhance = [AWECARecordEnhance shared];

    if (success && enhance.enhanceEnabled && enhance.armed && ![enhance shouldRunForCommentRecording]) {
        [AWECAUtils showToast:@"请先填写火山 API Key"];
        %orig;
        return;
    }

    if (success && [enhance shouldRunForCommentRecording] && path.length) {
        [enhance beginIfNeededAtPath:path];
        %orig;
        return;
    }

    if (success && [enhance shouldSkipStickyReplaceForPath:path]) {
        %orig;
        return;
    }

    if (success && [AWECAAudioReplacer shared].enabled) {
        NSString *recorderURL = self.recorder.url.path;
        %orig;
        NSString *pathAfter = self.audioFilePath;

        if (pathAfter.length > 0) {
            [[AWECAAudioReplacer shared] replaceAudioAtPath:pathAfter];
        } else if (recorderURL.length > 0) {
            [[AWECAAudioReplacer shared] replaceAudioAtPath:recorderURL];
        }
        [AWECAUtils showToast:@"语音已替换"];
    } else {
        %orig;
    }
}

- (void)setAudioFilePath:(NSString *)audioFilePath {
    %orig;
    if (!audioFilePath.length) return;
    if ([[AWECARecordEnhance shared] shouldSkipStickyReplaceForPath:audioFilePath]) return;
    if (![AWECAAudioReplacer shared].enabled) return;
    if ([[NSFileManager defaultManager] fileExistsAtPath:audioFilePath]) {
        [[AWECAAudioReplacer shared] replaceAudioAtPath:audioFilePath];
    }
}

%end

// 播放时缓存地址

%hook AWECommentAudioPlayerManager

- (void)playAudioWithVideoModel:(id)videoModel startTime:(double)startTime audioEffectExternInfo:(id)info {
    if (videoModel && [videoModel isKindOfClass:[NSString class]]) {
        NSString *jsonStr = (NSString *)videoModel;
        [[AWECADownloadManager shared] parseAndCacheVideoModelJSON:jsonStr];
    }
    %orig;
}

- (void)playAudioWithVideoModel:(id)videoModel startTime:(double)startTime {
    if (videoModel && [videoModel isKindOfClass:[NSString class]]) {
        [[AWECADownloadManager shared] parseAndCacheVideoModelJSON:(NSString *)videoModel];
    }
    %orig;
}

%end

// 长按保存语音

%hook AWECommentLongPressPanelAdaptar

- (void)showLongPressPanelWithParam:(id)param config:(id)config showSheetCompletion:(id)showCompletion dismissSheetCompletion:(id)dismissCompletion {
    %orig;

    AWECommentModel *comment = nil;
    if ([param respondsToSelector:@selector(selectdComment)]) {
        comment = [(AWECommentLongPressPanelParam *)param selectdComment];
    }

    if (!comment || !comment.audioModel) {
        return;
    }

    AWECommentModel *savedComment = comment;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[AWECADownloadManager shared] showSaveDialogAndDownload:savedComment];
    });
}

%end

// 上传前再次替换

%hook AWECommentAudioUploadManager

- (void)startUploadAudioWithFilePath:(id)filePath {
    NSString *path = (NSString *)filePath;
    if (![[AWECARecordEnhance shared] shouldSkipStickyReplaceForPath:path] &&
        [AWECAAudioReplacer shared].enabled && filePath) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
            [[AWECAAudioReplacer shared] replaceAudioAtPath:path];
        }
    }
    %orig;
}

- (void)uploadAudioWithFilePath:(id)filePath completion:(id)completion {
    NSString *path = (NSString *)filePath;
    if (![[AWECARecordEnhance shared] shouldSkipStickyReplaceForPath:path] &&
        [AWECAAudioReplacer shared].enabled && filePath) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
            [[AWECAAudioReplacer shared] replaceAudioAtPath:path];
        }
    }
    %orig;
}

- (void)uploadAudioWithFilePath:(id)filePath authCompletion:(id)authCompletion completion:(id)completion {
    NSString *path = (NSString *)filePath;
    if (![[AWECARecordEnhance shared] shouldSkipStickyReplaceForPath:path] &&
        [AWECAAudioReplacer shared].enabled && filePath) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
            [[AWECAAudioReplacer shared] replaceAudioAtPath:path];
        }
    }
    %orig;
}

%end


// 预览气泡替换

static void (*orig_generateAudioPreviewBubble)(id self, SEL _cmd, id recordedModel);
static void hook_generateAudioPreviewBubble(id self, SEL _cmd, id recordedModel) {
    NSString *audioPath = [recordedModel valueForKey:@"audioFilePath"];
    AWECARecordEnhance *enhance = [AWECARecordEnhance shared];

    if (recordedModel && [enhance shouldRunForCommentRecording] && audioPath.length) {
        [enhance waitForEnhancedPath:audioPath completion:^(BOOL ok, NSString *message) {
            if (ok) {
                double realDur = [AWECAUtils audioDurationAtPath:audioPath];
                [recordedModel setValue:@((long long)(realDur * 1000)) forKey:@"duration"];
            }
            orig_generateAudioPreviewBubble(self, _cmd, recordedModel);
            if (message.length) [AWECAUtils showToast:message duration:2.5];
        }];
        return;
    }

    if (recordedModel && ![enhance shouldSkipStickyReplaceForPath:audioPath] && [AWECAAudioReplacer shared].enabled) {
        if (audioPath.length > 0 && [[NSFileManager defaultManager] fileExistsAtPath:audioPath]) {
            BOOL ok = [[AWECAAudioReplacer shared] replaceAudioAtPath:audioPath];

            if (ok) {
                double realDur = [AWECAUtils audioDurationAtPath:audioPath];
                long long realMs = (long long)(realDur * 1000);
                [recordedModel setValue:@(realMs) forKey:@"duration"];
            }
        }
    }
    orig_generateAudioPreviewBubble(self, _cmd, recordedModel);
}

static void setupAudioInputElementHook(void) {
    Class cls = NSClassFromString(@"AWECommentInputViewSwiftImpl.CommentInputAudioInputElement");
    if (!cls) {
        return;
    }
    SEL sel = @selector(generateAudioPreviewBubbleWithRecordedModel:);
    Method method = class_getInstanceMethod(cls, sel);
    if (method) {
        orig_generateAudioPreviewBubble = (void (*)(id, SEL, id))method_getImplementation(method);
        method_setImplementation(method, (IMP)hook_generateAudioPreviewBubble);
    }
}

// 麦克风原生录音

static void (*orig_audioIconViewDidLoad)(id self, SEL _cmd);
static void hook_audioIconViewDidLoad(id self, SEL _cmd) {
    orig_audioIconViewDidLoad(self, _cmd);

    UIView *elementView = nil;
    if ([self respondsToSelector:@selector(view)]) {
        elementView = [self performSelector:@selector(view)];
    }
    if (!elementView) return;

    UIView *redDot = [[UIView alloc] initWithFrame:CGRectMake(elementView.bounds.size.width - 8, 2, 6, 6)];
    redDot.backgroundColor = [UIColor redColor];
    redDot.layer.cornerRadius = 3;
    redDot.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    redDot.hidden = ![AWECARecordEnhance shouldShowStatusDot];
    redDot.tag = kAWECAStatusDotTag;
    [elementView addSubview:redDot];
}

static void (*orig_handleAudioButton)(id self, SEL _cmd);
static void hook_handleAudioButton(id self, SEL _cmd) {
    [[AWECARecordEnhance shared] armFromCommentButton];
    orig_handleAudioButton(self, _cmd);
}

static void setupAudioIconElementHook(void) {
    Class cls = NSClassFromString(@"AWECommentInputViewSwiftImpl.CommentAudioIconElement");
    if (!cls) return;
    SEL sel = @selector(viewDidLoad);
    Method method = class_getInstanceMethod(cls, sel);
    if (method) {
        orig_audioIconViewDidLoad = (void (*)(id, SEL))method_getImplementation(method);
        method_setImplementation(method, (IMP)hook_audioIconViewDidLoad);
    }

    SEL btnSel = @selector(handleAudioButton);
    Method btnMethod = class_getInstanceMethod(cls, btnSel);
    if (btnMethod) {
        orig_handleAudioButton = (void (*)(id, SEL))method_getImplementation(btnMethod);
        method_setImplementation(btnMethod, (IMP)hook_handleAudioButton);
    }
}

// 插件初始化

%ctor {
    @autoreleasepool {
        [AWECAUtils ensureDirectoriesExist];

        [AWECAAudioReplacer shared];
        [AWECARecordEnhance shared];

        setupAudioInputElementHook();
        setupAudioIconElementHook();
        AWECASetupCommentHeaderButton();
    }
}
