#!/bin/bash
#
# Script to generate Spotlight database test files
# Requires MacOS

EXIT_SUCCESS=0
EXIT_FAILURE=1

# Checks the availability of a binary and exits if not available.
#
# Arguments:
#   a string containing the name of the binary
#
assert_availability_binary()
{
	local BINARY=$1

	which ${BINARY} > /dev/null 2>&1
	if test $? -ne ${EXIT_SUCCESS}
	then
		echo "Missing binary: ${BINARY}"
		echo ""

		exit ${EXIT_FAILURE}
	fi
}

assert_availability_binary diskutil
assert_availability_binary hdiutil
assert_availability_binary mdutil
assert_availability_binary sw_vers

MACOS_VERSION=`sw_vers -productVersion`
SHORT_VERSION=`echo "${MACOS_VERSION}" | sed 's/^\([0-9][0-9]*[.][0-9][0-9]*\).*$/\1/'`

SPECIMENS_PATH="specimens/${MACOS_VERSION}"

if test -d ${SPECIMENS_PATH}
then
	echo "Specimens directory: ${SPECIMENS_PATH} already exists."

	exit ${EXIT_FAILURE}
fi

mkdir -p ${SPECIMENS_PATH}

set -e

DEVICE_NUMBER=`diskutil list | grep -e '^/dev/disk' | tail -n 1 | sed 's?^/dev/disk??;s? .*$??'`

VOLUME_DEVICE_NUMBER=$(( ${DEVICE_NUMBER} + 1 ))

IMAGE_FILE="${SPECIMENS_PATH}/hfsplus"

# Create raw disk image with a case-insensitive HFS+ file system
hdiutil create -fs 'HFS+' -size "64M" -type UDIF -volname TestVolume "${IMAGE_FILE}"

hdiutil attach ${IMAGE_FILE}.dmg

VOLUME_PATH="/Volumes/TestVolume"

# Copy file of different types to the volume.
cp LICENSE ${VOLUME_PATH}

# TODO: add more test files.

# Turn on Spotlight indexing on the volume.
mdutil -i on ${VOLUME_PATH}

# Sleep so that Spotlight has some time to index the files on the volume.
sleep 5

# Capture Spotlight VolumeConfig.plist.
sudo mdutil -P ${VOLUME_PATH} > ${SPECIMENS_PATH}/hfsplus.VolumeConfig.plist

# Capture Spotlight metadata attributes about files.
mdls ${VOLUME_PATH}/LICENSE > ${SPECIMENS_PATH}/LICENSE.mdls

# Sleep to prevent "resource busy" warning.
sleep 3

hdiutil detach disk${VOLUME_DEVICE_NUMBER}

exit ${EXIT_SUCCESS}
