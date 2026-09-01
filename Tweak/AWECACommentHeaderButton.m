// 评论顶栏入口
// @cookieodd | github.com/cookieodd | t.me/cookieodd

#import "AWECACommentHeaderButton.h"
#import "AWECAAudioPickerController.h"
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <objc/message.h>

#define kAWECAWaveformTag 19529
static NSString * const kAWECAWaveformAccId = @"AWECAWaveformButton";
static NSString * const kAWECACloseAccId = @"CommentPanelCloseButton";
static NSString * const kAWECAShrinkAccId = @"CommentPanelShrinkButton";
static NSString * const kAWECAMagnifyAccId = @"CommentPanelMagnifyButton";

static BOOL AWECAColorIsFaint(UIColor *c) {
    if (!c) return YES;
    CGFloat r = 0, g = 0, b = 0, a = 0, w = 0;
    if ([c getRed:&r green:&g blue:&b alpha:&a]) return a < 0.25;
    if ([c getWhite:&w alpha:&a]) return a < 0.25;
    return YES;
}

static CGFloat AWECALuma(UIColor *c) {
    if (!c) return 1.0;
    CGFloat r = 0, g = 0, b = 0, a = 1, w = 1;
    if ([c getRed:&r green:&g blue:&b alpha:&a]) return 0.2126 * r + 0.7152 * g + 0.0722 * b;
    if ([c getWhite:&w alpha:&a]) return w;
    return 1.0;
}

static UIColor *AWECAResolved(UIColor *c, UIView *v) {
    if (!c || !v) return c;
    if (@available(iOS 13.0, *)) return [c resolvedColorWithTraitCollection:v.traitCollection];
    return c;
}

static BOOL AWECAViewLooksDark(UIView *start) {
    for (UIView *v = start; v; v = v.superview) {
        UIColor *bg = AWECAResolved(v.backgroundColor, v);
        if (AWECAColorIsFaint(bg)) continue;
        return AWECALuma(bg) < 0.55;
    }
    return NO;
}

#pragma mark - 查找

static UIView *AWECAFindAccIdDeep(UIView *root, NSString *accId, NSInteger depth) {
    if (!root || !accId.length || depth > 24) return nil;
    if ([root.accessibilityIdentifier isEqualToString:accId]) return root;
    for (UIView *s in root.subviews) {
        UIView *found = AWECAFindAccIdDeep(s, accId, depth + 1);
        if (found) return found;
    }
    return nil;
}

static Class AWECAInteractionButtonClass(void) {
    static Class cls;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        cls = NSClassFromString(@"AWECommentSwiftBizUI.CommentInteractionBaseButton");
    });
    return cls;
}

static void AWECAWalkRightmostChip(UIView *node, UIView *root, Class btnCls, NSInteger depth, UIView **best, CGFloat *bestX) {
    if (!node || !best || !bestX || depth > 24) return;
    if (btnCls && [node isKindOfClass:btnCls] && !node.hidden) {
        CGFloat w = node.bounds.size.width;
        if (w >= 20 && w <= 36) {
            CGRect r = [node convertRect:node.bounds toView:root];
            if (r.origin.x > *bestX) {
                *bestX = r.origin.x;
                *best = node;
            }
        }
    }
    for (UIView *s in node.subviews) {
        AWECAWalkRightmostChip(s, root, btnCls, depth + 1, best, bestX);
    }
}

static UIView *AWECAFindHeaderChip(UIView *root) {
    UIView *v = AWECAFindAccIdDeep(root, kAWECACloseAccId, 0);
    if (v) return v;
    v = AWECAFindAccIdDeep(root, kAWECAMagnifyAccId, 0);
    if (v) return v;
    v = AWECAFindAccIdDeep(root, kAWECAShrinkAccId, 0);
    if (v) return v;

    Class btnCls = AWECAInteractionButtonClass();
    if (!btnCls) return nil;
    UIView *best = nil;
    CGFloat bestX = -1;
    AWECAWalkRightmostChip(root, root, btnCls, 0, &best, &bestX);
    return best;
}

