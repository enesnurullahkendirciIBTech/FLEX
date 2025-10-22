//
//  FLEXManager+Extensibility.m
//  FLEX
//
//  Created by Tanner on 2/2/20.
//  Copyright © 2020 FLEX Team. All rights reserved.
//

#import "FLEXManager+Extensibility.h"
#import "FLEXManager+Private.h"
#import "FLEXNavigationController.h"
#import "FLEXObjectExplorerFactory.h"
#import "FLEXKeyboardShortcutManager.h"
#import "FLEXExplorerViewController.h"
#import "FLEXNetworkMITMViewController.h"
#import "FLEXKeyboardHelpViewController.h"
#import "FLEXFileBrowserController.h"
#import "FLEXArgumentInputStructView.h"
#import "FLEXExplorerToolbarItem.h"
#import "FLEXUtility.h"
#import <objc/runtime.h>

@interface FLEXManager (ExtensibilityPrivate)
@property (nonatomic, readonly) UIViewController *topViewController;
@end

// Private storage for custom toolbar actions
@interface FLEXToolbarActionStorage : NSObject
@property (nonatomic, weak) id target;
@property (nonatomic) SEL action;
@end

@implementation FLEXToolbarActionStorage
@end

// Private storage for toolbar item customization
@interface FLEXToolbarItemCustomization : NSObject
@property (nonatomic, copy) NSString *title;
@property (nonatomic, strong) UIImage *image;
@end

@implementation FLEXToolbarItemCustomization
@end

@implementation FLEXManager (Extensibility)

// Associated object keys for storing custom actions
static char kGlobalsActionKey;
static char kHierarchyActionKey;
static char kSelectActionKey;
static char kRecentActionKey;
static char kMoveActionKey;
static char kCloseActionKey;

// Associated object keys for storing customizations
static char kGlobalsCustomizationKey;
static char kHierarchyCustomizationKey;
static char kSelectCustomizationKey;
static char kRecentCustomizationKey;
static char kMoveCustomizationKey;
static char kCloseCustomizationKey;

#pragma mark - Custom Action Storage

