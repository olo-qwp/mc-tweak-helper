#import "MCMenuView.h"
#import "MCEventSimulator.h"

// ============================================================
// 颜色常量 - 暗色主题
// ============================================================
#define COLOR_BG       [UIColor colorWithWhite:0.08 alpha:0.92]
#define COLOR_TINT     [UIColor colorWithRed:0.33 green:0.68 blue:1.00 alpha:1.0]
#define COLOR_TEXT     [UIColor whiteColor]
#define COLOR_SUBTEXT  [UIColor colorWithWhite:0.7 alpha:1.0]
#define COLOR_BORDER   [UIColor colorWithWhite:0.2 alpha:1.0]

// ============================================================
// MCFloatingButton - 可拖动的浮动按钮
// ============================================================
@interface MCFloatingButton ()

@property (nonatomic, assign, readwrite) BOOL dragging;
@property (nonatomic, assign) CGPoint lastTouchPoint;

@end

@implementation MCFloatingButton

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.layer.cornerRadius = frame.size.width / 2;
        self.layer.masksToBounds = YES;
        self.backgroundColor = COLOR_TINT;
        self.layer.shadowColor = [UIColor blackColor].CGColor;
        self.layer.shadowOffset = CGSizeMake(0, 4);
        self.layer.shadowOpacity = 0.4;
        self.layer.shadowRadius = 8;
        
        // 锤子图标 (用文字代替)
        [self setTitle:@"⛏" forState:UIControlStateNormal];
        self.titleLabel.font = [UIFont systemFontOfSize:24];
        
        // 添加拖拽手势
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        [self addGestureRecognizer:pan];
    }
    return self;
}

- (void)handlePan:(UIPanGestureRecognizer *)gesture {
    CGPoint translation = [gesture translationInView:self.superview];
    CGPoint center = self.center;
    center.x += translation.x;
    center.y += translation.y;
    self.center = center;
    [gesture setTranslation:CGPointZero inView:self.superview];
    
    if (gesture.state == UIGestureRecognizerStateBegan) {
        self.dragging = YES;
        [UIView animateWithDuration:0.2 animations:^{
            self.transform = CGAffineTransformMakeScale(1.3, 1.3);
            self.alpha = 0.8;
        }];
    } else if (gesture.state == UIGestureRecognizerStateEnded ||
               gesture.state == UIGestureRecognizerStateCancelled) {
        self.dragging = NO;
        [UIView animateWithDuration:0.2 animations:^{
            self.transform = CGAffineTransformIdentity;
            self.alpha = 1.0;
        }];
        
        // 吸附到屏幕边缘
        CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
        CGFloat snapX = center.x > screenWidth / 2 ? screenWidth - 35 : 35;
        [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.center = CGPointMake(snapX, MIN(MAX(center.y, 50), [UIScreen mainScreen].bounds.size.height - 50));
        } completion:nil];
    }
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    // 扩大点击区域
    CGFloat margin = -10;
    CGRect largerArea = CGRectInset(self.bounds, margin, margin);
    return CGRectContainsPoint(largerArea, point);
}

@end

// ============================================================
// MCMenuPanel - 功能面板
// ============================================================
@interface MCMenuPanel ()

@property (nonatomic, strong) UISwitch *autoClickSwitch;
@property (nonatomic, strong) UILabel *autoClickLabel;
@property (nonatomic, strong) UISlider *speedSlider;
@property (nonatomic, strong) UILabel *speedLabel;
@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, strong) UIView *statusIndicator;

@end