static UIImageView *AWECAFirstImageView(UIView *v) {
    if (!v) return nil;
    if ([v isKindOfClass:[UIImageView class]] && v.bounds.size.width > 1) return (UIImageView *)v;
    for (UIView *s in v.subviews) {
        UIImageView *found = AWECAFirstImageView(s);
        if (found) return found;
    }
    return nil;
}

static UIViewController *AWECAVCFromView(UIView *view) {
    UIResponder *r = view;
    while (r) {
        if ([r isKindOfClass:[UIViewController class]]) return (UIViewController *)r;
        r = r.nextResponder;
    }
    return nil;
}

#pragma mark - 按钮

@interface AWECAWaveformButton : UIButton
- (void)aweca_applyChromeFromReference:(UIView *)ref;
@end

@implementation AWECAWaveformButton

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.tag = kAWECAWaveformTag;
        self.accessibilityIdentifier = kAWECAWaveformAccId;
        self.clipsToBounds = YES;
        self.userInteractionEnabled = YES;
        [self addTarget:self action:@selector(aweca_tapped) forControlEvents:UIControlEventTouchUpInside];
        [self aweca_applyChromeFromReference:nil];
    }
    return self;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    if (self.traitCollection.userInterfaceStyle == previousTraitCollection.userInterfaceStyle) return;
    UIView *ref = self.superview ? AWECAFindHeaderChip(self.superview) : nil;
    [self aweca_applyChromeFromReference:ref];
}

- (void)aweca_applyChromeFromReference:(UIView *)ref {
    BOOL dark = AWECAViewLooksDark(ref.superview ?: (self.superview ?: self));
    UIColor *fill = dark
        ? [UIColor colorWithWhite:1.0 alpha:0.08]
        : [UIColor colorWithRed:22.0 / 255.0 green:24.0 / 255.0 blue:35.0 / 255.0 alpha:0.05];
    UIColor *tint = dark ? [UIColor colorWithWhite:1 alpha:1] : [UIColor colorWithWhite:0 alpha:1];
    CGFloat radius = self.bounds.size.height > 1 ? self.bounds.size.height / 2.0 : 12.0;
    CGFloat iconPoint = 14.0;

    if (ref) {
        UIColor *refFill = AWECAResolved(ref.backgroundColor, ref);
        if (refFill && !AWECAColorIsFaint(refFill)) fill = ref.backgroundColor;
        else if (ref.backgroundColor) fill = ref.backgroundColor;
        if (ref.layer.cornerRadius > 0.5) radius = ref.layer.cornerRadius;
        UIImageView *iv = AWECAFirstImageView(ref);
        if (iv.bounds.size.width > 1) iconPoint = MIN(iv.bounds.size.width, iv.bounds.size.height);
        dark = AWECAViewLooksDark(ref.superview ?: ref);
        tint = dark ? [UIColor colorWithWhite:1 alpha:1] : [UIColor colorWithWhite:0 alpha:1];
    }

    self.backgroundColor = fill;
    self.layer.cornerRadius = radius;
    UIImageSymbolConfiguration *cfg = [UIImageSymbolConfiguration configurationWithPointSize:iconPoint
                                                                                      weight:UIImageSymbolWeightRegular];
    UIImage *img = [UIImage systemImageNamed:@"waveform" withConfiguration:cfg];
    img = [img imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [self setImage:img forState:UIControlStateNormal];
    self.tintColor = tint;
    self.imageView.tintColor = tint;
}

- (void)aweca_tapped {
    UIViewController *hostVC = AWECAVCFromView(self);
    if (!hostVC) return;
    AWECAAudioPickerController *picker = [[AWECAAudioPickerController alloc] init];
    picker.embeddedInCommentTab = YES;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:picker];
    nav.modalPresentationStyle = UIModalPresentationPageSheet;
    if (@available(iOS 15.0, *)) {
        UISheetPresentationController *sheet = nav.sheetPresentationController;
        if (sheet) {
            sheet.detents = @[
                UISheetPresentationControllerDetent.mediumDetent,
                UISheetPresentationControllerDetent.largeDetent
            ];
            sheet.prefersGrabberVisible = YES;
        }
    }
    [hostVC presentViewController:nav animated:YES completion:nil];
}

