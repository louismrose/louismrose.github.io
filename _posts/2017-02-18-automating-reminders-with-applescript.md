---
layout: post
title: Automating Reminders with AppleScript
---

Occasionally, I need to provision a complete replica of our AWS production to get my work done. As you might imagine, this incurs a fairly hefty hourly charge and we try to avoid running this setup for any longer than necessary. Although I've tried to develop the habit of checking the AWS consoles before heading home for the day, I sometimes forget. We then run a completely unused production stack overnight, wasting a whole bunch of money and resources.

Automatically shutting down the replica every evening seemed like the obvious solution. But the trouble is that sometimes I *do* want to run the stack for a couple of extra hours or even overnight whilst a long-running test finishes.

And then it occurred to me: perhaps I should adapt my provisioning script to also create a task in Apple's Reminders app.

Here's the code:

```applescript
# add_teardown_reminder.applescript

tell application "Reminders"

  # Calculate date time for midnight today
  set currentDay to (current date) - (time of (current date))
  # Calculate date time for 1700 today
  set theDate to currentDay + (17 * hours)

  # Select the relevant list in Reminders.app
  set myList to list "Work"

  tell myList
    # Create the reminder
    set newReminder to make new reminder
    set name of newReminder to "Teardown test servers"
    set remind me date of newReminder to theDate
  end tell
end tell
```

This script calculates a date time for today at midnight, adds 17 hours to get a due date of "5pm today" and then adds the task to the Work list in Reminders.app. Running the script from a shell script is simple:

```bash
osascript add_teardown_reminder.applescript
```

I'd not dabbled with AppleScript very much before, but getting this done took around 10 minutes. The "Open Dictionary" tool in Apple's Script Editor is an excellent way to explore the APIs provided by Reminders.app (and other applications), and I picked up a few tips from [Federico Viticci](https://www.macstories.net/tutorials/enhancing-reminders-with-applescript-and-macros/).

Best of all, our AWS account won't be wasting midnight oil anymore.
