#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 浮动菜单管理器
/// 在游戏画面上层显示可拖动的浮动按钮和功能菜单
@interface MCMenuManager : NSObject

/// 单例
+ (instancetype)sharedInstance;

/// 显示菜单
- (void)showMenu;

/// 隐藏菜单
- (void)hideMenu;

/// 是否正在显示
@property (nonatomic, readonly, getter=isVisible) BOOL visible;

@end

/// 浮动菜单视图
@interface MCFloatingButton : UIButton

/// 是否正在拖拽
@property (nonatomic, readonly, getter=isDragging) BOOL dragging;

@end

/// 功能面板视图
@interface MCMenuPanel : UIView

/// 刷新 UI 状态
- (void)refreshUI;

@end

NS_ASSUME_NONNULL_END