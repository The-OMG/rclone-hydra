#!/bin/sh

################################################################################
#### Start multiple instances of rclone http serve for use with a reverse  #####
#### proxy webserver.                                                      #####
################################################################################
#                   ___           ___           ___                            #
#                  /  /\         /__/\         /  /\                           #
#                 /  /::\       |  |::\       /  /:/_                          #
#                /  /:/\:\      |  |:|:\     /  /:/ /\                         #
#               /  /:/  \:\   __|__|:|\:\   /  /:/_/::\                        #
#              /__/:/ \__\:\ /__/::::| \:\ /__/:/__\/\:\                       #
#              \  \:\ /  /:/ \  \:\~~\__\/ \  \:\ /~~/:/                       #
#               \  \:\  /:/   \  \:\        \  \:\  /:/                        #
#                \  \:\/:/     \  \:\        \  \:\/:/                         #
#                 \  \::/       \  \:\        \  \::/                          #
#                  \__\/         \__\/         \__\/                           #
#                                                                              #
################################################################################
#### rclone credit        : https://github.com/ncw/rclone
###  Install rclone       : https://rclone.org/install/
###  Install rclone       : "brew install rclone"

#### GNU parallel credit  : https://www.gnu.org/software/parallel/
###  Install GNU parallel : "sudo apt-get install parallel"
###  Install GNU parallel : "brew install parallel"
################################################################################

_Main() {

  TEAMDRIVE_TO_SERVE="TDcartoons-matt07211"

  # My rclone remotes are named so that I can grep the Teamdrive name from
  # multiple accounts and pipe them to the accounts file. You may need to create
  # your own accounts.txt file manually if your remotes are not setup in this way.
  ACCOUNTS=$(rclone listremotes | grep ${TEAMDRIVE_TO_SERVE})
  ACCOUNT_COUNT=$(rclone listremotes | grep -c ${TEAMDRIVE_TO_SERVE})

  PORTS=$(seq 10001 +1 100${ACCOUNT_COUNT})

  # create initial logfile.
  echo "" "$HOME/logs/rclone-hydra.log"

  # Calculate best chunksize for trasnfer speed.
  AvailableRam=$(free --giga -w | grep Mem | awk '{print $8}')
  case "$AvailableRam" in
  [1-9][0-9] | [1-9][0-9][0-9]) driveChunkSize="1024M" ;;
  [6-9]) driveChunkSize="512M" ;;
  5) driveChunkSize="256M" ;;
  4) driveChunkSize="128M" ;;
  3) driveChunkSize="64M" ;;
  2) driveChunkSize="32M" ;;
  [0-1]) driveChunkSize="8M" ;;
  esac

  rcloneARGS="--buffer-size=0M \
--cache-chunk-size=10M \
--cache-db-path=$HOME/.cache/rclone/.rcache \
--cache-info-age=10m \
--cache-total-chunk-size=10G \
--cache-workers=8 \
--cache-writes \
--dir-cache-time=4m \
--drive-chunk-size=${driveChunkSize} \
--drive-upload-cutoff=${driveChunkSize} \
--fast-list \
--low-level-retries=10 \
--min-size=0 \
--no-check-certificate \
--read-only \
--retries=3 \
--stats=10s \
--stats=30s \
--timeout=300s \
--tpslimit=6 \
--umask=002 \
-vv"

  parallelARGS="--jobs=${ACCOUNT_COUNT} --link -x"

  # start rclone serve http remotes in a staggered fashion.
  parallel ${parallelARGS} \
    "rclone serve http {1} --addr localhost:{2} ${rcloneARGS}" \
    ::: "${ACCOUNTS}" \
    ::: "${PORTS}"
}
_Main @
