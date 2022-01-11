#!/bin/bash

##################################################################
# Created by Christian Haitian for use to easily update          #
# various standalone emulators, libretro cores, and other        #
# various programs for the RK3326 platform for various Linux     #
# based distributions.                                           #
# See the LICENSE.md file at the top-level directory of this     #
# repository.                                                    #
##################################################################

cur_wd="$PWD"
bitness="$(getconf LONG_BIT)"

	# Libretro Pcsx_rearmed build
	if [[ "$var" == "pcsx_rearmed" || "$var" == "all" ]]; then
	# if [[ "$(getconf LONG_BIT)" != "32" ]]; then
	#   echo " "
	#   echo "This environment is not 32 bit.  Can't build the pcsx_rearmed core here."
	#   echo " "
	#   exit 1
	# fi
	 pcsx_rearmed_rumblepatch="no"
	 cd $cur_wd
	  if [ ! -d "pcsx_rearmed/" ]; then
		git clone https://github.com/libretro/pcsx_rearmed.git
		if [[ $? != "0" ]]; then
		  echo " "
		  echo "There was an error while cloning the pcsx_rearmed libretro git.  Is Internet active or did the git location change?  Stopping here."
		  exit 1
		fi
		cp patches/pcsx_rearmed-patch* pcsx_rearmed/.
	  fi

	 cd pcsx_rearmed/
	 
	 pcsx_rearmed_patches=$(find *.patch)
	 
	 if [[ ! -z "$pcsx_rearmed_patches" ]]; then
	  for patching in pcsx_rearmed-patch*
	  do
		 if [[ $patching == *"rumble"* ]]; then
		   echo " "
		   echo "Skipping the $patching for now and making a note to apply that later"
		   sleep 3
		   pcsx_rearmed_rumblepatch="yes"
		 else  
		   patch -Np1 < "$patching"
		   if [[ $? != "0" ]]; then
			echo " "
			echo "There was an error while applying $patching.  Stopping here."
			exit 1
		   fi
		   rm "$patching" 
		 fi
	  done
	 fi
	  make clean

      sed -i '/a53/s//a35/g' Makefile.libretro
      sed -i '/a72/s//a35/g' Makefile.libretro
	  sed -i '/rpi3/s//rk3326/' Makefile.libretro
	  sed -i '/rpi3_64/s//rk3326_64/' Makefile.libretro

	  if [[ "$bitness" == "64" ]]; then
	    make -f Makefile.libretro ARCH=arm64 BUILTIN_GPU=unai DYNAREC=ari64 platform=rk3326_64 -j$(($(nproc) - 1))
	  else
	    make -f Makefile.libretro HAVE_NEON=1 ARCH=arm BUILTIN_GPU=neon DYNAREC=ari64 platform=rrk3326 -j$(($(nproc) - 1))
	  fi

	  if [[ $? != "0" ]]; then
		echo " "
		echo "There was an error while building the newest lr-pcsx_rearmed core.  Stopping here."
		exit 1
	  fi

	  strip pcsx_rearmed_libretro.so

	  if [ ! -d "../cores$bitness/" ]; then
		mkdir -v ../cores$bitness
	  fi

	  cp pcsx_rearmed_libretro.so ../cores$bitness/.

	  if [[ $pcsx_rearmed_rumblepatch == "yes" ]]; then
		for patching in pcsx_rearmed-patch*
		do
		  patch -Np1 < "$patching"
		  if [[ $? != "0" ]]; then
			echo " "
			echo "There was an error while patching in the rumble feature from $patching.  Stopping here."
			exit 1
		  fi
		  rm "$patching"

		  if [[ "$bitness" == "64" ]]; then
		    make -f Makefile.libretro ARCH=arm64 BUILTIN_GPU=unai DYNAREC=ari64 platform=rk3326_64 -j$(($(nproc) - 1))
		  else
		    make -f Makefile.libretro HAVE_NEON=1 ARCH=arm BUILTIN_GPU=neon DYNAREC=ari64 platform=rrk3326 -j$(($(nproc) - 1))
		  fi

		  if [[ $? != "0" ]]; then
			echo " "
			echo "There was an error while building the newest lr-pcsx_rearmed core with the patched in rumble feature.  Stopping here."
			exit 1
		  fi

		  strip pcsx_rearmed_libretro.so
		  mv pcsx_rearmed_libretro.so pcsx_rearmed_rumble_libretro.so
		  cp pcsx_rearmed_rumble_libretro.so ../cores$bitness/.
		  echo " "
		  echo "pcsx_rearmed_libretro.so and pcsx_rearmed_rumble_libretro.so have been created and have been placed in the rk3326_core_builds/cores32 subfolder"
	      gitcommit=$(git log | grep -m 1 commit | cut -c -14 | cut -c 8-)
	      echo $gitcommit > ../cores$bitness/pcsx_rearmed_rumble_libretro.so.commit
		done
	  fi

	  gitcommit=$(git log | grep -m 1 commit | cut -c -14 | cut -c 8-)
	  echo $gitcommit > ../cores$bitness/$(basename $PWD)_libretro.so.commit

	  echo " "
	  echo "pcsx_rearmed_libretro.so has been created and has been placed in the rk3326_core_builds/cores32 subfolder"
	fi
