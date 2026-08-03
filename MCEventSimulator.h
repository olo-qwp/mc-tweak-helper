#import <CoreGraphics/CoreGraphics.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 触摸事件模拟器
/// 使用 GSEvent 私有 API 模拟触摸事件
@interface MCEventSimulator : NSObject

/// 单例
+ (instancetype)sharedInstance;

/// 模拟在指定位置的触摸按下
/// @param point 屏幕坐标点
- (void)simulateTouchDownAtPoint:(CGPoint)point;

/// 模拟在指定位置的触摸抬起
/// @param point 屏幕坐标点
- (void)simulateTouchUpAtPoint:(CGPoint)point;

/// 模拟一次完整的点击（按下+抬起）
/// @param point 屏幕坐标点
- (void)simulateTapAtPoint:(CGPoint)point;

/// 开始连点 - 在指定位置以固定间隔重复点击
/// @param point 点击位置
/// @param interval 点击间隔（秒）
- (void)startAutoClickAtPoint:(CGPoint)point interval:(NSTimeInterval)interval;

/// 停止连点
- (void)stopAutoClick;

/// 是否正在连点
@property (nonatomic, readonly, getter=isAutoClicking) BOOL autoClicking;

/// 当前连点位置
@property (nonatomic, readonly) CGPoint autoClickPoint;

/// 当前连点间隔
@property (nonatomic, readonly) NSTimeInterval autoClickInterval;

@end

NS_ASSUME_NONNULL_END