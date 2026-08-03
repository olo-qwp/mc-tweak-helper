#import "MCEventSimulator.h"
#import <dlfcn.h>
#import <mach/mach.h>

// GSEvent 类型定义
typedef enum {
    kGSEventTouchBegan = 0x0B,
    kGSEventTouchEnded = 0x0C,
    kGSEventTouchMoved = 0x0D,
    kGSEventTap = 0x0E,
} MCEventType;

// GSEvent 结构体头部
typedef struct {
    uint8_t  type;         // 事件类型
    uint8_t  tapCount;     // 点击次数
    uint8_t  phase;        // 触摸阶段
    uint8_t  fingerCount;  // 手指数量
    float    locationX;    // X 坐标
    float    locationY;    // Y 坐标
    float    windowX;      // 窗口 X
    float    windowY;      // 窗口 Y
    uint64_t timestamp;    // 时间戳
    uint64_t _pad[6];
} MCEventRecord;

// GSEvent 函数指针
typedef void (*GSEventSendType)(void *event);
typedef void *(*GSEventCreateWithTypeAndLocationType)(int type, CGPoint location);

@interface MCEventSimulator ()

@property (nonatomic, assign, readwrite) BOOL autoClicking;
@property (nonatomic, assign, readwrite) CGPoint autoClickPoint;
@property (nonatomic, assign, readwrite) NSTimeInterval autoClickInterval;

@property (nonatomic, strong) NSTimer *autoClickTimer;
@property (nonatomic, assign) void *gsEventHandle;

// GSEvent 函数
@property (nonatomic, assign) GSEventSendType GSEventSend;
@property (nonatomic, assign) GSEventCreateWithTypeAndLocationType GSEventCreateWithTypeAndLocation;

@end

@implementation MCEventSimulator

+ (instancetype)sharedInstance {
    static MCEventSimulator *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self loadGSEventFunctions];
    }
    return self;
}

- (void)loadGSEventFunctions {
    void *handle = dlopen("/System/Library/PrivateFrameworks/GraphicsServices.framework/GraphicsServices", RTLD_LAZY);
    if (handle) {
        self.GSEventSend = (GSEventSendType)dlsym(handle, "GSEventSend");
        self.GSEventCreateWithTypeAndLocation = (GSEventCreateWithTypeAndLocationType)dlsym(handle, "GSEventCreateWithTypeAndLocation");
        self.gsEventHandle = handle;
    }
}

- (void)dealloc {
    if (self.gsEventHandle) {
        dlclose(self.gsEventHandle);
    }
}

#pragma mark - 单次触摸

- (void)simulateTouchDownAtPoint:(CGPoint)point {
    if (!self.GSEventCreateWithTypeAndLocation || !self.GSEventSend) return;
    void *event = self.GSEventCreateWithTypeAndLocation(kGSEventTouchBegan, point);
    if (event) {
        self.GSEventSend(event);
        free(event);
    }
}

- (void)simulateTouchUpAtPoint:(CGPoint)point {
    if (!self.GSEventCreateWithTypeAndLocation || !self.GSEventSend) return;
    void *event = self.GSEventCreateWithTypeAndLocation(kGSEventTouchEnded, point);
    if (event) {
        self.GSEventSend(event);
        free(event);
    }
}

- (void)simulateTapAtPoint:(CGPoint)point {
    if (!self.GSEventCreateWithTypeAndLocation || !self.GSEventSend) return;
    // 按下并立即抬起
    [self simulateTouchDownAtPoint:point];
    usleep(50000); // 50ms 延迟
    [self simulateTouchUpAtPoint:point];
}

#pragma mark - 连点器

- (void)startAutoClickAtPoint:(CGPoint)point interval:(NSTimeInterval)interval {
    [self stopAutoClick];
    
    self.autoClicking = YES;
    self.autoClickPoint = point;
    self.autoClickInterval = interval;
    
    // 使用定时器循环点击
    self.autoClickTimer = [NSTimer scheduledTimerWithTimeInterval:interval
                                                           target:self
                                                         selector:@selector(autoClickTick)
                                                         userInfo:nil
                                                          repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.autoClickTimer forMode:NSRunLoopCommonModes];
}

- (void)stopAutoClick {
    self.autoClicking = NO;
    [self.autoClickTimer invalidate];
    self.autoClickTimer = nil;
}

- (void)autoClickTick {
    if (!self.autoClicking) return;
    
    // 在连点位置执行点击
    [self simulateTapAtPoint:self.autoClickPoint];
}

@end