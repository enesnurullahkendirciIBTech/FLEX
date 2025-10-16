//
//  FLEXExplorerToolbar.m
//  Flipboard
//
//  Created by Ryan Olson on 4/4/14.
//  Copyright (c) 2020 FLEX Team. All rights reserved.
//

#import "FLEXColor.h"
#import "FLEXExplorerToolbar.h"
#import "FLEXExplorerToolbarItem.h"
#import "FLEXResources.h"
#import "FLEXUtility.h"

@interface FLEXExplorerToolbar ()

@property (nonatomic, readwrite) FLEXExplorerToolbarItem *globalsItem;
@property (nonatomic, readwrite) FLEXExplorerToolbarItem *hierarchyItem;
@property (nonatomic, readwrite) FLEXExplorerToolbarItem *selectItem;
@property (nonatomic, readwrite) FLEXExplorerToolbarItem *recentItem;
@property (nonatomic, readwrite) FLEXExplorerToolbarItem *moveItem;
@property (nonatomic, readwrite) FLEXExplorerToolbarItem *closeItem;
@property (nonatomic, readwrite) UIView *dragHandle;

@property (nonatomic) UIImageView *dragHandleImageView;

@property (nonatomic) UIView *selectedViewDescriptionContainer;
@property (nonatomic) UIView *selectedViewDescriptionSafeAreaContainer;
@property (nonatomic) UIView *selectedViewColorIndicator;
@property (nonatomic) UILabel *selectedViewDescriptionLabel;

@property (nonatomic,readwrite) UIView *backgroundView;

@end

