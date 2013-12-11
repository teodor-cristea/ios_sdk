/*  Copyright (c) 2011 The ORMMA.org project authors. All Rights Reserved.
 *
 *  Use of this source code is governed by a BSD-style license
 *  that can be found in the LICENSE file in the root of the source
 *  tree. All contributing project authors may
 *  be found in the AUTHORS file in the root of the source tree.
 */

#import <UIKit/UIKit.h>
#import "MRAIDDataAccessLayer.h"
#import "MRAIDLocalServer.h"



@interface MRAIDDataAccessLayer ()

@property( nonatomic, copy ) NSString *databasePath;

- (void)updateDatabaseSchemaForRecovery:(BOOL)recovery;
- (BOOL)processSchemaFile:(NSString *)path;

// opens the database
- (BOOL)open;

// closes the database
- (void)close;


- (void)handleDidBecomeActiveNotification:(NSNotification *)notification;
- (void)handleDidResignActiveNotification:(NSNotification *)notification;

@end




@implementation MRAIDDataAccessLayer


#pragma mark -
#pragma mark Constants




#pragma mark -
#pragma mark Properties

@dynamic databasePath;



#pragma mark -
#pragma mark Initializers / Memory Management

+ (MRAIDDataAccessLayer *)sharedInstance
{
	static MRAIDDataAccessLayer *sharedInstance = nil;

    @synchronized( self )
    {
        if ( sharedInstance == nil )
		{
			sharedInstance = [[MRAIDDataAccessLayer alloc] init];
		}
    }
    return sharedInstance;
}


- (MRAIDDataAccessLayer *)init
{
	if ( ( self = [super init] ) )
	{
		// open the database
		[self open];
		
		// listen for major device events
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		[nc addObserver:self
			   selector:@selector(handleDidBecomeActiveNotification:)
				   name:UIApplicationDidBecomeActiveNotification
				 object:nil];
		[nc addObserver:self
			   selector:@selector(handleDidResignActiveNotification:)
				   name:UIApplicationWillResignActiveNotification
				 object:nil];
	}
	return self;
}


- (void)dealloc
{
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc removeObserver:self];

	// shutdown the database
	[self close];
}



#pragma mark -
#pragma mark Dynamic Properties

- (NSString *)databasePath
{
	NSArray *systemPaths = NSSearchPathForDirectoriesInDomains( NSCachesDirectory, NSUserDomainMask, YES ); 
	NSString *basePath = [systemPaths objectAtIndex:0]; 
	NSString *path = [basePath stringByAppendingPathComponent:@"mraid.db"];
	return path;
}



#pragma mark -
#pragma mark Notification Handlers

- (void)handleDidBecomeActiveNotification:(NSNotification *)notification
{
	@synchronized( self )
	{
		// re-open the database connection if needed
		NSLog( @"Caught Application Did Become Active-- restoring access to the MRAID database..." );

		[self open];
	}
}


- (void)handleDidResignActiveNotification:(NSNotification *)notification
{
	@synchronized( self )
	{
		// close the database if needed
		NSLog( @"Caught Application Did Resign Active-- closing access to the MRAID database..." );
		
		[self close];
	}
}



#pragma mark -
#pragma mark Database Control

- (BOOL)open
{
	// build path to db
	BOOL opened = NO;
	@synchronized( self )
	{
		if ( m_database == nil )
		{
			m_database = [FMDatabase databaseWithPath:self.databasePath];
			opened = [m_database open];
			if ( !opened )
			{
				// error opening the database, shut it down
				NSLog( @"Could not open the MRAID database" );
				m_database  = nil;
			}
			
			// the database is opened, update the schema if necessary
			[self updateDatabaseSchemaForRecovery:NO];
			
			NSLog( @"MRAID Database is open and ready for business." );
		}
	}
	return opened;
}


- (void)close
{
	@synchronized( self )
	{
		if ( m_database != nil )
		{
			[m_database close], m_database = nil;

			NSLog( @"MRAID Database is closed." );
		}
	}
}



#pragma mark -
#pragma mark Cache Management

