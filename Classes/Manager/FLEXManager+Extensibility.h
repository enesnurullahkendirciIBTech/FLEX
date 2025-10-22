//
//  FLEXManager+Extensibility.h
//  FLEX
//
//  Created by Tanner on 2/2/20.
//  Copyright © 2020 FLEX Team. All rights reserved.
//

#import "FLEXManager.h"
#import "FLEXGlobalsEntry.h"

@class FLEXExplorerToolbar;

NS_ASSUME_NONNULL_BEGIN

@interface FLEXManager (Extensibility)

#pragma mark - Internal (Do not call directly)

/// Internal method to apply custom toolbar actions. Called automatically from FLEXExplorerViewController.
/// @note Do not call this method directly. It is only for internal use.
+ (void)applyCustomActionsToToolbar:(FLEXExplorerToolbar *)toolbar;

#pragma mark - Globals Screen Entries

/// Adds an entry at the top of the list of Global State items.
/// Call this method before this view controller is displayed.
/// @param entryName The string to be displayed in the cell.
/// @param objectFutureBlock When you tap on the row, information about the object returned
/// by this block will be displayed. Passing a block that returns an object allows you to display
/// information about an object whose actual pointer may change at runtime (e.g. +currentUser)
/// @note This method must be called from the main thread.
/// The objectFutureBlock will be invoked from the main thread and may return nil.
/// @note The passed block will be copied and retain for the duration of the application,
/// you may want to use __weak references.
- (void)registerGlobalEntryWithName:(NSString *)entryName objectFutureBlock:(id (^)(void))objectFutureBlock;

/// Adds an entry at the top of the list of Global State items.
/// Call this method before this view controller is displayed.
/// @param entryName The string to be displayed in the cell.
/// @param viewControllerFutureBlock When you tap on the row, view controller returned
/// by this block will be pushed on the navigation controller stack.
/// @note This method must be called from the main thread.
/// The viewControllerFutureBlock will be invoked from the main thread and may not return nil.
/// @note The passed block will be copied and retain for the duration of the application,
/// you may want to use __weak references as needed.
- (void)registerGlobalEntryWithName:(NSString *)entryName
          viewControllerFutureBlock:(UIViewController * (^)(void))viewControllerFutureBlock;

/// Adds an entry at the top of the list of Global State items.
/// @param entryName The string to be displayed in the cell.
/// @param rowSelectedAction When you tap on the row, this block will be invoked
/// with the host table view view controller. Use it to deselect the row or present an alert.
/// @note This method must be called from the main thread.
/// The rowSelectedAction will be invoked from the main thread.
/// @note The passed block will be copied and retain for the duration of the application,
/// you may want to use __weak references as needed.
- (void)registerGlobalEntryWithName:(NSString *)entryName action:(FLEXGlobalsEntryRowAction)rowSelectedAction;

/// Removes all registered global entries.
- (void)clearGlobalEntries;

#pragma mark - Toolbar Customization

/// Customize the title and image of the globals toolbar item.
/// @param title The new title for the button (e.g., @"menu", @"settings")
/// @param image The new image for the button. Can be nil to keep the current image.
- (void)customizeGlobalsItemWithTitle:(NSString *)title image:(nullable UIImage *)image;

/// Customize the title and image of the hierarchy toolbar item.
/// @param title The new title for the button (e.g., @"views", @"hierarchy")
/// @param image The new image for the button. Can be nil to keep the current image.
- (void)customizeHierarchyItemWithTitle:(NSString *)title image:(nullable UIImage *)image;

/// Customize the title and image of the select toolbar item.
/// @param title The new title for the button (e.g., @"select", @"pick")
/// @param image The new image for the button. Can be nil to keep the current image.
- (void)customizeSelectItemWithTitle:(NSString *)title image:(nullable UIImage *)image;