@implementation FLEXExplorerToolbar

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialize state
        self.expanded = NO;
        self.isOnRightEdge = NO;
        
        // Background
        self.backgroundView = [UIView new];
        self.backgroundView.backgroundColor = [FLEXColor secondaryBackgroundColorWithAlpha:0.95];
        [self addSubview:self.backgroundView];

        // Drag handle
        self.dragHandle = [UIView new];
        self.dragHandle.backgroundColor = UIColor.clearColor;
        UIImage *chevronImage = [self chevronImageForExpandedState:NO];
        self.dragHandleImageView = [[UIImageView alloc] initWithImage:chevronImage];
        self.dragHandleImageView.tintColor = [FLEXColor.iconColor colorWithAlphaComponent:0.666];
        self.dragHandleImageView.contentMode = UIViewContentModeCenter;
        [self.dragHandle addSubview:self.dragHandleImageView];
        [self addSubview:self.dragHandle];
        
        // Buttons
        self.globalsItem   = [FLEXExplorerToolbarItem itemWithTitle:@"menu" image:FLEXResources.globalsIcon];
        self.hierarchyItem = [FLEXExplorerToolbarItem itemWithTitle:@"views" image:FLEXResources.hierarchyIcon];
        self.selectItem    = [FLEXExplorerToolbarItem itemWithTitle:@"select" image:FLEXResources.selectIcon];
        self.recentItem    = [FLEXExplorerToolbarItem itemWithTitle:@"recent" image:FLEXResources.recentIcon];
        self.moveItem      = [FLEXExplorerToolbarItem itemWithTitle:@"move" image:FLEXResources.moveIcon sibling:self.recentItem];
        self.closeItem     = [FLEXExplorerToolbarItem itemWithTitle:@"close" image:FLEXResources.closeIcon];

        // Selected view box //
        
        self.selectedViewDescriptionContainer = [UIView new];
        self.selectedViewDescriptionContainer.backgroundColor = [FLEXColor tertiaryBackgroundColorWithAlpha:0.95];
        self.selectedViewDescriptionContainer.hidden = YES;
        [self addSubview:self.selectedViewDescriptionContainer];

        self.selectedViewDescriptionSafeAreaContainer = [UIView new];
        self.selectedViewDescriptionSafeAreaContainer.backgroundColor = UIColor.clearColor;
        [self.selectedViewDescriptionContainer addSubview:self.selectedViewDescriptionSafeAreaContainer];
        
        self.selectedViewColorIndicator = [UIView new];
        self.selectedViewColorIndicator.backgroundColor = UIColor.redColor;
        [self.selectedViewDescriptionSafeAreaContainer addSubview:self.selectedViewColorIndicator];
        
        self.selectedViewDescriptionLabel = [UILabel new];
        self.selectedViewDescriptionLabel.backgroundColor = UIColor.clearColor;
        self.selectedViewDescriptionLabel.font = [[self class] descriptionLabelFont];
        [self.selectedViewDescriptionSafeAreaContainer addSubview:self.selectedViewDescriptionLabel];
        
        // toolbarItems
        self.toolbarItems = @[_globalsItem, _hierarchyItem, _selectItem, _moveItem, _closeItem];
    }

    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    CGRect safeArea = [self safeArea];
    const CGFloat kToolbarItemHeight = [[self class] toolbarItemHeight];
    const CGFloat dragHandleWidth = [[self class] dragHandleWidth];
    
    // Drag Handle
    CGFloat dragHandleX = self.isOnRightEdge ? (CGRectGetMaxX(safeArea) - dragHandleWidth) : CGRectGetMinX(safeArea);
    self.dragHandle.frame = CGRectMake(dragHandleX, CGRectGetMinY(safeArea), dragHandleWidth, kToolbarItemHeight);
    CGRect dragHandleImageFrame = self.dragHandleImageView.frame;
    dragHandleImageFrame.origin.x = FLEXFloor((self.dragHandle.frame.size.width - dragHandleImageFrame.size.width) / 2.0);
    dragHandleImageFrame.origin.y = FLEXFloor((self.dragHandle.frame.size.height - dragHandleImageFrame.size.height) / 2.0);
    self.dragHandleImageView.frame = dragHandleImageFrame;
    
    // Toolbar Items
    CGFloat originY = CGRectGetMinY(safeArea);
    CGFloat height = kToolbarItemHeight;
    
    if (self.expanded) {
        // Show all items equally distributed
        CGFloat totalItemsWidth = CGRectGetWidth(safeArea) - dragHandleWidth;
        CGFloat width = FLEXFloor(totalItemsWidth / self.toolbarItems.count);
        
        if (self.isOnRightEdge) {
            // Right side: reverse order (close, recent, select, views, menu) then drag handle
            NSArray *reversedItems = [[self.toolbarItems reverseObjectEnumerator] allObjects];
            CGFloat originX = CGRectGetMinX(safeArea);
            
            for (FLEXExplorerToolbarItem *toolbarItem in reversedItems) {
                toolbarItem.currentItem.hidden = NO;
                toolbarItem.currentItem.frame = CGRectMake(originX, originY, width, height);
                originX = CGRectGetMaxX(toolbarItem.currentItem.frame);
            }
            
            // Adjust last item to end at drag handle
            FLEXExplorerToolbarItem *lastItem = (FLEXExplorerToolbarItem *)reversedItems.lastObject;
            UIView *lastToolbarItem = lastItem.currentItem;
            CGRect lastToolbarItemFrame = lastToolbarItem.frame;
            lastToolbarItemFrame.size.width = dragHandleX - lastToolbarItemFrame.origin.x;
            lastToolbarItem.frame = lastToolbarItemFrame;
        } else {
            // Left side: drag handle then normal order (menu, views, select, recent, close)
            CGFloat originX = CGRectGetMaxX(self.dragHandle.frame);
            
            for (FLEXExplorerToolbarItem *toolbarItem in self.toolbarItems) {
                toolbarItem.currentItem.hidden = NO;
                toolbarItem.currentItem.frame = CGRectMake(originX, originY, width, height);
                originX = CGRectGetMaxX(toolbarItem.currentItem.frame);
            }
            
            // Adjust last item to reach the edge
            UIView *lastToolbarItem = self.toolbarItems.lastObject.currentItem;
            CGRect lastToolbarItemFrame = lastToolbarItem.frame;
            lastToolbarItemFrame.size.width = CGRectGetMaxX(safeArea) - lastToolbarItemFrame.origin.x;
            lastToolbarItem.frame = lastToolbarItemFrame;
        }
    } else {
        // Collapsed state - hide all items, only show drag handle
        for (FLEXExplorerToolbarItem *toolbarItem in self.toolbarItems) {
            toolbarItem.currentItem.hidden = YES;
        }
    }

    // Background should match the actual toolbar width
    CGFloat backgroundWidth = self.expanded ? CGRectGetWidth(self.bounds) : dragHandleWidth;
    CGFloat backgroundX = self.isOnRightEdge ? (CGRectGetWidth(self.bounds) - backgroundWidth) : 0;
    self.backgroundView.frame = CGRectMake(backgroundX, 0, backgroundWidth, kToolbarItemHeight);
    
    const CGFloat kSelectedViewColorDiameter = [[self class] selectedViewColorIndicatorDiameter];
    const CGFloat kDescriptionLabelHeight = [[self class] descriptionLabelHeight];
    const CGFloat kHorizontalPadding = [[self class] horizontalPadding];
    const CGFloat kDescriptionVerticalPadding = [[self class] descriptionVerticalPadding];
    const CGFloat kDescriptionContainerHeight = [[self class] descriptionContainerHeight];
    
    CGRect descriptionContainerFrame = CGRectZero;
    CGFloat descriptionWidth = self.expanded ? CGRectGetWidth(self.bounds) : backgroundWidth;
    descriptionContainerFrame.size.width = descriptionWidth;
    descriptionContainerFrame.size.height = kDescriptionContainerHeight;
    descriptionContainerFrame.origin.x = self.isOnRightEdge ? (CGRectGetWidth(self.bounds) - descriptionWidth) : CGRectGetMinX(self.bounds);
    descriptionContainerFrame.origin.y = CGRectGetMaxY(self.bounds) - kDescriptionContainerHeight;
    self.selectedViewDescriptionContainer.frame = descriptionContainerFrame;

    CGRect descriptionSafeAreaContainerFrame = CGRectZero;
    CGFloat safeAreaWidth = self.expanded ? CGRectGetWidth(safeArea) : MIN(CGRectGetWidth(safeArea), backgroundWidth);
    descriptionSafeAreaContainerFrame.size.width = safeAreaWidth;
    descriptionSafeAreaContainerFrame.size.height = kDescriptionContainerHeight;
    descriptionSafeAreaContainerFrame.origin.x = self.isOnRightEdge ? (CGRectGetMaxX(safeArea) - safeAreaWidth) : CGRectGetMinX(safeArea);
    descriptionSafeAreaContainerFrame.origin.y = CGRectGetMinY(safeArea);
    self.selectedViewDescriptionSafeAreaContainer.frame = descriptionSafeAreaContainerFrame;

    // Selected View Color
    CGRect selectedViewColorFrame = CGRectZero;
    selectedViewColorFrame.size.width = kSelectedViewColorDiameter;
    selectedViewColorFrame.size.height = kSelectedViewColorDiameter;
    selectedViewColorFrame.origin.x = kHorizontalPadding;
    selectedViewColorFrame.origin.y = FLEXFloor((kDescriptionContainerHeight - kSelectedViewColorDiameter) / 2.0);
    self.selectedViewColorIndicator.frame = selectedViewColorFrame;
    self.selectedViewColorIndicator.layer.cornerRadius = ceil(selectedViewColorFrame.size.height / 2.0);
    
    // Selected View Description
    CGRect descriptionLabelFrame = CGRectZero;
    CGFloat descriptionOriginX = CGRectGetMaxX(selectedViewColorFrame) + kHorizontalPadding;
    descriptionLabelFrame.size.height = kDescriptionLabelHeight;
    descriptionLabelFrame.origin.x = descriptionOriginX;
    descriptionLabelFrame.origin.y = kDescriptionVerticalPadding;
    descriptionLabelFrame.size.width = CGRectGetMaxX(self.selectedViewDescriptionContainer.bounds) - kHorizontalPadding - descriptionOriginX;
    self.selectedViewDescriptionLabel.frame = descriptionLabelFrame;
}