@end

#pragma mark - 布局

static AWECAWaveformButton *AWECAExistingWaveform(UIView *root) {
    UIView *v = AWECAFindAccIdDeep(root, kAWECAWaveformAccId, 0);
    if ([v isKindOfClass:[AWECAWaveformButton class]]) return (AWECAWaveformButton *)v;
    UIView *tagged = [root viewWithTag:kAWECAWaveformTag];
    if ([tagged isKindOfClass:[AWECAWaveformButton class]]) return (AWECAWaveformButton *)tagged;
    return nil;
}

static CGRect AWECAChipFrameInHost(UIView *chip, UIView *host) {
    if (!chip || !host) return CGRectMake(0, 8, 24, 24);
    CGRect r = [chip convertRect:chip.bounds toView:host];
    if (r.size.width < 8 || r.size.height < 8) {
        r.size = CGSizeMake(24, 24);
        if (r.origin.y < 1) r.origin.y = 8;
    }
    return r;
}

static void AWECAAttachWaveformOnView(UIView *root) {
    if (!root) return;

    UIView *close = AWECAFindAccIdDeep(root, kAWECACloseAccId, 0);
    UIView *magnify = AWECAFindAccIdDeep(root, kAWECAMagnifyAccId, 0);
    UIView *shrink = AWECAFindAccIdDeep(root, kAWECAShrinkAccId, 0);
    UIView *chip = close ?: magnify ?: shrink;
    if (!chip) chip = AWECAFindHeaderChip(root);
    if (!chip) return;

    UIView *host = chip.superview ?: root;
    AWECAWaveformButton *btn = AWECAExistingWaveform(host);
    if (!btn) btn = AWECAExistingWaveform(root);
    if (!btn) {
        btn = [[AWECAWaveformButton alloc] initWithFrame:CGRectMake(0, 8, 24, 24)];
        [host addSubview:btn];
    } else if (btn.superview != host) {
        [btn removeFromSuperview];
        [host addSubview:btn];
    }

    UIView *leftChip = nil;
    if (magnify && !magnify.hidden) leftChip = magnify;
    else if (shrink && !shrink.hidden) leftChip = shrink;
    else if (magnify) leftChip = magnify;
    else if (shrink) leftChip = shrink;
    else leftChip = close;
    if (!leftChip) leftChip = chip;

    CGRect ref = AWECAChipFrameInHost(leftChip, host);
    CGRect closeR = close ? AWECAChipFrameInHost(close, host) : CGRectZero;
    CGFloat stride = 44;
    if (close && leftChip != close) {
        CGFloat native = closeR.origin.x - ref.origin.x;
        if (native >= 28 && native <= 64) stride = native;
    }

    CGFloat x = ref.origin.x - stride;
    if (x < 8) x = 8;

    btn.hidden = NO;
    btn.alpha = 1;
    btn.userInteractionEnabled = YES;
    btn.frame = CGRectMake(x, ref.origin.y, ref.size.width, ref.size.height);
    btn.layer.zPosition = 999;
    [btn aweca_applyChromeFromReference:chip];
    [host bringSubviewToFront:btn];
}

static UIView *AWECARootFromObject(id obj) {
    if ([obj isKindOfClass:[UIViewController class]]) return ((UIViewController *)obj).view;
    if ([obj isKindOfClass:[UIView class]]) return obj;
    if ([obj respondsToSelector:@selector(view)]) {
        id v = [obj view];
        if ([v isKindOfClass:[UIView class]]) return v;
    }
    return nil;
}

#pragma mark - Hook

