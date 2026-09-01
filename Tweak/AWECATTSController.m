// 文字合成页
// @cookieodd | github.com/cookieodd | t.me/cookieodd

#import "AWECATTSController.h"
#import "AWECATTSManager.h"
#import "AWECAUtils.h"

#define kTextMaxLength 300
#define kCellFont [UIFont systemFontOfSize:15]

@interface AWECATTSController () <UITextViewDelegate>
@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, strong) UILabel *placeholderLabel;
@property (nonatomic, assign) BOOL isSynthesizing;
@end

@implementation AWECATTSController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor systemGroupedBackgroundColor];
    [self setupUI];
    [self updateTitleView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [self updateTitleView];
    if (@available(iOS 16.0, *)) {
        UISheetPresentationController *sheet = self.navigationController.sheetPresentationController;
        if (sheet) {
            [sheet animateChanges:^{
                sheet.selectedDetentIdentifier = @"ttsCompact";
            }];
        }
    }
}

#pragma mark - 标题

- (void)updateTitleView {
    AWECATTSManager *mgr = [AWECATTSManager shared];
    NSString *name = mgr.voiceName.length > 0 ? mgr.voiceName : @"知性灿灿 2.0";
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = [NSString stringWithFormat:@"合成：%@", name];
    titleLabel.font = [UIFont systemFontOfSize:13];
    titleLabel.textColor = [UIColor secondaryLabelColor];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [titleLabel sizeToFit];
    self.navigationItem.titleView = titleLabel;
}

- (void)dismissKeyboard {
    [self.view endEditing:YES];
}

#pragma mark - 布局

- (void)setupUI {
    UIView *container = [[UIView alloc] init];
    container.translatesAutoresizingMaskIntoConstraints = NO;
    container.backgroundColor = [UIColor tertiarySystemBackgroundColor];
    container.layer.cornerRadius = 8;
    container.layer.borderWidth = 0.5;
    container.layer.borderColor = [UIColor separatorColor].CGColor;
    [self.view addSubview:container];

    UITextView *tv = [[UITextView alloc] init];
    tv.font = kCellFont;
    tv.backgroundColor = [UIColor clearColor];
    tv.delegate = self;
    tv.translatesAutoresizingMaskIntoConstraints = NO;
    UIToolbar *bar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    bar.items = @[
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
        [[UIBarButtonItem alloc] initWithTitle:@"完成" style:UIBarButtonItemStyleDone target:self action:@selector(dismissKeyboard)]
    ];
    tv.inputAccessoryView = bar;
    [container addSubview:tv];
    self.textView = tv;

    UILabel *ph = [[UILabel alloc] init];
    ph.text = @"在这里输入要合成的文字...";
    ph.font = kCellFont;
    ph.textColor = [UIColor placeholderTextColor];
    ph.translatesAutoresizingMaskIntoConstraints = NO;
    [container addSubview:ph];
    self.placeholderLabel = ph;

    UIButton *synthBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [synthBtn setTitle:@"合成替换" forState:UIControlStateNormal];
    synthBtn.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    [synthBtn setTitleColor:[UIColor systemBlueColor] forState:UIControlStateNormal];
    synthBtn.backgroundColor = [UIColor tertiarySystemBackgroundColor];
    synthBtn.layer.cornerRadius = 8;
    synthBtn.translatesAutoresizingMaskIntoConstraints = NO;
    [synthBtn addTarget:self action:@selector(synthesize)
        forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:synthBtn];

    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [container.topAnchor constraintEqualToAnchor:safe.topAnchor constant:8],
        [container.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:16],
        [container.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-16],
        [container.heightAnchor constraintEqualToConstant:120],
        [tv.topAnchor constraintEqualToAnchor:container.topAnchor constant:4],
        [tv.leadingAnchor constraintEqualToAnchor:container.leadingAnchor constant:4],
        [tv.trailingAnchor constraintEqualToAnchor:container.trailingAnchor constant:-4],
        [tv.bottomAnchor constraintEqualToAnchor:container.bottomAnchor constant:-4],
        [ph.topAnchor constraintEqualToAnchor:tv.topAnchor constant:8],
        [ph.leadingAnchor constraintEqualToAnchor:tv.leadingAnchor constant:5],
        [synthBtn.topAnchor constraintEqualToAnchor:container.bottomAnchor constant:8],
        [synthBtn.leadingAnchor constraintEqualToAnchor:container.leadingAnchor],
        [synthBtn.trailingAnchor constraintEqualToAnchor:container.trailingAnchor],
        [synthBtn.heightAnchor constraintEqualToConstant:44],
    ]];
}

#pragma mark - 输入代理

- (void)textViewDidChange:(UITextView *)textView {
    self.placeholderLabel.hidden = textView.text.length > 0;
    if (textView.text.length > kTextMaxLength) {
        textView.text = [textView.text substringToIndex:kTextMaxLength];
    }
}

#pragma mark - 合成

- (void)synthesize {
    NSString *text = self.textView.text;
    if (!text || text.length == 0) {
        [AWECAUtils showToast:@"请输入要合成的文字"];
        return;
    }
    if (self.isSynthesizing) return;
    self.isSynthesizing = YES;
    [AWECAUtils showToast:@"正在合成..."];

    [[AWECATTSManager shared] synthesizeText:text completion:^(BOOL success, NSString *audioPath, NSString *error) {
        self.isSynthesizing = NO;
        if (success) {
            [self.view endEditing:YES];
            if (self.navigationController.viewControllers.count > 1) {
                [self.navigationController popViewControllerAnimated:YES];
            } else if (self.presentingViewController) {
                [self dismissViewControllerAnimated:YES completion:^{
                    for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
                        if ([scene isKindOfClass:[UIWindowScene class]]) {
                            for (UIWindow *w in ((UIWindowScene *)scene).windows) {
                                [w endEditing:YES];
                            }
                        }
                    }
                }];
            }
        } else {
            [AWECAUtils showToast:error ?: @"合成失败"];
        }
    }];
}

@end
