#!/bin/bash
#
#	----------------------------------------------------------------------------
#	Dynamic IPSet Refresh Script
#	============================================================================
#	Created:       2025-03-30, by Weasel.SteamID.155@gMail.com        
#	Last modified: 2026-02-16, by Weasel.SteamID.155@gMail.com
#	----------------------------------------------------------------------------
#
#	Purpose:
#	=======
#
#	Creates or updates an IPSet defined by variables below, and
#	looks for a two-column text file with a matching name.
#
#	That IPSet may then be used in Iptables firewall rules.
#
#	Notes:
#	=====
#
#	* Requires IPTables is installed (sudo apt-get install -y iptables;)
#	* Requires that IPSet is installed (sudo apt-get install -y ipset;)
#	* Requires Tail is installed (probably already is), part of "CoreUtils" (sudo apt-get install -y coreutils;)
#	* Requires WDiff is installed (sudo apt-get install -y wdiff;)
#	* Requires XArgs is installed, typically part of "FindUtils" (sudo apt-get install -y findutils;)
#
#	Preparation:
#	===========
#
#	1.	In the same folder as this script, create a text file (see variable below for naming).
#	2.	Populate that text file with sources you wish to automatically update, one-per-line.  For example:
#
#	NOTE:
#		You may optionally have two (TAB-seperated) columns.
#		If so, the second column is for descriptions/comments, and its contents will be ignored.
#		If you wish, you may also use individual IP addresses (###.###.###.###) in the same file.
#		If you wish, you may also use IP addresses blocks (###.###.###.###/##) in the same file.
#		
#        	something1.example.com	some optional description 1
#         	something2.example.com	some optional description 2
#         	something3.example.com	some optional description 3
#         	192.168.187.187	some optional description 4
#         	192.168.187/24	some optional description 4
#
#	3.	Run this script to create/update an "ipset" (see variable below for naming)
#	4.	In your IPTables setup, create a new set of rules allowing what ports/protocols
#		you wish to permit - however, instead of specifying a static IP address, use the
#		option to specify the ipset named matching the variable defined below.
#	5.	Schedule this script to run periodically (maybe at the top of every hour? or more often?).
#
#	Do it ...
#	=====
#
#	Define some variables, and ensure folders exist ...
#	-----------------------------------------------
#
LIST_NAME="blacklist";		#	This will be used as a base for naming text and temp files.
IPSET_NAME="BLACKLIST";		#	This will be used for the name of the IPSet, use it in your IPTables rules.
SCRIPTS_FOLDER="/root/scripts";	#	Ensure this reflects where the script will be installed/executed-from.
LOG_FOLDER="/root/logs";		#	Ensure this reflects where the script will write various logs to.
TEMP_FOLDER="/root/tempwork";	#	Ensure this reflects where the script will write various logs to.
mkdir $SCRIPTS_FOLDER > /dev/null 2>&1;
mkdir $LOG_FOLDER > /dev/null 2>&1;
mkdir $TEMP_FOLDER > /dev/null 2>&1;
LOG_FILE="$LOG_FOLDER/$LIST_NAME-refresh-action.log";
LIST_ENTRIES_FILE="$SCRIPTS_FOLDER/$LIST_NAME-entries.txt";
LIST_CUT_FILE="$TEMP_FOLDER/$LIST_NAME-cut-temp.txt";
#
#	Display some stuff ...
#	------------------
#
echo -e "+-----------------------------------------------------------------------------+";
echo -e "Begin IPSet Refresh at $(date)";
echo -e "+-----------------------------------------------------------------------------+";
echo -e "";
echo -e "Current IPTables Details:"
echo -e "------------------------";
sudo iptables -L;
echo -e "";
echo -e "Previous IPSet Details:"
echo -e "----------------------";
sudo ipset list $IPSET_NAME;
ipsetbefore=$(sudo ipset list $IPSET_NAME | tail -n +7);
echo -e "";
#
#	Perform various tasks ...
#
echo -e "Performing various tasks:"
echo -e "------------------------";
#
#	Change to the scripts directory ...
#	-------------------------------
#
echo -e "Changing to the scripts directory ...";
cd $SCRIPTS_FOLDER > /dev/null 2>&1;
#
#	Ensure the IPSet exists ...
#	-----------------------
#
echo -e "Ensuring the IPSet exists ...";
ipset -N $IPSET_NAME nethash > /dev/null 2>&1;
#
#	Temporarily clearing the IPSet ...
#	------------------------------
#
echo -e "Temporarily clearing the IPSet ...";
ipset -F $IPSET_NAME > /dev/null 2>&1;
#
#	Rebuilding the IPSet ...
#	--------------------
#
echo -e "Rebuilding the IPSet (from $LIST_ENTRIES_FILE) ...";
cut -f1 $LIST_ENTRIES_FILE > $LIST_CUT_FILE;
xargs < $LIST_CUT_FILE -I listentry sudo ipset add $IPSET_NAME listentry > /dev/null 2>&1;
echo -e "Removing the temp file ($LIST_CUT_FILE) ...";
rm $LIST_CUT_FILE > /dev/null 2>&1;
echo -e "";
echo -e "Updated IPSet Details:"
echo -e "---------------------";
ipset list $IPSET_NAME;
ipsetafter=$(sudo ipset list $IPSET_NAME | tail -n +7);
#
#	If there was a change, display a notice and log the change ...
#
echo -e "";
echo -e "Effective IPSet Status:"
echo -e "----------------------";
if [ "$ipsetafter" == "$ipsetbefore" ]; then
		echo -e "No change to IPSet detected.";
        echo -e "";
	else
		echo -e "Change to IPSet detected, at $(date)";
        echo -e "Change to IPSet detected, at $(date):" >> $LOG_FILE;
		wdiff <(echo "$ipsetbefore") <(echo "$ipsetafter");
		wdiff <(echo "$ipsetbefore") <(echo "$ipsetafter") >> $LOG_FILE;
        echo -e "";
        echo -e "" >> $LOG_FILE;
fi;
#
#	Display some stuff ...
#	------------------
#
echo -e "+-----------------------------------------------------------------------------+";
echo -e "IPSet Refresh Completed at $(date)";
echo -e "+-----------------------------------------------------------------------------+";
#
#   That's all folks!
#