/// Customize the title and image of the recent (network) toolbar item.
/// @param title The new title for the button (e.g., @"network", @"requests")
/// @param image The new image for the button. Can be nil to keep the current image.
- (void)customizeRecentItemWithTitle:(NSString *)title image:(nullable UIImage *)image;

/// Customize the title and image of the move toolbar item.
/// @param title The new title for the button (e.g., @"move", @"drag")
/// @param image The new image for the button. Can be nil to keep the current image.
- (void)customizeMoveItemWithTitle:(NSString *)title image:(nullable UIImage *)image;

/// Customize the title and image of the close toolbar item.
/// @param title The new title for the button (e.g., @"close", @"exit")
/// @param image The new image for the button. Can be nil to keep the current image.
- (void)customizeCloseItemWithTitle:(NSString *)title image:(nullable UIImage *)image;

/// Set a custom action for the globals toolbar item.
/// @param target The target object for the action. Can be nil to remove the action.
/// @param action The selector to call when the button is tapped. Can be NULL to remove the action.
- (void)setGlobalsItemTarget:(nullable id)target action:(nullable SEL)action;

/// Set a custom action for the hierarchy toolbar item.
/// @param target The target object for the action. Can be nil to remove the action.
/// @param action The selector to call when the button is tapped. Can be NULL to remove the action.
- (void)setHierarchyItemTarget:(nullable id)target action:(nullable SEL)action;

/// Set a custom action for the select toolbar item.
/// @param target The target object for the action. Can be nil to remove the action.
/// @param action The selector to call when the button is tapped. Can be NULL to remove the action.
- (void)setSelectItemTarget:(nullable id)target action:(nullable SEL)action;

/// Set a custom action for the recent (network) toolbar item.
/// @param target The target object for the action. Can be nil to remove the action.
/// @param action The selector to call when the button is tapped. Can be NULL to remove the action.
- (void)setRecentItemTarget:(nullable id)target action:(nullable SEL)action;

/// Set a custom action for the move toolbar item.
/// @param target The target object for the action. Can be nil to remove the action.
/// @param action The selector to call when the button is tapped. Can be NULL to remove the action.
- (void)setMoveItemTarget:(nullable id)target action:(nullable SEL)action;

/// Set a custom action for the close toolbar item.
/// @param target The target object for the action. Can be nil to remove the action.
/// @param action The selector to call when the button is tapped. Can be NULL to remove the action.
- (void)setCloseItemTarget:(nullable id)target action:(nullable SEL)action;

#pragma mark - Editing

/// Enable displaying ivar names for custom struct types
+ (void)registerFieldNames:(NSArray<NSString *> *)names forTypeEncoding:(NSString *)typeEncoding;

#pragma mark - Simulator Shortcuts

/// Simulator keyboard shortcuts are enabled by default.
/// The shortcuts will not fire when there is an active text field, text view, or other responder
/// accepting key input. You can disable keyboard shortcuts if you have existing keyboard shortcuts
/// that conflict with FLEX, or if you like doing things the hard way ;)
/// Keyboard shortcuts are always disabled (and support is #if'd out) in non-simulator builds
@property (nonatomic) BOOL simulatorShortcutsEnabled;

/// Adds an action to run when the specified key & modifier combination is pressed
/// @param key A single character string matching a key on the keyboard
/// @param modifiers Modifier keys such as shift, command, or alt/option
/// @param action The block to run on the main thread when the key & modifier combination is recognized.
/// @param description Shown the the keyboard shortcut help menu, which is accessed via the '?' key.
/// @note The action block will be retained for the duration of the application. You may want to use weak references.
/// @note FLEX registers several default keyboard shortcuts. Use the '?' key to see a list of shortcuts.
- (void)registerSimulatorShortcutWithKey:(NSString *)key
                               modifiers:(UIKeyModifierFlags)modifiers
                                  action:(dispatch_block_t)action
                             description:(NSString *)description;

@end

NS_ASSUME_NONNULL_END