static BOOL AWECASwizzle(Class cls, SEL sel, IMP newIMP, const char *fallbackTypes, IMP *origOut) {
    if (!cls || !sel || !newIMP || !origOut) return NO;
    *origOut = NULL;
    Method method = class_getInstanceMethod(cls, sel);
    if (!method) {
        if (!fallbackTypes) return NO;
        BOOL added = class_addMethod(cls, sel, newIMP, fallbackTypes);
        if (added) *origOut = NULL;
        return added;
    }
    const char *types = method_getTypeEncoding(method);
    IMP orig = method_getImplementation(method);
    if (class_addMethod(cls, sel, newIMP, types ?: fallbackTypes)) {
        *origOut = orig;
        return YES;
    }
    *origOut = method_setImplementation(method, newIMP);
    return *origOut != NULL;
}

static void (*orig_innerLayout)(id, SEL);
static void hook_innerLayout(id self, SEL _cmd) {
    if (orig_innerLayout) orig_innerLayout(self, _cmd);
    AWECAAttachWaveformOnView(AWECARootFromObject(self));
}

static void (*orig_innerAppear)(id, SEL, BOOL);
static void hook_innerAppear(id self, SEL _cmd, BOOL animated) {
    if (orig_innerAppear) orig_innerAppear(self, _cmd, animated);
    UIView *root = AWECARootFromObject(self);
    AWECAAttachWaveformOnView(root);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        AWECAAttachWaveformOnView(root);
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        AWECAAttachWaveformOnView(root);
    });
}

static void (*orig_setupVH)(id, SEL);
static void hook_setupVH(id self, SEL _cmd) {
    if (orig_setupVH) orig_setupVH(self, _cmd);
    dispatch_async(dispatch_get_main_queue(), ^{
        AWECAAttachWaveformOnView(AWECARootFromObject(self));
    });
}

static void (*orig_enterFull)(id, SEL);
static void hook_enterFull(id self, SEL _cmd) {
    if (orig_enterFull) orig_enterFull(self, _cmd);
    dispatch_async(dispatch_get_main_queue(), ^{
        AWECAAttachWaveformOnView(AWECARootFromObject(self));
    });
}

static void (*orig_exitFull)(id, SEL);
static void hook_exitFull(id self, SEL _cmd) {
    if (orig_exitFull) orig_exitFull(self, _cmd);
    dispatch_async(dispatch_get_main_queue(), ^{
        AWECAAttachWaveformOnView(AWECARootFromObject(self));
    });
}

static void (*orig_containerAppear)(id, SEL, BOOL);
static void hook_containerAppear(id self, SEL _cmd, BOOL animated) {
    if (orig_containerAppear) orig_containerAppear(self, _cmd, animated);
    UIView *root = AWECARootFromObject(self);
    AWECAAttachWaveformOnView(root);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        AWECAAttachWaveformOnView(root);
    });
}

void AWECASetupCommentHeaderButton(void) {
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        Class inner = NSClassFromString(@"AWECommentPanelContainerSwiftImpl.CommentContainerInnerViewController");
        if (inner) {
            AWECASwizzle(inner, @selector(viewDidLayoutSubviews), (IMP)hook_innerLayout, "v@:", (IMP *)&orig_innerLayout);
            AWECASwizzle(inner, @selector(viewDidAppear:), (IMP)hook_innerAppear, "v@:B", (IMP *)&orig_innerAppear);
        }
        Class holder = NSClassFromString(@"AWECommentPanelContainerSwiftImpl.CommentContainerInnerViewHolder");
        if (holder) {
            AWECASwizzle(holder, @selector(setupViewHolder), (IMP)hook_setupVH, "v@:", (IMP *)&orig_setupVH);
            AWECASwizzle(holder, @selector(enterFullScreen), (IMP)hook_enterFull, "v@:", (IMP *)&orig_enterFull);
            AWECASwizzle(holder, @selector(exitFullScreen), (IMP)hook_exitFull, "v@:", (IMP *)&orig_exitFull);
        }
        Class container = NSClassFromString(@"AWECommentContainerViewController");
        if (container) {
            AWECASwizzle(container, @selector(viewDidAppear:), (IMP)hook_containerAppear, "v@:B", (IMP *)&orig_containerAppear);
        }
    });
}