#pragma mark - Setter Overrides

- (void)setToolbarItems:(NSArray<FLEXExplorerToolbarItem *> *)toolbarItems {
    if (_toolbarItems == toolbarItems) {
        return;
    }
    
    // Remove old toolbar items, if any
    for (FLEXExplorerToolbarItem *item in _toolbarItems) {
        [item.currentItem removeFromSuperview];
    }
    
    // Trim to 5 items if necessary
    if (toolbarItems.count > 5) {
        toolbarItems = [toolbarItems subarrayWithRange:NSMakeRange(0, 5)];
    }

    for (FLEXExplorerToolbarItem *item in toolbarItems) {
        [self addSubview:item.currentItem];
    }

    _toolbarItems = toolbarItems.copy;

    // Lay out new items
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

- (void)setSelectedViewOverlayColor:(UIColor *)selectedViewOverlayColor {
    if (![_selectedViewOverlayColor isEqual:selectedViewOverlayColor]) {
        _selectedViewOverlayColor = selectedViewOverlayColor;
        self.selectedViewColorIndicator.backgroundColor = selectedViewOverlayColor;
    }
}

- (void)setSelectedViewDescription:(NSString *)selectedViewDescription {
    if (![_selectedViewDescription isEqual:selectedViewDescription]) {
        _selectedViewDescription = selectedViewDescription;
        self.selectedViewDescriptionLabel.text = selectedViewDescription;
        BOOL showDescription = selectedViewDescription.length > 0;
        self.selectedViewDescriptionContainer.hidden = !showDescription;
    }
}


#pragma mark - Sizing Convenience Methods

+ (UIFont *)descriptionLabelFont {
    return [UIFont systemFontOfSize:12.0];
}

+ (CGFloat)toolbarItemHeight {
    return 44.0;
}

+ (CGFloat)dragHandleWidth {
    return FLEXResources.dragHandle.size.width;
}

+ (CGFloat)descriptionLabelHeight {
    return ceil([[self descriptionLabelFont] lineHeight]);
}

+ (CGFloat)descriptionVerticalPadding {
    return 2.0;
}

+ (CGFloat)descriptionContainerHeight {
    return [self descriptionVerticalPadding] * 2.0 + [self descriptionLabelHeight];
}

+ (CGFloat)selectedViewColorIndicatorDiameter {
    return ceil([self descriptionLabelHeight] / 2.0);
}

+ (CGFloat)horizontalPadding {
    return 11.0;
}

- (CGSize)sizeThatFits:(CGSize)size {
    CGFloat height = 0.0;
    height += [[self class] toolbarItemHeight];
    height += [[self class] descriptionContainerHeight];
    
    CGFloat width = size.width;
    if (!self.expanded) {
        // When collapsed, only show drag handle
        CGFloat collapsedWidth = [[self class] dragHandleWidth];
        width = MIN(collapsedWidth, size.width);
    }
    
    return CGSizeMake(width, height);
}

- (CGRect)safeArea {
    CGRect safeArea = self.bounds;
    if (@available(iOS 11.0, *)) {
        safeArea = UIEdgeInsetsInsetRect(self.bounds, self.safeAreaInsets);
    }

    return safeArea;
}

- (UIImage *)chevronImageForExpandedState:(BOOL)expanded {
    // Use SF Symbols if available (iOS 13+)
    if (@available(iOS 13.0, *)) {
        NSString *symbolName;
        
        if (self.isOnRightEdge) {
            // Right edge: reversed logic
            symbolName = expanded ? @"chevron.right" : @"chevron.left";
        } else {
            // Left edge: normal logic
            symbolName = expanded ? @"chevron.left" : @"chevron.right";
        }
        
        UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:17 weight:UIImageSymbolWeightMedium];
        return [UIImage systemImageNamed:symbolName withConfiguration:config];
    } else {
        // Fallback for iOS 12 and earlier - use the original drag handle
        return FLEXResources.dragHandle;
    }
}

- (void)updateDragHandleIcon {
    UIImage *newImage = [self chevronImageForExpandedState:self.expanded];
    
    // Animate icon change with a flip transition
    [UIView transitionWithView:self.dragHandleImageView
                      duration:0.3
                       options:UIViewAnimationOptionTransitionFlipFromLeft
                    animations:^{
        self.dragHandleImageView.image = newImage;
    } completion:nil];
}

- (void)toggleExpansion {
    self.expanded = !self.expanded;
    
    // Update drag handle icon
    [self updateDragHandleIcon];
    
    // Calculate new size
    CGSize newSize = [self sizeThatFits:self.superview.bounds.size];
    
    [UIView animateWithDuration:0.3
                          delay:0.0
         usingSpringWithDamping:0.8
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
        CGRect newFrame = self.frame;
        CGFloat widthDifference = newSize.width - newFrame.size.width;
        
        // Update width
        newFrame.size.width = newSize.width;
        
        // If on right side, adjust origin.x to keep right edge fixed
        if (self.isOnRightEdge) {
            newFrame.origin.x -= widthDifference;
        }
        
        self.frame = newFrame;
        
        [self setNeedsLayout];
        [self layoutIfNeeded];
    } completion:nil];
}

@end
