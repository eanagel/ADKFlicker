# ADKFlicker #


A sample application that reproduces some weird flickering in AsyncDisplayKit's `ASTableView` cells. You can see an example of the problem in this [video](ADKFlicker-demo.mp4).

Requires a special version of AsyncDisplayKit (located [here](https://github.com/eanagel/AsyncDisplayKit/tree/ADKFlicker)) that is the [current master](https://github.com/facebook/AsyncDisplayKit/tree/f248dbddd1eb3de559b2ec3b9397d2f218ffe6af) with the following pull requests merged in:

 - [Allow ASTableView to be loaded in a xib/storyboard](https://github.com/facebook/AsyncDisplayKit/pull/443) - So I don't have to deal with autolayout in code ;)

 - [Bug Fix - ASTableView sometimes fails to render cell contents when scrolling programmatically.](https://github.com/facebook/AsyncDisplayKit/pull/430) - Without this PR new cells are (almost) always blank, try removing it to see the effect.
 

## Steps to Build ##

Pull the repo and run `pod update`


## Steps to Reproduce ##

Ok, once you reproduce you'll know it, because things start acting real weird!

1. Run the app in the simulator and enable slow animations. Make sure the keyboard is hidden so you can type while seeing the whole screen. (You'll be entering text and I don't resize the screen for the keyboard.)
2. Select the "type something!" text box and enter a few messages in rapid succession.
3. Do this a couple times and you will notice the red and green cells will begin overlapping each other while animations are active.
4. If can manage to grab the View Heirarchy while the animations are happening you see some weird stuff, including a `UIView` at the same level as the `UITableViewCellContentView`. I assume this is a normal part of the cell's animation lifecycle (you don't see them when animations aren't in flight.) At times the frames of the cells seem to be just wrong DURING the animation, but they are correct after the animation completes.

## Thoughts ##

 - This does seem like some kind of race condition. Maybe it happens when multiple animations are in flight at the same time? I'm not sure here.
 
 - It does seem to have to do with cell reuse somehow as well. If you disable cell reuse by tweaking ASTableView.mm around line #335 the problem will go away. I wonder if somehow we are updating (rendering to) the wrong cells while multiple animations are in flight? Is that possible somehow?

 - The code I have to scroll to the end of the content seems to scroll backwards when multiple insertion animations are active which is odd. Additionally, if you disable animated scrolling (`setContentOffset:animated:NO`) you don't see the problem anymore, but I'm not sure if this is actually fixing the problem or just hiding it since there are no longer slow animations involved to make it so easy to see the issue (there does seem to be flicker without the animation.) To be safe I added code to prevent calls to `setContentOffset` while animating a previous one. This didn't improve things :(
 
 - I'm probably just doing some really stupid here. Good news I was able to reproduce it in an isolated code base!
 

