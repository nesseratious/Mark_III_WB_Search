//
//  ViewController.h
//  Mark_III_WB_Search
//
//  Created by Denis Esie on 07.02.2024.
//

#import <UIKit/UIKit.h>

@class Event;

@interface ViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate>
@end

@interface ViewController (TmpUtility)
- (void)performSearchText:(NSString* )text events:(Event* __strong*)events eventsCount:(NSInteger)eventsCount completion: (void (^)(NSInteger count, BOOL finished, const void* partialBytes, NSUInteger length))completion;
@end