- (void)cacheCreative:(NSString *)creativeId
			   forURL:(NSURL *)url
{
	@synchronized( self )
	{
		NSAssert( ( m_database != nil ), @"Database not open!" );
		
		// first see if the creative already exists
		NSLog( @"Caching Creative: %@ from %@", creativeId, url );
		BOOL exists = NO;
		FMResultSet *rs = [m_database executeQuery:@"SELECT * FROM creatives WHERE hash = ?", creativeId];
		if ( [rs next] )
		{
			// already exists
			NSLog( @"Cache Entry already exists" );
			exists = YES;
		}
		
		[m_database beginTransaction];
		if ( exists )
		{
			// already exists, just update the accessed date
			NSLog( @"Updating existing cache entry" );
			[m_database executeUpdate:@"UPDATE creatives SET last_accessed = CURRENT_TIMESTAMP"];
		}
		else
		{
			NSLog( @"Making new cache entry" );
			[m_database executeUpdate:@"INSERT INTO creatives( hash ) VALUES( ? )", creativeId];
		}
		[m_database commit];
		
		NSLog( @"Creative caching complete." );
	}
}


- (void)creativeAccessed:(NSString *)creativeId
{
	@synchronized( self )
	{
		NSAssert( ( m_database != nil ), @"Database not open!" );
		
		[m_database beginTransaction];
		[m_database executeUpdate:@"UPDATE creatives SET last_accessed = CURRENT_TIMESTAMP"];
		[m_database commit];
	}
}


- (void)removeCreative:(NSString *)creativeId
{
	@synchronized( self )
	{
		NSAssert( ( m_database != nil ), @"Database not open!" );

		[m_database beginTransaction];
		[m_database executeUpdate:@"DELETE FROM creatives WHERE hash = ?", creativeId];
		[m_database commit];
	}
}


- (void)incrementCacheUsageForCreative:(NSString *)creativeId
									by:(unsigned long long)bytes;
{
	@synchronized( self )
	{
		NSAssert( ( m_database != nil ), @"Database not open!" );

		[m_database beginTransaction];
		[m_database executeUpdate:@"UPDATE creatives SET size = size + ? WHERE hash = ?", bytes, creativeId];
		[m_database commit];
	}
}


- (void)decrementCacheUsageForCreative:(NSString *)creativeId
									by:(unsigned long long)bytes;
{
	@synchronized( self )
	{
		NSAssert( ( m_database != nil ), @"Database not open!" );
		
		[m_database beginTransaction];
		[m_database executeUpdate:@"UPDATE creatives SET size = size - ? WHERE hash = ?", bytes, creativeId];
		[m_database commit];
	}
}


- (void)truncateCacheUsageForCreative:(NSString *)creativeId
{
	@synchronized( self )
	{
		NSAssert( ( m_database != nil ), @"Database not open!" );
		
		[m_database beginTransaction];
		[m_database executeUpdate:@"UPDATE creatives SET size = 0 WHERE hash = ?", creativeId];
		[m_database commit];
	}
}


- (void)removeAllCreatives
{
	@synchronized( self )
	{
		NSAssert( ( m_database != nil ), @"Database not open!" );
		
		[m_database beginTransaction];
		[m_database executeUpdate:@"DELETE FROM creatives"];
		[m_database commit];
	}
}


#pragma mark -
#pragma mark Store and Forwards

- (void)storeRequest:(NSString *)request
{
	@synchronized( self )
	{
		NSAssert( ( m_database != nil ), @"Database not open!" );
		
		[m_database beginTransaction];
		[m_database executeUpdate:@"INSERT INTO proxy_requests( request ) VALUES( ? )", request];
		[m_database commit];
	}
}


- (MRAIDStoreAndForwardRequest *)getNextStoreAndForwardRequest;
{
	MRAIDStoreAndForwardRequest *saf = nil;
	@synchronized( self )
	{
		NSAssert( ( m_database != nil ), @"Database not open!" );
		
		FMResultSet *rs = [m_database executeQuery:@"SELECT * FROM proxy_requests ORDER BY created_on LIMIT 1"];
		if ( [rs next] )
		{
			saf = [[MRAIDStoreAndForwardRequest alloc] init];
			saf.requestNumber = [rs longForColumn:@"request_number"];
			saf.request = [rs stringForColumn:@"request"];
			saf.createdOn = [rs dateForColumn:@"c reated_on"];
		}
	}
	return saf;
}


- (void)removeStoreAndForwardRequestWithRequestNumber:(NSNumber *)requestNumber;
{
	@synchronized( self )
	{
		NSAssert( ( m_database != nil ), @"Database not open!" );
		
		[m_database beginTransaction];
		[m_database executeUpdate:@"DELETE FROM proxy_requests WHERE request_number = ?", requestNumber];
		[m_database commit];
	}
}



#pragma mark -
#pragma mark Schema Management

