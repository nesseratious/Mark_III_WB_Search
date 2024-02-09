//
//  Event.h
//  Mark_III_WB_Search
//
//  Created by Denis Esie on 07.02.2024.
//

#ifndef Event_h
#define Event_h

#import <Foundation/Foundation.h>

@interface Event : NSObject

@property (nonatomic, direct) NSString *title;
@property (nonatomic, direct) NSDate *startDate;
@property (nonatomic, direct) NSDate *endDate;

- (instancetype)initWithTitle:(NSString *)title startDate:(NSDate *)startDate endDate:(NSDate *)endDate;

@end

#endif /* Event_h */
