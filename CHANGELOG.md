# Changelog

This document lists user-visible changes made to WebNews along with the date they were deployed to the CSH production server. "Invisible" changes such as refactoring or updating dependencies are not listed &ndash; see the commit history for those.

## 2014-06-02

* The web interface has gotten a liberal sprinkling of icons to make buttons more distinguishable, replace some old non-vector images, and generally pretty things up.

* The post view now wraps at about 100 characters wide, regardless of whether reading mode is enabled. This should make things more tolerable for those with maximized 1920-pixel-wide browsers.

* Newsgroup names are now abbreviated in some places to emphasize the part of the name you actually care about. This includes the activity feed, whose layout has been tweaked a bit.

* WebNews can now both read and post Unicode author and subject lines. (previously these were shown as "=?utf-8?b?..." when posted by other clients, and WebNews itself would strip non-ASCII characters before posting)

* WebNews is now slightly better at guessing which thread to put de-threaded mailing list posts under.

* Fixed a configuration issue causing emails to not be sent at all since the most recent server move. The fact that no one reported this is kind of frightening...

* Fixed a condition where some replies could become invisible/un-selectable in the threaded view, only accessible from the activity feed or the flat view.

## 2013-10-07

### API Changes

* The user profile method now returns an `is_admin` attribute. This can be used to conditionally hide admin-only functionality (sticky threads, canceling others' posts) or give the user visual confirmation that they are an admin, as with the orange badge in the web interface.

## 2013-09-22

* Fixed an issue that was preventing email notifications and digests from going out, and causing error pop-ups when posting (thanks @jeid64 and @clockfort for bringing it to my attention)

* Fixed an issue where posts marked as unread in control.cancel would be stuck that way forever

* Truncated author names on the activity dashboard to prevent certain unnamed joke-explainers from breaking the layout

## 2013-06-08

* It's now possible to receive both notifications *and* digests for the same newsgroup (or globally). For instance, you can receive immediate notifications for any replies to your posts, and also receive a weekly digest of all posts.

## 2013-05-22

* WebNews now has email notifications and digests, configurable in the Settings dialog. Note the default settings are applied to all newsgroups unless overridden, all digests are sent at 1am, and the weekly digest treats Monday (rather than Sunday) as the start of the week.

## 2012-12-04

* WebNews now supports multiple color schemes, selectable in the Settings dialog. Currently two are available: Classic (the existing one) and Sublime (a new light-on-dark color scheme).

* The activity feed on the Home page has gained some time-based visual chunking.

* Threads can now be marked read directly from the activity feed by clicking the "Mark Read..." button at the upper right.

* The posting dialog now shrinks vertically to fit the browser window if it is too tall.

### API Changes

* **GET /activity** now returns both `personal_class` and `unread_class` properties for each activity entry. Previously only `personal_class` was returned, and its value would be either the unread class or personal class of the thread, depending on whether it contained any unread posts.

## 2012-11-26

* WebNews now has Gravatar integration (with code contributed by @clockfort). The newly reorganized Settings dialog provides an easy link to Gravatar so you can change the image associated with your email address.

* Admins can now sticky a post directly from the new post dialog.

* Search now has an "original posts" filter, if you don't want replies cluttering up your search results.

### API Changes

* **POST /compose** now accepts an optional `sticky_until` parameter

* **GET /search** now accepts an optional `original` parameter

## 2012-11-05

* The post view now features a "Reading Mode" toggle in the lower-right corner that expands the post to fill the window, bumps the font size, and sets a comfortable maximum width. The hotkey for this toggle is `d`.

* Clicking "Post Reply" (or pressing `r`) while you have text selected will now quote only that text in your reply. Note that the quoted text will always be attributed (via the "<name> wrote:" line) to the author of the post you are replying to, even if the text you select is inside a quote that is attributed to someone else. So don't do that.

* Dialog hotkeys have been changed slightly. Previously, `Esc` and `Alt`+`q` both had the same function, which was to cancel/close any open dialog or abandon any open draft. Now, `Esc` still cancels/closes open dialogs, but will minimize open drafts instead of abandoning them. `Alt`+`q` is now reserved for explicitly discarding a draft. (`Esc` outside of a dialog still brings you to the Home screen)

* Posts made from WebNews now contain an X-WebNews-Posting-Host header indicating the "real" source of the message, since the NNTP-Posting-Host header that normally serves this function is always the address of the web server.

### API Changes

* **GET /compose** now accepts optional numeric `quote_start` and `quote_length` parameters.

* **POST /compose** and **DELETE /:newsgroup/:number** now accept an optional `posting_host` parameter.

## 2012-10-22

This update introduces Dashboard Redesign MkII. The new activity feed layout is more compact and loads much faster, but now has a hard limit on how many threads are displayed; it no longer shows *all* threads in which you have unread posts, nor does it necessarily go all the way out to 7 days ago.

Other changes in this update:

* Hotkey change: "Show/hide headers" is now `h` instead of `d`. "Home", which was previously bound to both `h` and `Esc`, is now just `Esc`.

* The data format returned by the API method **GET /activity** has changed to reflect the new activity feed format. Check the [API documentation](https://github.com/grantovich/CSH-WebNews/wiki/API) for the new spec (note this method is still marked "subject to change").

### API Changes

* Methods that return a `personal_class` value will now always have it set to `null` if there is no applicable class. (previously, some methods used null to indicate this, and others used an empty string)

## 2012-10-08

* Your username in the upper-right now links to a search for all posts you've made

* Added a confirmation when submitting a blank post (i.e. no body text)

* Fixed odd auto-quote behavior when replying to a blank post

* Fixed a case where using hotkeys could result in an unintentional double-post

## 2012-09-01

* The WebNews API has landed! [Read all about it here](https://github.com/grantovich/CSH-WebNews/wiki/API).

* The Search dialog now allows searching for multiple authors, consequently allowing the "Posts" button next to the author line to work more reliably.

* The Settings dialog now offers several options to control when new posts are marked unread: Always (the default), Only in threads you've posted in, Only direct replies to your posts, and Never. I added these primarily with alumni in mind; finer-grained options that will be more useful for current members are coming in the future.

* Any search query can now be turned into an RSS feed by clicking the icon at the upper-right of the search results. Note this requires you to enable API access and uses your API key in the feed URL (just like any other API call), so be careful what you do with it. [Read more here](https://github.com/grantovich/CSH-WebNews/wiki/RSS).

## 2012-05-23

* In further pursuit of chewing up all available CPU all the time, WebNews now syncs with the news server on a once-per-minute cronjob (previously it used a "lazy" request-based model). The upside is that initial load times will be snappier, and you'll experience fewer random navigation delays throughout the app.

* Navigating through newsgroups or threads with hotkeys now actually performs well. Hold down `j` with impunity!

* Search keywords are now correctly ANDed instead of being ORed.

* The dashboard no longer steals keyboard focus from dialogs.

## 2012-05-05

* Starred posts! Similar to Gmail, you can now "star" posts you find especially interesting, hilarious, epic, etc. so you can easily find them later. Just click on the star button in the post toolbar, or press `s`. To view all your starred posts, click the "Starred" button in the main toolbar, or press `Shift`+`s`. There is also a new "only search starred" checkbox in the Search dialog.

* Mark Thread Read! This new button in the newsgroup toolbar will "mark read" all posts in the same thread as the post you have selected. The hotkey is `Shift`+`i`.

* Hotkey shuffling! Many hotkeys have been changed or added. As usual the About dialog (hotkey `?`) has the full list, but here's what's different:
  * Home is now `Esc` as well as `h` (`Esc` in a dialog still closes/cancels it)
  * Search is now `/`, was previously `s`
  * Settings is now `~`, was previously `t`
  * New "mark thread read" button is `Shift`+`i`
  * "Mark newsgroup read" is now `Alt`+`i`, was previously `Shift`+`r`
  * "Mark everything read" is now `Alt`+`Shift`+`i`, was previously `Alt`+`r`
  * Post New is now `c`, was previously `p`
  * New "star/unstar" button is `s`
  * Sticky is now `t`, was previously `i`
  * Cancel is now `#`, was previously `c`
  * View in Newsgroup (from search results) is now `v`, previously had no hotkey

## 2012-04-01

* Cross-posting is now accessible to non-admins

* Hotkeys no longer fire incorrectly when holding down Ctrl

## 2012-03-04

This update officially introduces "Admin" privileges, which are now extended to both RTPs and EBoard members (as determined by the user's Unix groups). If you are an Admin, you'll see an orange badge next to your name in the upper-right. You'll also see orange-bordered buttons elsewhere in WebNews, indicating functions that require Admin privileges. Currently these are:

* Admins can cancel any post that has no replies, even if they are not the original poster. This can be used to clean up spam or duplicate posts.

* Admins can set threads as "sticky" for a specified time period, which pins them to the top of the activity feed and gives them a highlighted background. Note that you must have the original post in a thread selected to see the Sticky button. The hotkey for this function is `i`.

Additional changes included in this update:

* Added limited cross-posting support. This feature is very lightly tested and currently only available to Admins, though the UI doesn't indicate this. In the New Post dialog, click the "Cross-post..." button to expand the cross-post options.

* The Post Reply dialog now displays a link back to the post you are replying to.

* More UI tweaks to the post view header (it now behaves the same as the newsgroup header).

## 2012-02-18

* Minor performance and responsiveness improvements, see issue #50

* Made the Next Unread order more intuitive in threaded mode (it now takes a depth-first approach, making it better at following conversations)

* Miscellaneous UI tweaks

* Initial work on user roles: RTPs now get an "Admin" badge, though they can't actually do anything special yet

## 2012-01-22

* Footnote-style URL references in posts are now auto-linked. This is a common convention for plain text messages that has been spotted on news occasionally, so it makes sense to "officially" support it as a way of inserting long URLs into posts (plus there's no real degradation for non-WebNews users).

## 2012-01-14

* It's now possible to develop and test WebNews "standalone", without a Webauth setup.

## 2011-12-26

* Posts can now be marked unread, either by clicking the Mark Unread button in the post view, or pressing the hotkey `u`. WebNews internally distinguishes between regular unread posts and posts that you've explicitly marked as unread, and pushes the latter to the end of the Next Unread sequence (i.e. Next Unread will only take you to a marked-as-unread post if you have no more regular unread posts left).

## 2011-12-16

* Just in time for the holidays: It's the Hotkey Update! For those who don't trust all these new-fangled "mice", WebNews can now be navigated entirely from your keyboard. All available shortcuts are listed in the About dialog: Click the "?" in the corner, or hit the `/` key! My favorite, and probably the one that most people will want to use, is `n` for Next Unread.

* Made a tweak to the quote collapsing feature: "Short" quotes (arbitrarily defined as those containing 8 line breaks or less) will never be collapsed, even if they otherwise would be.

## 2011-11-27

* WebNews now has a quote collapsing feature. If a reply quotes the entire text of the original post unaltered (ignoring signatures), the quote will be collapsed into a "Show quoted text" button. This currently only applies when using the default Threaded display mode.

## 2011-11-26

* Dashboard overhaul! The activity feed has been redesigned and split in two, giving you more information and a much better overview of your unread posts and threads. Also, the dashboard will now use all available vertical space.

* Fixed author profile links not using the correct URL since Profiles2 was moved back to the "official" profiles location

* Fixed a bug where threads containing unread posts would sometimes fail to auto-expand

* Threads can now be expanded or collapsed without selecting them, by clicking directly on the expando-triangle (the background color changes on hover)

* The post importer now correctly handles HTML emails with attachments; as a result, several posts in csh.lists.sysadmin that previously appeared corrupted in WebNews are now displayed properly

## 2011-10-25

* Added an explanatory message to the authentication page to help out Chrome users (and maybe others?) who haven't installed the certificate

* Slightly rearranged the newsgroup list and added some visual dividers

* Removed the "open links in new tab" preference, since literally no one ever changed it from the default; also made the open-in-new-tab behavior more consistent throughout the interface

* Users who haven't accessed WebNews in three months will now have their unread posts cleared, and will stop accumulating unread posts until the next time they log in (mostly to avoid unbounded database growth)

## 2011-10-13

* Added alternate "Flat" and "Hybrid" message views, in addition to the normal threaded view. Change your preference in the Settings dialog.

* When viewing a cross-post, instances of the post in other newsgroups will also be marked as read. (thanks @clockfort)

* Made another attempt at fixing the "infinite refresh" bug (thanks @agargiulo for providing data). If you are still encountering this, and clearing your browser cache doesn't fix it, please let me know in issue #33

## 2011-10-04

* Next Unread now works more intuitively: It will "stick" to the thread and/or newsgroup you're currently viewing, avoiding unnecessary jumps

* Backend improvements that should result in slightly better performance

* Several bug fixes (most notably, Next Unread will no longer randomly stop working)

## 2011-09-27

* Clicking "Mark All Read" while on the home page no longer forces a dashboard reload

* Added a proper error message for when your Webauth token expires and you need to re-authenticate

* Viewing non-recent posts by accessing the URL directly or clicking "View in Thread" from search results will no longer cause the thread view to get stuck loading for a long time (as fun as it was to load a flame post from 2005 and drive up the server's load average for ten minutes)

## 2011-09-18

* Removed "Beta" tag

* Posts can now be searched using various criteria

* Profiles/wiki page links now appear next to the author line for CSH accounts

## 2011-09-04

* External linking to posts is now supported: You can access a link like https://webnews.csh.rit.edu/#!/csh.general/18595 from anywhere, even if you're not already signed into Webauth, and it will still work correctly.

## 2011-08-25

* Cross-posts are now handled properly. Replying to a cross-post will send the reply to the correct Followup-To newsgroup, and cross-posts no longer show up multiple times in the activity feed. Each "instance" of a cross-post also displays a notification linking to the instances in other newsgroups. (Creating cross-posts is still not supported, but may be in a future release)

* Post canceling has been implemented. Only your own posts can be canceled, and only if they have no replies yet. Canceled posts are removed from WebNews immediately; the cancel dialog explains the consequences for other clients and the mailing lists.

* A basic "draft" feature has been added, using HTML5 local storage. Drafts are saved automatically and continuously, similar to Gmail. The new "Minimize" button in the post dialog and "Resume Draft" button in the main toolbar allow you to write a post while looking up quotes or information elsewhere on news. Plus, now your post-in-progress won't be lost if your browser crashes, your battery dies, or you accidentally close the tab or navigate away from WebNews.

* WebNews is now more tolerant of flaky connections, and can recover from connection failures automatically without a manual refresh. Error handling in general has also been improved, and error messages are more explanatory when they do occur.

## 2011-08-12

* Fixed several browser-specific CSS alignment issues

* Consolidated/improved home page activity feed

* Added global and newsgroup-specific "Mark All Read" buttons

* Home page now puts your unread post count in the page title

* Added "About" dialog with useful links and information

* External links in posts now open in a new window/tab by default (can be turned off in Settings)

## 2011-08-10

* First publicly-accessible version, branded "WebNews Beta"
