#!/bin/bash
# Script to automatically build and deploy project to an rclone directory 
# Requires the following commands: rclone, 7z, tar
# Also requires path to godot client, preferrably headless. This needs to be changed to match your configuration. 

print_usage()
{
	echo "Usage: $0 [-w for windows | -l for linux]"
}

build_linux()
{
	echo Cleaning up Linux bin folder...
	mkdir -p bin/linux
	rm -f bin/linux/*

	echo Building Linux...
	/opt/godot-headless --quiet --export "Linux/X11" bin/linux/dungeon_masters.x86_64
	
	echo Archiving Linux...
	tar cfJ bin/linux/linux.tar.xz -C bin/linux/ dungeon_masters.x86_64 dungeon_masters.pck
	
	echo Uploading Linux...
	rclone copy --update bin/linux/linux.tar.xz google-drive:"Dungeon Masters/bin"
}

build_windows()
{
	echo Cleaning up Windows bin folder...
	mkdir -p bin/windows
	rm -f bin/windows/*

	echo Building Windows...
	/opt/godot-headless --quiet --export "Windows Desktop" bin/windows/dungeon_masters.exe

	echo Archiving Windows...
	7z a bin/windows/windows.7z bin/windows/dungeon_masters.exe bin/windows/dungeon_masters.pck > /dev/null

	echo Uploading Windows...
	rclone copy --update bin/windows/windows.7z google-drive:"Dungeon Masters/bin"
}

# Check prerequisites

if ! command -v rclone >/dev/null 2>&1; then
	echo "ERROR: Missing package: rclone"
	exit 1
fi

if ! command -v 7z >/dev/null 2>&1; then
	echo "ERROR: Missing package: 7z"
	exit 1
fi

if ! command -v tar >/dev/null 2>&1; then
	echo "ERROR: Missing package: tar"
	exit 1
fi

if [ ! -f "project.godot" ]; then
	echo "ERROR: Script must be run from a directory containing a project.godot file"
	exit 1
fi

# A POSIX variable
OPTIND=1        # Reset in case getopts has been used previously in the shell.

while getopts "wlh" opt; do
	case "${opt}" in
		w)
			build_windows
			;;
		l)	
			build_linux
			;;
		h)
			print_usage
			exit 0
			;;
		*)
			print_usage >&2
			exit 1
			;;
	esac
done

# Remove just flags processed from $@
shift $((OPTIND-1))

# If no arguments passed
if [ $OPTIND -eq 1 ]; then 
	print_usage >&2
	exit 1
fi

echo Done.
