//
//  TMLDBManager.h
//  ORMMA
//
//  Created by The Mobile Life on 20/09/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TMLDBManager : NSObject

+ (TMLDBManager *)sharedInstance;

- (void)insertAd:(NSDictionary *)ad;
- (void)deleteAdWithId:(NSInteger)key;
- (NSArray *)ads;
- (void)closeDB;
- (NSDictionary *)formattedDictionaryFromDictionary:(NSDictionary *)dict;

@end
