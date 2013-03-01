//
//  TMLDBManager.m
//  ORMMA
//
//  Created by The Mobile Life on 20/09/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "TMLDBManager.h"
#include <sqlite3.h>

static sqlite3 *database = NULL;

@implementation TMLDBManager

- (id)init
{
  self = [super init];
  if (self == nil)
    return nil;
   
  NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];   
  NSString *dbPath = [documentPath stringByAppendingPathComponent:@"Ads.sql"];
  if ([[NSFileManager defaultManager] fileExistsAtPath:dbPath] == NO)
  {
    NSString *dbBundlePath = [[NSBundle mainBundle] pathForResource:@"Ads" ofType:@"sql"];
    [[NSFileManager defaultManager] copyItemAtPath:dbBundlePath toPath:dbPath error:NULL];
  }
  
  if (sqlite3_open([dbPath UTF8String], &database) != SQLITE_OK)
  {
    NSAssert1(0, @"Error : ", sqlite3_errmsg(database));
  }
    
  return self;
}

- (NSDictionary *)formattedDictionaryFromString:(NSString *)str
{
  NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
  
  NSArray *paramsArray = [str componentsSeparatedByString:@";"];
  for (int i = 0; i < paramsArray.count; ++i)
  {
      NSString *param = [paramsArray objectAtIndex:i];
      NSArray *paramArray = [param componentsSeparatedByString:@"="];
      if(paramArray.count == 2){
          [params setObject:[paramArray objectAtIndex:1] forKey:[paramArray objectAtIndex:0]];
      }
  }
  
  return [params autorelease];
}

- (NSDictionary *)formattedDictionaryFromDictionary:(NSDictionary *)dict
{
  NSMutableDictionary *params = [[NSMutableDictionary alloc] init];;
  NSArray *paramsArray = [[dict objectForKey:@"Params"] componentsSeparatedByString:@";"];
  for (int i = 0; i < paramsArray.count; ++i)
  {
    NSString *param = [paramsArray objectAtIndex:i];
    NSArray *paramArray = [param componentsSeparatedByString:@"="];
    if(paramArray.count == 2){
        [params setObject:[paramArray objectAtIndex:1] forKey:[paramArray objectAtIndex:0]];
    }
  }
  NSDictionary *urlParams = [[NSDictionary alloc] initWithObjectsAndKeys:[dict objectForKey:@"AdName"], @"AdName", [dict objectForKey:@"BaseURL"], @"BaseURL", params, @"Params", nil];
  NSLog(@"urlParams = %@", urlParams);
  [params release];
  params = nil;
  return [urlParams autorelease];
}

- (void)insertAd:(NSDictionary *)ad
{
  char *query = "INSERT INTO Ads(name, params, url) VALUES(?, ?, ?)";
  sqlite3_stmt *statement = NULL;
  if (sqlite3_prepare_v2(database, query, -1, &statement, NULL) != SQLITE_OK)
  {
    NSAssert1(0, @"Error in insert prepare : ", sqlite3_errmsg(database));
  }
  sqlite3_bind_text(statement, 1, [[ad objectForKey:@"AdName"] UTF8String], -1, NULL);
  sqlite3_bind_text(statement, 2, [[ad objectForKey:@"Params"] UTF8String], -1, NULL);
  sqlite3_bind_text(statement, 3, [[ad objectForKey:@"BaseURL"] UTF8String], -1, NULL);
  if (sqlite3_step(statement) != SQLITE_DONE)
  {
    NSAssert1(0, @"Error in insert step : ", sqlite3_errmsg(database));
  }
  
  sqlite3_finalize(statement);
  //sqlite3_reset(statement);
  statement = NULL;
}

- (void)deleteAdWithId:(NSInteger)key
{
  char *query = "DELETE FROM Ads WHERE key=?";
  sqlite3_stmt *statement = NULL;
  if (sqlite3_prepare_v2(database, query, -1, &statement, NULL) != SQLITE_OK)
  {
    NSAssert1(0, @"Error in delete prepare : ", sqlite3_errmsg(database));
  }
  sqlite3_bind_int(statement, 1, key);
  if (sqlite3_step(statement) != SQLITE_DONE)
  {
    NSAssert1(0, @"Error in delete step : ", sqlite3_errmsg(database));
  }
  
  sqlite3_finalize(statement);
  statement = NULL;
}

- (NSArray *)ads
{
  NSMutableArray *ads = [[[NSMutableArray alloc] init] autorelease];
  char *query = "SELECT * FROM Ads";
  sqlite3_stmt *statement = NULL;
  if (sqlite3_prepare_v2(database, query, -1, &statement, NULL) != SQLITE_OK)
  {
    NSAssert1(0, @"Error in select prepare : ", sqlite3_errmsg(database));
  }
  
 
  while (sqlite3_step(statement) == SQLITE_ROW)
  {
    NSMutableDictionary *ad = [[NSMutableDictionary alloc] init];
    
    int key = sqlite3_column_int(statement, 0);    
    [ad setObject:[NSNumber numberWithInt:key] forKey:@"Key"];
    
    const unsigned char *name = sqlite3_column_text(statement, 1);
    if (name)
    {
      NSString *adName = [[NSString alloc] initWithFormat:@"%s", name];
      [ad setObject:adName forKey:@"AdName"];
      [adName release];
      adName = nil;
    }
    
    const unsigned char *params = sqlite3_column_text(statement, 2);
    if (params)
    {
      NSString *adParams = [[NSString alloc] initWithFormat:@"%s", params];
      [ad setObject:[self formattedDictionaryFromString:adParams] forKey:@"Params"];
      [adParams release];
      adParams = nil;
    }
    
    const unsigned char *url = sqlite3_column_text(statement, 3);
    if (url)
    {
      NSString *baseURL = [[NSString alloc] initWithFormat:@"%s", url];
      [ad setObject:baseURL forKey:@"BaseURL"];
      [baseURL release];
      baseURL = nil;
    }
    
    [ads addObject:ad];
    [ad release];
    ad = nil;
  }
      
  sqlite3_finalize(statement);
  statement = NULL;

  return ads;
}

- (void)closeDB
{
  if (sqlite3_close(database) != SQLITE_OK)
  {
    NSAssert1(0, @"Error in closing database : ", sqlite3_errmsg(database));
  }
}

+ (TMLDBManager *)sharedInstance
{
  TMLDBManager *sharedInstance = nil;
  
  if (sharedInstance == nil)
  {
    sharedInstance = [[TMLDBManager alloc] init];
  }
  return sharedInstance;
}

@end