@implementation MCMenuPanel

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    self.backgroundColor = COLOR_BG;
    self.layer.cornerRadius = 16;
    self.layer.masksToBounds = YES;
    self.layer.borderWidth = 0.5;
    self.layer.borderColor = COLOR_BORDER.CGColor;
    
    CGFloat y = 16;
    CGFloat w = self.frame.size.width - 32;
    CGFloat indent = 16;
    
    // ---- 标题 ----
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(indent, y, w - 60, 28)];
    titleLabel.text = @"⚡ MC 辅助工具";
    titleLabel.font = [UIFont boldSystemFontOfSize:17];
    titleLabel.textColor = COLOR_TEXT;
    [self addSubview:titleLabel];
    
    // 关闭按钮
    self.closeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.closeButton.frame = CGRectMake(w + 4, y, 28, 28);
    [self.closeButton setTitle:@"✕" forState:UIControlStateNormal];
    self.closeButton.titleLabel.font = [UIFont boldSystemFontOfSize:18];
    [self.closeButton setTintColor:[UIColor lightGrayColor]];
    [self.closeButton addTarget:self action:@selector(closePanel) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.closeButton];
    
    y += 38;
    
    // ---- 分隔线 ----
    UIView *line1 = [[UIView alloc] initWithFrame:CGRectMake(indent, y, w, 0.5)];
    line1.backgroundColor = COLOR_BORDER;
    [self addSubview:line1];
    y += 12;
    
    // ---- 连点器开关 ----
    self.autoClickLabel = [[UILabel alloc] initWithFrame:CGRectMake(indent, y, 120, 32)];
    self.autoClickLabel.text = @"🖱 连点器";
    self.autoClickLabel.font = [UIFont systemFontOfSize:15];
    self.autoClickLabel.textColor = COLOR_TEXT;
    [self addSubview:self.autoClickLabel];
    
    self.autoClickSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(w - 56, y, 0, 0)];
    self.autoClickSwitch.onTintColor = COLOR_TINT;
    [self.autoClickSwitch addTarget:self action:@selector(autoClickToggled:) forControlEvents:UIControlEventValueChanged];
    [self addSubview:self.autoClickSwitch];
    
    // 状态指示
    self.statusIndicator = [[UIView alloc] initWithFrame:CGRectMake(w - 80, y + 6, 16, 16)];
    self.statusIndicator.layer.cornerRadius = 8;
    self.statusIndicator.backgroundColor = [UIColor systemRedColor];
    self.statusIndicator.layer.shadowColor = [UIColor systemRedColor].CGColor;
    self.statusIndicator.layer.shadowOpacity = 0.6;
    self.statusIndicator.layer.shadowRadius = 4;
    [self addSubview:self.statusIndicator];
    
    y += 42;
    
    // ---- 速度控制 ----
    UILabel *speedTitle = [[UILabel alloc] initWithFrame:CGRectMake(indent, y, 80, 28)];
    speedTitle.text = @"点击速度";
    speedTitle.font = [UIFont systemFontOfSize:13];
    speedTitle.textColor = COLOR_SUBTEXT;
    [self addSubview:speedTitle];
    
    self.speedLabel = [[UILabel alloc] initWithFrame:CGRectMake(w - 60, y, 60, 28)];
    self.speedLabel.text = @"10/秒";
    self.speedLabel.font = [UIFont systemFontOfSize:13];
    self.speedLabel.textColor = COLOR_TINT;
    self.speedLabel.textAlignment = NSTextAlignmentRight;
    [self addSubview:self.speedLabel];
    
    y += 28;
    
    self.speedSlider = [[UISlider alloc] initWithFrame:CGRectMake(indent, y, w, 32)];
    self.speedSlider.minimumValue = 1;
    self.speedSlider.maximumValue = 30;
    self.speedSlider.value = 10;
    self.speedSlider.tintColor = COLOR_TINT;
    self.speedSlider.thumbTintColor = COLOR_TINT;
    [self.speedSlider addTarget:self action:@selector(speedChanged:) forControlEvents:UIControlEventValueChanged];
    [self addSubview:self.speedSlider];
    
    y += 40;
    
    // ---- 底部提示 ----
    UILabel *footer = [[UILabel alloc] initWithFrame:CGRectMake(indent, y, w, 20)];
    footer.text = @"点击浮动按钮开始定位点击位置";
    footer.font = [UIFont systemFontOfSize:11];
    footer.textColor = COLOR_SUBTEXT;
    footer.textAlignment = NSTextAlignmentCenter;
    [self addSubview:footer];
    
    y += 24;
    
    // 更新面板高度
    CGRect frame = self.frame;
    frame.size.height = y;
    self.frame = frame;
}

#pragma mark - Actions

- (void)autoClickToggled:(UISwitch *)sender {
    if (sender.isOn) {
        // 在屏幕中心位置开始连点
        CGPoint center = CGPointMake(CGRectGetMidX([UIScreen mainScreen].bounds), CGRectGetMidY([UIScreen mainScreen].bounds));
        NSTimeInterval interval = 1.0 / self.speedSlider.value;
        [[MCEventSimulator sharedInstance] startAutoClickAtPoint:center interval:interval];
        self.statusIndicator.backgroundColor = [UIColor systemGreenColor];
        self.statusIndicator.layer.shadowColor = [UIColor systemGreenColor].CGColor;
    } else {
        [[MCEventSimulator sharedInstance] stopAutoClick];
        self.statusIndicator.backgroundColor = [UIColor systemRedColor];
        self.statusIndicator.layer.shadowColor = [UIColor systemRedColor].CGColor;
    }
}

- (void)speedChanged:(UISlider *)sender {
    NSInteger speed = (NSInteger)round(sender.value);
    self.speedLabel.text = [NSString stringWithFormat:@"%ld/秒", (long)speed];
    
    // 如果正在连点，更新速度
    if (self.autoClickSwitch.isOn) {
        [[MCEventSimulator sharedInstance] stopAutoClick];
        CGPoint center = CGPointMake(CGRectGetMidX([UIScreen mainScreen].bounds), CGRectGetMidY([UIScreen mainScreen].bounds));
        NSTimeInterval interval = 1.0 / speed;
        [[MCEventSimulator sharedInstance] startAutoClickAtPoint:center interval:interval];
    }
}

