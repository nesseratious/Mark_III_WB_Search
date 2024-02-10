//
//  ModelInterface.h
//  Mark_III_WB_Search
//
//  Created by developer on 11.02.2024.
//

#import <Foundation/NSObject.h>

@class NSDate, NSString;
@class Event;
@protocol ModelInterfaceDelegate;


@protocol ModelInterface<NSObject>
@property (nonatomic, weak) id<ModelInterfaceDelegate> delegate;

@property (nonatomic, readonly) NSUInteger eventsCount;
- (Event*)eventAtIndex:(NSUInteger)index;

- (void)fetchNextFutureEvents;
- (void)fetchNextPastEvents;

- (void)filterWithText:(NSString*)text;
@end


@protocol ModelInterfaceDelegate<NSObject>
- (void)eventsListDidChange:(id<ModelInterface>)model;
@end


extern const NSInteger nextEventsFetchingYearsCount;
extern const NSInteger initialEventsFetchingPastYearsCount;
extern const NSInteger initialEventsFetchingFutureYearsCount;


// TODO: ability to recalculate indexes when fetching past events
// TODO: initialize real class with defining date
