#!/bin/bash

################################################################################
#### Start multiple instannces of rclone http serve for use with a reverse #####
#### proxy webserver.                                                      #####
################################################################################
#							      ___           ___           ___                            #
#							     /  /\         /__/\         /  /\                           #
#							    /  /::\       |  |::\       /  /:/_                          #
#							   /  /:/\:\      |  |:|:\     /  /:/ /\                         #
#							  /  /:/  \:\   __|__|:|\:\   /  /:/_/::\                        #
#							 /__/:/ \__\:\ /__/::::| \:\ /__/:/__\/\:\                       #
#							 \  \:\ /  /:/ \  \:\~~\__\/ \  \:\ /~~/:/                       #
#							  \  \:\  /:/   \  \:\        \  \:\  /:/                        #
#							   \  \:\/:/     \  \:\        \  \:\/:/                         #
#							    \  \::/       \  \:\        \  \::/                          #
#							     \__\/         \__\/         \__\/                           #
#                                                                              #
################################################################################
#### rclone credit        : https://github.com/ncw/rclone
###  Install rclone       : https://rclone.org/install/
###  Install rclone       : "brew install rclone"

#### GNU parallel credit  : https://www.gnu.org/software/parallel/
###  Install GNU parallel : "sudo apt-get install parallel"
###  Install GNU parallel : "brew install parallel"
################################################################################

# path to your file containing the acounts you want to use.
ACCOUNTS="$HOME/scripts/pegasus.txt"

# path to your file containing the ports you want to use.
PORTS="$HOME/scripts/ports.txt"

rcloneARGS=(
  "--stats=30s"
  "--read-only"
  "--fast-list"
  "-vv"
  "--log-file=${HOME}/logs/alexandria.log"
)

parallelARGS=(
  "--link"
  "--jobs=12"
  "--delay=3"
  "--joblog=alexandria-parallel.log"
  "-X"
)

# Remove existing accounts file.
rm -rf "$ACCOUNTS"

# Remove existing ports file.
rm -rf "$PORTS"

# My rclone remotes are named so that I can grep the Teamdrive name from
# multiple accounts and pipe them to the accounts file. You may need to create
# your own accounts.txt file manually if your remotes are not setup in this way.
 rclone listremotes | grep TDpegasus >>"$ACCOUNTS"

# generating ports file. Since I have 12 remotes to start, this ports file will
# create 12 ports in sequence. If you have a different amout of remotes to use,
# modify "10033".

i=$(wc -l <"$ACCOUNTS")
for i in 1000{1..9} 100{10..99} ; do
  echo $i >"$PORTS"
done
#seq 10000 +1 10033 >>"$PORTS"


# create initial logfile.
touch "${HOME}/logs/alexandria.log"

# start rclone serve http remotes in a staggered fashion.
echo parallel "${parallelARGS[@]}" rclone serve http {1}alexandria-library.space \
--addr localhost:{2} "${rcloneARGS[@]}" :::: "$ACCOUNTS" "$PORTS"
echo "Alexandria started"