- (void)closePanel {
    if (self.autoClickSwitch.isOn) {
        [self.autoClickSwitch setOn:NO animated:YES];
        [[MCEventSimulator sharedInstance] stopAutoClick];
        self.statusIndicator.backgroundColor = [UIColor systemRedColor];
        self.statusIndicator.layer.shadowColor = [UIColor systemRedColor].CGColor;
    }
    [UIView animateWithDuration:0.25 animations:^{
        self.alpha = 0;
        self.transform = CGAffineTransformMakeScale(0.8, 0.8);
    } completion:^(BOOL finished) {
        self.hidden = YES;
        [[MCMenuManager sharedInstance] hideMenu];
    }];
}

- (void)refreshUI {
    // 刷新状态
    if ([MCEventSimulator sharedInstance].isAutoClicking) {
        [self.autoClickSwitch setOn:YES animated:NO];
        self.statusIndicator.backgroundColor = [UIColor systemGreenColor];
        self.statusIndicator.layer.shadowColor = [UIColor systemGreenColor].CGColor;
    }
}

@end

// ============================================================
// MCMenuManager - 菜单管理器
// ============================================================
@interface MCMenuManager ()

@property (nonatomic, strong) UIWindow *overlayWindow;
@property (nonatomic, strong) MCFloatingButton *floatingButton;
@property (nonatomic, strong) MCMenuPanel *menuPanel;
@property (nonatomic, assign, readwrite) BOOL visible;
@property (nonatomic, assign) BOOL menuOpen;

@end

@implementation MCMenuManager

+ (instancetype)sharedInstance {
    static MCMenuManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    // 延迟创建窗口：只在 showMenu 时创建，不在 init 时创建
    // 避免在 app 启动过程中访问 UIKit API
    return self;
}

- (void)ensureOverlayWindow {
    if (self.overlayWindow) return;
    
    // 安全检查：确保主屏幕可用
    if (![UIScreen mainScreen]) {
        return;
    }
    
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    
    // 创建覆盖窗口 - 使用极高的窗口层级确保在最上层
    self.overlayWindow = [[UIWindow alloc] initWithFrame:screenBounds];
    self.overlayWindow.windowLevel = 2000000.0;
    self.overlayWindow.backgroundColor = [UIColor clearColor];
    self.overlayWindow.userInteractionEnabled = YES;
    
    // 根视图控制器
    UIViewController *rootVC = [[UIViewController alloc] init];
    rootVC.view.backgroundColor = [UIColor clearColor];
    rootVC.view.userInteractionEnabled = NO;
    self.overlayWindow.rootViewController = rootVC;
    
    // 浮动按钮
    CGFloat btnSize = 50;
    self.floatingButton = [[MCFloatingButton alloc] initWithFrame:CGRectMake(16, 200, btnSize, btnSize)];
    [self.floatingButton addTarget:self action:@selector(floatingButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.overlayWindow addSubview:self.floatingButton];
    
    // 菜单面板 (初始隐藏)
    CGFloat panelWidth = 260;
    CGFloat panelX = (screenBounds.size.width - panelWidth) / 2;
    self.menuPanel = [[MCMenuPanel alloc] initWithFrame:CGRectMake(panelX, 80, panelWidth, 0)];
    self.menuPanel.hidden = YES;
    self.menuPanel.alpha = 0;
    self.menuPanel.transform = CGAffineTransformMakeScale(0.8, 0.8);
    [self.overlayWindow addSubview:self.menuPanel];
}

- (void)floatingButtonTapped {
    // 安全检查
    if (!self.floatingButton || !self.menuPanel) return;
    if (self.floatingButton.isDragging) return;
    
    self.menuOpen = !self.menuOpen;
    
    if (self.menuOpen) {
        [self.menuPanel refreshUI];
        self.menuPanel.hidden = NO;
        [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.menuPanel.alpha = 1;
            self.menuPanel.transform = CGAffineTransformIdentity;
        } completion:nil];
    } else {
        [UIView animateWithDuration:0.25 animations:^{
            self.menuPanel.alpha = 0;
            self.menuPanel.transform = CGAffineTransformMakeScale(0.8, 0.8);
        } completion:^(BOOL finished) {
            self.menuPanel.hidden = YES;
        }];
    }
}

- (void)showMenu {
    if (self.visible) return;
    
    // 确保窗口已创建（延迟创建）
    [self ensureOverlayWindow];
    
    // 如果窗口创建失败，不继续
    if (!self.overlayWindow) return;
    
    self.visible = YES;
    self.overlayWindow.hidden = NO;
    
    // 将浮动按钮置于顶层
    [self.overlayWindow bringSubviewToFront:self.floatingButton];
    [self.overlayWindow bringSubviewToFront:self.menuPanel];
    
    // 动画出现
    self.floatingButton.transform = CGAffineTransformMakeScale(0.1, 0.1);
    [UIView animateWithDuration:0.5 delay:0.5 usingSpringWithDamping:0.6 initialSpringVelocity:0.8 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.floatingButton.transform = CGAffineTransformIdentity;
    } completion:nil];
}

- (void)hideMenu {
    self.visible = NO;
    self.menuOpen = NO;
    self.menuPanel.hidden = YES;
    self.overlayWindow.hidden = YES;
}

@end