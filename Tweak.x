#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>




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




%hook UIViewController

- (void)presentViewController:(UIViewController *)viewControllerToPresent animated:(BOOL)flag completion:(void (^)(void))completion {
    // Look up the Swift class dynamically
    Class nagClass = objc_getClass("IGCoreRootTestFlightNagPlugin.TestFlightUpdateNudgeViewController");
    
    // Check if the view controller about to be shown is our culprit
    if (nagClass && [viewControllerToPresent isKindOfClass:nagClass]) {
        NSLog(@"[IGAdBlock] Prevented TestFlight update nudge from presenting entirely!");
        
        // Safely execute completion block if the calling function expected one
        if (completion) {
            completion();
        }
        return; // Halt execution here, skipping %orig
    }
    
    // Otherwise, carry on as normal
    %orig;
}

%end




%group SwiftHooks
%hook SwiftSundialPlaceholderClass

- (id)objectsForListAdapter:(id)arg1 {
    NSArray *original_feed = %orig;
    NSMutableArray *filtered_feed = [NSMutableArray array];
    for (id item in original_feed) {
        if ([item isKindOfClass:%c(IGAdItem)]) {
            NSLog(@"[IGAdBlock] Swift Reel ad removed.");
            continue;
        }
        [filtered_feed addObject:item];
    }
    return filtered_feed;
}

%end
%end


%group TestFlightNagHooks
%hook TestFlightNagPlaceholderClass

- (void)viewDidAppear:(BOOL)animated {
    %orig;
    
    // Dismiss the view controller immediately when it shows up
    [(UIViewController *)self dismissViewControllerAnimated:YES completion:nil];
    
    NSLog(@"[IGAdBlock] TestFlight update nudge bypassed successfully!");
}

%end
%end





%ctor {
    %init;


	Class swiftSundialClass = objc_getClass("IGSundialFeed.IGSundialFeedDataSource");
    if (swiftSundialClass) {
        // Map the placeholder hook name to the actual runtime class pointer
        %init(SwiftHooks, SwiftSundialPlaceholderClass = swiftSundialClass);
        NSLog(@"[IGAdBlock] Successfully initialized Swift hooks.");
    } else {
        NSLog(@"[IGAdBlock] Warning: Could not find Swift class at runtime.");
    }




	Class nagClass = objc_getClass("IGCoreRootTestFlightNagPlugin.TestFlightUpdateNudgeViewController");
    if (nagClass) {
        %init(TestFlightNagHooks, TestFlightNagPlaceholderClass = nagClass);
        NSLog(@"[IGAdBlock] Found and hooked TestFlight Nag Controller.");
    } else {
        NSLog(@"[IGAdBlock] Could not find TestFlight Nag Controller class.");
    }
}