- (void)updateDatabaseSchemaForRecovery:(BOOL)recovery
{
	NSFileManager *fm = [NSFileManager defaultManager];
	NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"MRAID"
													 ofType:@"bundle"];
	if ( bundlePath == nil )
	{
		[NSException raise:@"Invalid Build Detected"
					format:@"Unable to find MRAID.bundle. Make sure it is added to your resources!"];
	}
	m_mraidBundle = [NSBundle bundleWithPath:bundlePath];
	NSString *sqlPath;
	
	// this is only called on database open.
	// the database object is already locked, nothing else can happen until 
	// we're finished, no need for more locks.
	
	// determine the current database version
	NSInteger version = 0;
	FMResultSet *rs = [m_database executeQuery:@"SELECT version FROM schema_version"];
	if ( [rs next] )
	{
		version = [rs intForColumn:@"version"];
	}
	
	NSLog( @"Current MRAID Database Version is: %i", version );
	
	// now see if there are any new schema files we need to apply
	for ( version++; /* no condition */ ; version++ )
	{
		sqlPath = [m_mraidBundle pathForResource:[NSString stringWithFormat:@"%i", version]
										  ofType:@"sql"];
		if ( sqlPath == nil )
		{
			// no more files to process
			break;
		}
		NSLog( @"Looking for MRAID Schema File: %@", sqlPath );
		
		// we have a schema file, process it
		if ( ![self processSchemaFile:sqlPath] )
		{
			// unable to upgrade the schema, we need to try to recover, so
			// let's trash the cache completely (since we will lose our cache
			// management data anyway)
			[MRAIDLocalServer removeAllCachedResources];
			
			// Now, let's trash the entire database
			[self close];
			[fm removeItemAtPath:self.databasePath 
						   error:NULL];
			[self open];
			
			if ( recovery )
			{
				// we're already trying to recover, something is woefully wrong
				// let's just crash the app and hope things pick up correctly
				// on a restart
				[NSException raise:@"Database Recovery Failure"
							format:@"The initial database recovery failed; attempting to correct on restart"];
				return;
			}
			
			// this is the first time we've tried this, so let's just restart
			// the schema update process
			[self updateDatabaseSchemaForRecovery:YES];
			return;
		}

		// now update the schema version
		[m_database beginTransaction];
		[m_database executeUpdate:@"UPDATE schema_version SET version = ?", [NSNumber numberWithInt:version]];
		[m_database commit];
	}
}



- (BOOL)processSchemaFile:(NSString *)path
{
	// assume data is in UTF8
	NSLog( @"Processing MRAID Schema File: %@", path );
	NSString *string = [NSString stringWithContentsOfFile:path
												 encoding:NSUTF8StringEncoding
													error:NULL];
	
	// first, let's remove '/*' + '*/' comments
	NSRange commentStart;
	NSRange commentEnd;
	for ( commentStart = [string rangeOfString:@"/*"]; commentStart.location != NSNotFound; commentStart = [string rangeOfString:@"/*"] )
	{
		// we've found the start of a comment, now find the end
		commentEnd = [string rangeOfString:@"*/"];
		if ( commentEnd.location == NSNotFound)
		{
			// no end of comment, bail
			[NSException raise:@"Syntax Error"
						format:@"Error in SQL file: no end of comment."];
		}
		if ( commentEnd.location < commentStart.location )
		{
			// end of comment before start of comment, bail
			[NSException raise:@"Syntax Error"
						format:@"Error in SQL file: end of comment before start."];
		}
		
		// ok we've got the bounds of the comment
		NSRange comment;
		comment.location = commentStart.location;
		comment.length = ( 2 + ( commentEnd.location - commentStart.location ) );
		string = [string stringByReplacingCharactersInRange:comment
												 withString:@""];
	}	
	
	// now let's process the file, line by line
	NSArray *lines = [string componentsSeparatedByString:@"\n"];
	NSMutableString *sql = [NSMutableString stringWithCapacity:1000];
	for ( NSString *line in lines )
	{
		// remove comment to end of line
		NSArray *text = [line componentsSeparatedByString:@"--"];
		if ( text.count == 0 )
		{
			// nothing to do
			continue;
		} 
		NSString *workingLine = [[text objectAtIndex:0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		if ( workingLine.length > 0 )
		{
			
			[sql appendString:@" "];
			[sql appendString:workingLine];
			if ( [workingLine hasSuffix:@";"] )
			{
				// execute SQL command
				[m_database beginTransaction];
				NSLog( @"Executing SQL: %@", sql );
				[m_database executeUpdate:sql];
				[m_database commit];
				
				// now clear the SQL for the next loop
				NSRange deleteRange = { 0, sql.length };
				[sql deleteCharactersInRange:deleteRange];
			}
		}
	}
	
	return YES;
}



@end