- (void)setCustomActionForKey:(const void *)key target:(id)target action:(SEL)action {
    if (target && action) {
        FLEXToolbarActionStorage *storage = [FLEXToolbarActionStorage new];
        storage.target = target;
        storage.action = action;
        objc_setAssociatedObject(self, key, storage, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    } else {
        objc_setAssociatedObject(self, key, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

- (FLEXToolbarActionStorage *)customActionForKey:(const void *)key {
    return objc_getAssociatedObject(self, key);
}

- (void)setCustomizationForKey:(const void *)key title:(NSString *)title image:(UIImage *)image {
    FLEXToolbarItemCustomization *customization = objc_getAssociatedObject(self, key);
    if (!customization) {
        customization = [FLEXToolbarItemCustomization new];
        objc_setAssociatedObject(self, key, customization, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    if (title) {
        customization.title = title;
    }
    if (image) {
        customization.image = image;
    }
}

- (FLEXToolbarItemCustomization *)customizationForKey:(const void *)key {
    return objc_getAssociatedObject(self, key);
}

#pragma mark - Apply Customizations & Actions (Called from FLEXExplorerViewController)

+ (void)applyCustomActionsToToolbar:(FLEXExplorerToolbar *)toolbar {
    FLEXManager *manager = self.sharedManager;
    
    // Apply customizations (title/image) first
    FLEXToolbarItemCustomization *globalsCustomization = [manager customizationForKey:&kGlobalsCustomizationKey];
    if (globalsCustomization) {
        if (globalsCustomization.title) {
            [toolbar.globalsItem setItemTitle:globalsCustomization.title];
        }
        if (globalsCustomization.image) {
            [toolbar.globalsItem setItemImage:globalsCustomization.image];
        }
    }
    
    FLEXToolbarItemCustomization *hierarchyCustomization = [manager customizationForKey:&kHierarchyCustomizationKey];
    if (hierarchyCustomization) {
        if (hierarchyCustomization.title) {
            [toolbar.hierarchyItem setItemTitle:hierarchyCustomization.title];
        }
        if (hierarchyCustomization.image) {
            [toolbar.hierarchyItem setItemImage:hierarchyCustomization.image];
        }
    }
    
    FLEXToolbarItemCustomization *selectCustomization = [manager customizationForKey:&kSelectCustomizationKey];
    if (selectCustomization) {
        if (selectCustomization.title) {
            [toolbar.selectItem setItemTitle:selectCustomization.title];
        }
        if (selectCustomization.image) {
            [toolbar.selectItem setItemImage:selectCustomization.image];
        }
    }
    
    FLEXToolbarItemCustomization *recentCustomization = [manager customizationForKey:&kRecentCustomizationKey];
    if (recentCustomization) {
        if (recentCustomization.title) {
            [toolbar.recentItem setItemTitle:recentCustomization.title];
        }
        if (recentCustomization.image) {
            [toolbar.recentItem setItemImage:recentCustomization.image];
        }
    }
    
    FLEXToolbarItemCustomization *moveCustomization = [manager customizationForKey:&kMoveCustomizationKey];
    if (moveCustomization) {
        if (moveCustomization.title) {
            [toolbar.moveItem setItemTitle:moveCustomization.title];
        }
        if (moveCustomization.image) {
            [toolbar.moveItem setItemImage:moveCustomization.image];
        }
    }
    
    FLEXToolbarItemCustomization *closeCustomization = [manager customizationForKey:&kCloseCustomizationKey];
    if (closeCustomization) {
        if (closeCustomization.title) {
            [toolbar.closeItem setItemTitle:closeCustomization.title];
        }
        if (closeCustomization.image) {
            [toolbar.closeItem setItemImage:closeCustomization.image];
        }
    }
    
    // Apply custom actions
    FLEXToolbarActionStorage *globalsAction = [manager customActionForKey:&kGlobalsActionKey];
    if (globalsAction && globalsAction.target) {
        [toolbar.globalsItem removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
        [toolbar.globalsItem addTarget:globalsAction.target action:globalsAction.action forControlEvents:UIControlEventTouchUpInside];
    }
    
    FLEXToolbarActionStorage *hierarchyAction = [manager customActionForKey:&kHierarchyActionKey];
    if (hierarchyAction && hierarchyAction.target) {
        [toolbar.hierarchyItem removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
        [toolbar.hierarchyItem addTarget:hierarchyAction.target action:hierarchyAction.action forControlEvents:UIControlEventTouchUpInside];
    }
    
    FLEXToolbarActionStorage *selectAction = [manager customActionForKey:&kSelectActionKey];
    if (selectAction && selectAction.target) {
        [toolbar.selectItem removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
        [toolbar.selectItem addTarget:selectAction.target action:selectAction.action forControlEvents:UIControlEventTouchUpInside];
    }
    
    FLEXToolbarActionStorage *recentAction = [manager customActionForKey:&kRecentActionKey];
    if (recentAction && recentAction.target) {
        [toolbar.recentItem removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
        [toolbar.recentItem addTarget:recentAction.target action:recentAction.action forControlEvents:UIControlEventTouchUpInside];
    }
    
    FLEXToolbarActionStorage *moveAction = [manager customActionForKey:&kMoveActionKey];
    if (moveAction && moveAction.target) {
        [toolbar.moveItem removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
        [toolbar.moveItem addTarget:moveAction.target action:moveAction.action forControlEvents:UIControlEventTouchUpInside];
    }
    
    FLEXToolbarActionStorage *closeAction = [manager customActionForKey:&kCloseActionKey];
    if (closeAction && closeAction.target) {
        [toolbar.closeItem removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
        [toolbar.closeItem addTarget:closeAction.target action:closeAction.action forControlEvents:UIControlEventTouchUpInside];
    }
}

#pragma mark - Globals Screen Entries

- (void)registerGlobalEntryWithName:(NSString *)entryName objectFutureBlock:(id (^)(void))objectFutureBlock {
    NSParameterAssert(entryName);
    NSParameterAssert(objectFutureBlock);
    NSAssert(NSThread.isMainThread, @"This method must be called from the main thread.");

    entryName = entryName.copy;
    FLEXGlobalsEntry *entry = [FLEXGlobalsEntry entryWithNameFuture:^NSString *{
        return entryName;
    } viewControllerFuture:^UIViewController *{
        return [FLEXObjectExplorerFactory explorerViewControllerForObject:objectFutureBlock()];
    }];

    [self.userGlobalEntries addObject:entry];
}

- (void)registerGlobalEntryWithName:(NSString *)entryName viewControllerFutureBlock:(UIViewController * (^)(void))viewControllerFutureBlock {
    NSParameterAssert(entryName);
    NSParameterAssert(viewControllerFutureBlock);
    NSAssert(NSThread.isMainThread, @"This method must be called from the main thread.");

    entryName = entryName.copy;
    FLEXGlobalsEntry *entry = [FLEXGlobalsEntry entryWithNameFuture:^NSString *{
        return entryName;
    } viewControllerFuture:^UIViewController *{
        UIViewController *viewController = viewControllerFutureBlock();
        NSCAssert(viewController, @"'%@' entry returned nil viewController. viewControllerFutureBlock should never return nil.", entryName);
        return viewController;
    }];

    [self.userGlobalEntries addObject:entry];
}

- (void)registerGlobalEntryWithName:(NSString *)entryName action:(FLEXGlobalsEntryRowAction)rowSelectedAction {
    NSParameterAssert(entryName);
    NSParameterAssert(rowSelectedAction);
    NSAssert(NSThread.isMainThread, @"This method must be called from the main thread.");
    
    entryName = entryName.copy;
    FLEXGlobalsEntry *entry = [FLEXGlobalsEntry entryWithNameFuture:^NSString * _Nonnull{
        return entryName;
    } action:rowSelectedAction];
    
    [self.userGlobalEntries addObject:entry];
}

- (void)clearGlobalEntries {
    [self.userGlobalEntries removeAllObjects];
}


#pragma mark - Toolbar Customization

- (void)customizeGlobalsItemWithTitle:(NSString *)title image:(nullable UIImage *)image {
    NSParameterAssert(title);
    [self setCustomizationForKey:&kGlobalsCustomizationKey title:title image:image];
    
    // If toolbar is already initialized, reapply all customizations
    if (self.toolbar) {
        [FLEXManager applyCustomActionsToToolbar:self.toolbar];
    }
}

- (void)customizeHierarchyItemWithTitle:(NSString *)title image:(nullable UIImage *)image {
    NSParameterAssert(title);
    [self setCustomizationForKey:&kHierarchyCustomizationKey title:title image:image];
    
    // If toolbar is already initialized, reapply all customizations
    if (self.toolbar) {
        [FLEXManager applyCustomActionsToToolbar:self.toolbar];
    }
}

- (void)customizeSelectItemWithTitle:(NSString *)title image:(nullable UIImage *)image {
    NSParameterAssert(title);
    [self setCustomizationForKey:&kSelectCustomizationKey title:title image:image];
    
    // If toolbar is already initialized, reapply all customizations
    if (self.toolbar) {
        [FLEXManager applyCustomActionsToToolbar:self.toolbar];
    }
}

- (void)customizeRecentItemWithTitle:(NSString *)title image:(nullable UIImage *)image {
    NSParameterAssert(title);
    [self setCustomizationForKey:&kRecentCustomizationKey title:title image:image];
    
    // If toolbar is already initialized, reapply all customizations
    if (self.toolbar) {
        [FLEXManager applyCustomActionsToToolbar:self.toolbar];
    }
}

- (void)customizeMoveItemWithTitle:(NSString *)title image:(nullable UIImage *)image {
    NSParameterAssert(title);
    [self setCustomizationForKey:&kMoveCustomizationKey title:title image:image];
    
    // If toolbar is already initialized, reapply all customizations
    if (self.toolbar) {
        [FLEXManager applyCustomActionsToToolbar:self.toolbar];
    }
}

- (void)customizeCloseItemWithTitle:(NSString *)title image:(nullable UIImage *)image {
    NSParameterAssert(title);
    [self setCustomizationForKey:&kCloseCustomizationKey title:title image:image];
    
    // If toolbar is already initialized, reapply all customizations
    if (self.toolbar) {
        [FLEXManager applyCustomActionsToToolbar:self.toolbar];
    }
}

- (void)setGlobalsItemTarget:(nullable id)target action:(nullable SEL)action {
    [self setCustomActionForKey:&kGlobalsActionKey target:target action:action];
    NSLog(@"🔍 [FLEXManager] Stored globals action - target: %@, action: %@", target, NSStringFromSelector(action));
    
    // If toolbar is already initialized, reapply all custom actions
    if (self.toolbar) {
        NSLog(@"🔍 [FLEXManager] Toolbar exists, reapplying custom actions");
        [FLEXManager applyCustomActionsToToolbar:self.toolbar];
    }
}

- (void)setHierarchyItemTarget:(nullable id)target action:(nullable SEL)action {
    [self setCustomActionForKey:&kHierarchyActionKey target:target action:action];
    NSLog(@"🔍 [FLEXManager] Stored hierarchy action - target: %@, action: %@", target, NSStringFromSelector(action));
    
    // If toolbar is already initialized, reapply all custom actions
    if (self.toolbar) {
        NSLog(@"🔍 [FLEXManager] Toolbar exists, reapplying custom actions");
        [FLEXManager applyCustomActionsToToolbar:self.toolbar];
    }
}

- (void)setSelectItemTarget:(nullable id)target action:(nullable SEL)action {
    [self setCustomActionForKey:&kSelectActionKey target:target action:action];
    NSLog(@"🔍 [FLEXManager] Stored select action - target: %@, action: %@, responds: %d", 
          target, NSStringFromSelector(action), [target respondsToSelector:action]);
    
    // If toolbar is already initialized, reapply all custom actions
    if (self.toolbar) {
        NSLog(@"🔍 [FLEXManager] Toolbar exists, reapplying custom actions");
        [FLEXManager applyCustomActionsToToolbar:self.toolbar];
    }
}

- (void)setRecentItemTarget:(nullable id)target action:(nullable SEL)action {
    [self setCustomActionForKey:&kRecentActionKey target:target action:action];
    NSLog(@"🔍 [FLEXManager] Stored recent action - target: %@, action: %@", target, NSStringFromSelector(action));
    
    // If toolbar is already initialized, reapply all custom actions
    if (self.toolbar) {
        NSLog(@"🔍 [FLEXManager] Toolbar exists, reapplying custom actions");
        [FLEXManager applyCustomActionsToToolbar:self.toolbar];
    }
}

- (void)setMoveItemTarget:(nullable id)target action:(nullable SEL)action {
    [self setCustomActionForKey:&kMoveActionKey target:target action:action];
    NSLog(@"🔍 [FLEXManager] Stored move action - target: %@, action: %@", target, NSStringFromSelector(action));
    
    // If toolbar is already initialized, reapply all custom actions
    if (self.toolbar) {
        NSLog(@"🔍 [FLEXManager] Toolbar exists, reapplying custom actions");
        [FLEXManager applyCustomActionsToToolbar:self.toolbar];
    }
}

- (void)setCloseItemTarget:(nullable id)target action:(nullable SEL)action {
    [self setCustomActionForKey:&kCloseActionKey target:target action:action];
    NSLog(@"🔍 [FLEXManager] Stored close action - target: %@, action: %@", target, NSStringFromSelector(action));
    
    // If toolbar is already initialized, reapply all custom actions
    if (self.toolbar) {
        NSLog(@"🔍 [FLEXManager] Toolbar exists, reapplying custom actions");
        [FLEXManager applyCustomActionsToToolbar:self.toolbar];
    }
}


#pragma mark - Editing

+ (void)registerFieldNames:(NSArray<NSString *> *)names forTypeEncoding:(NSString *)typeEncoding {
    [FLEXArgumentInputStructView registerFieldNames:names forTypeEncoding:typeEncoding];
}


#pragma mark - Simulator Shortcuts

- (void)registerSimulatorShortcutWithKey:(NSString *)key modifiers:(UIKeyModifierFlags)modifiers action:(dispatch_block_t)action description:(NSString *)description {
#if TARGET_OS_SIMULATOR
    [FLEXKeyboardShortcutManager.sharedManager registerSimulatorShortcutWithKey:key modifiers:modifiers action:action description:description allowOverride:YES];
#endif
}

- (void)setSimulatorShortcutsEnabled:(BOOL)simulatorShortcutsEnabled {
#if TARGET_OS_SIMULATOR
    [FLEXKeyboardShortcutManager.sharedManager setEnabled:simulatorShortcutsEnabled];
#endif
}

- (BOOL)simulatorShortcutsEnabled {
#if TARGET_OS_SIMULATOR
    return FLEXKeyboardShortcutManager.sharedManager.isEnabled;
#else
    return NO;
#endif
}


#pragma mark - Shortcuts Defaults

- (void)registerDefaultSimulatorShortcutWithKey:(NSString *)key modifiers:(UIKeyModifierFlags)modifiers action:(dispatch_block_t)action description:(NSString *)description {
#if TARGET_OS_SIMULATOR
    // Don't allow override to avoid changing keys registered by the app
    [FLEXKeyboardShortcutManager.sharedManager registerSimulatorShortcutWithKey:key modifiers:modifiers action:action description:description allowOverride:NO];
#endif
}

- (void)registerDefaultSimulatorShortcuts {
    [self registerDefaultSimulatorShortcutWithKey:@"f" modifiers:0 action:^{
        [self toggleExplorer];
    } description:@"Toggle FLEX toolbar"];

    [self registerDefaultSimulatorShortcutWithKey:@"g" modifiers:0 action:^{
        [self showExplorerIfNeeded];
        [self.explorerViewController toggleMenuTool];
    } description:@"Toggle FLEX globals menu"];

    [self registerDefaultSimulatorShortcutWithKey:@"v" modifiers:0 action:^{
        [self showExplorerIfNeeded];
        [self.explorerViewController toggleViewsTool];
    } description:@"Toggle view hierarchy menu"];

    [self registerDefaultSimulatorShortcutWithKey:@"s" modifiers:0 action:^{
        [self showExplorerIfNeeded];
        [self.explorerViewController toggleSelectTool];
    } description:@"Toggle select tool"];

    [self registerDefaultSimulatorShortcutWithKey:@"m" modifiers:0 action:^{
        [self showExplorerIfNeeded];
        [self.explorerViewController toggleMoveTool];
    } description:@"Toggle move tool"];

    [self registerDefaultSimulatorShortcutWithKey:@"n" modifiers:0 action:^{
        [self toggleTopViewControllerOfClass:[FLEXNetworkMITMViewController class]];
    } description:@"Toggle network history view"];

    [self registerDefaultSimulatorShortcutWithKey:UIKeyInputDownArrow modifiers:0 action:^{
        if (self.isHidden || ![self.explorerViewController handleDownArrowKeyPressed]) {
            [self tryScrollDown];
        }
    } description:@"Cycle view selection\n\t\tMove view down\n\t\tScroll down"];

    [self registerDefaultSimulatorShortcutWithKey:UIKeyInputUpArrow modifiers:0 action:^{
        if (self.isHidden || ![self.explorerViewController handleUpArrowKeyPressed]) {
            [self tryScrollUp];
        }
    } description:@"Cycle view selection\n\t\tMove view up\n\t\tScroll up"];

    [self registerDefaultSimulatorShortcutWithKey:UIKeyInputRightArrow modifiers:0 action:^{
        if (!self.isHidden) {
            [self.explorerViewController handleRightArrowKeyPressed];
        }
    } description:@"Move selected view right"];

    [self registerDefaultSimulatorShortcutWithKey:UIKeyInputLeftArrow modifiers:0 action:^{
        if (self.isHidden) {
            [self tryGoBack];
        } else {
            [self.explorerViewController handleLeftArrowKeyPressed];
        }
    } description:@"Move selected view left"];

    [self registerDefaultSimulatorShortcutWithKey:@"?" modifiers:0 action:^{
        [self toggleTopViewControllerOfClass:[FLEXKeyboardHelpViewController class]];
    } description:@"Toggle (this) help menu"];

    [self registerDefaultSimulatorShortcutWithKey:UIKeyInputEscape modifiers:0 action:^{
        [[self.topViewController presentingViewController] dismissViewControllerAnimated:YES completion:nil];
    } description:@"End editing text\n\t\tDismiss top view controller"];

    [self registerDefaultSimulatorShortcutWithKey:@"o" modifiers:UIKeyModifierCommand|UIKeyModifierShift action:^{
        [self toggleTopViewControllerOfClass:[FLEXFileBrowserController class]];
    } description:@"Toggle file browser menu"];
}

+ (void)load {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.sharedManager registerDefaultSimulatorShortcuts];
    });
}


#pragma mark - Private

- (UIEdgeInsets)contentInsetsOfScrollView:(UIScrollView *)scrollView {
    if (@available(iOS 11, *)) {
        return scrollView.adjustedContentInset;
    }

    return scrollView.contentInset;
}

- (void)tryScrollDown {
    UIScrollView *scrollview = [self firstScrollView];
    UIEdgeInsets insets = [self contentInsetsOfScrollView:scrollview];
    CGPoint contentOffset = scrollview.contentOffset;
    CGFloat maxYOffset = scrollview.contentSize.height - scrollview.bounds.size.height + insets.bottom;
    contentOffset.y = MIN(contentOffset.y + 200, maxYOffset);
    [scrollview setContentOffset:contentOffset animated:YES];
}

- (void)tryScrollUp {
    UIScrollView *scrollview = [self firstScrollView];
    UIEdgeInsets insets = [self contentInsetsOfScrollView:scrollview];
    CGPoint contentOffset = scrollview.contentOffset;
    contentOffset.y = MAX(contentOffset.y - 200, -insets.top);
    [scrollview setContentOffset:contentOffset animated:YES];
}

- (UIScrollView *)firstScrollView {
    NSMutableArray<UIView *> *views = FLEXUtility.appKeyWindow.subviews.mutableCopy;
    UIScrollView *scrollView = nil;
    while (views.count > 0) {
        UIView *view = views.firstObject;
        [views removeObjectAtIndex:0];
        if ([view isKindOfClass:[UIScrollView class]]) {
            scrollView = (UIScrollView *)view;
            break;
        } else {
            [views addObjectsFromArray:view.subviews];
        }
    }
    return scrollView;
}

- (void)tryGoBack {
    UINavigationController *navigationController = nil;
    UIViewController *topViewController = self.topViewController;
    if ([topViewController isKindOfClass:[UINavigationController class]]) {
        navigationController = (UINavigationController *)topViewController;
    } else {
        navigationController = topViewController.navigationController;
    }
    [navigationController popViewControllerAnimated:YES];
}

- (UIViewController *)topViewController {
    return [FLEXUtility topViewControllerInWindow:UIApplication.sharedApplication.keyWindow];
}

- (void)toggleTopViewControllerOfClass:(Class)class {
    UINavigationController *topViewController = (id)self.topViewController;
    if ([topViewController isKindOfClass:[FLEXNavigationController class]]) {
        if ([topViewController.topViewController isKindOfClass:[class class]]) {
            if (topViewController.viewControllers.count == 1) {
                // Dismiss since we are already presenting it
                [topViewController.presentingViewController dismissViewControllerAnimated:YES completion:nil];
            } else {
                // Pop since we are viewing it but it's not the only thing on the stack
                [topViewController popViewControllerAnimated:YES];
            }
        } else {
            // Push it on the existing navigation stack
            [topViewController pushViewController:[class new] animated:YES];
        }
    } else {
        // Present it in an entirely new navigation controller
        [self.explorerViewController presentViewController:
            [FLEXNavigationController withRootViewController:[class new]]
        animated:YES completion:nil];
    }
}

- (void)showExplorerIfNeeded {
    if (self.isHidden) {
        [self showExplorer];
    }
}

@end
