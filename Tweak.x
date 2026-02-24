#import <Foundation/Foundation.h>




//Removing ads in the Instagram reels feed

//Hooking into the IGSundialFeedDataSource class, which is responsible for providing data to the reels feed
%hook IGSundialFeedDataSource 

//This method is called to get the list of items to display in the feed
- (id)objectsForListAdapter:(id)arg1 {
    NSArray *original_feed = %orig;
	NSMutableArray *filtered_feed = [NSMutableArray array];
	for (id item in original_feed) {

		//Ad objects are of type IGAdItem, regular content is of type IGMedia
		if ([item isKindOfClass:%c(IGAdItem)]) {
			NSLog(@"[IGAdBlock] Reel ad removed.");
			continue;
		}
		[filtered_feed addObject:item];
	}
    return filtered_feed; 
}
%end


//Hooking into the IGMainFeedListAdapterDataSource class, which is responsible for providing data to the main feed
%hook IGMainFeedListAdapterDataSource


- (id)objectsForListAdapter:(id)arg1 {
	NSArray *original_feed = %orig;
	NSMutableArray *filtered_feed = [NSMutableArray array];
	for (id item in original_feed) {
		if ([item isKindOfClass:%c(IGAdItem)]) {
			NSLog(@"[IGAdBlock] Main feed ad removed.");
			continue;
		}
		
		//Threads in feed are of type IGThreadsInFeedModel, mangled due to Swift obfuscation
		else if ([item isKindOfClass:objc_getClass("IGThreadsInFeedModels.IGThreadsInFeedModel")]) {
			NSLog(@"[IGAdBlock] Threads removed.");
			continue;
		}

		[filtered_feed addObject:item];
	}
	
	return filtered_feed; 
}

%end



%ctor {
    %init;
}
