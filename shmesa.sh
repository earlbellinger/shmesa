#!/bin/bash
# Convenience tools for MESA

# Earl Patrick Bellinger
# Max Planck Institute for Astrophysics
# bellinger@phys.au.dk

mesa_cp () {
    # Copies a MESA working directory but without
    # copying LOGS, photos, etc. 
    SOURCE=$1
    TARGET=$2
    rsync -av --progress $SOURCE/ $TARGET \
          --exclude LOGS \
          --exclude photos \
          --exclude .mesa_temp_cache
}

# mesa_sed () {

# mesa_grep () {
