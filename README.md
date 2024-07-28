# game-scripts
Scripts relating to dedicated server installation and configuration.

# Soulmask Delete and Backup
Soulmask saves files every 10 minutes, however does not have any action for leansing the old files.  This can cause your folder to grow very quickly.  My Server sees about 6-10 gb per day.  

This script will do two things.
1. Remove any files that have not been edited within your limit.  I keep 2 days.  Edited is an important distinction as the main save for soulmask is created when you first start, then constantly edited.  It's never regenerated.
2. Backup files in your path as well.  This will create a zip file for the world save of all the detail in the saves folder and then place it where you specify in the path.

I set this to run on a timer using scheduled tasks.  

# Creating the Scheudled tasks
Coming Soon
