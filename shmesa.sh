#!/bin/bash

#### MESA SHMESA 
#### Author: Earl Patrick Bellinger
#### Max Planck Institute for Astrophysics
#### bellinger@phys.au.dk

#### Command line utilies for MESA 
# provides commands such as `mesa change` and `mesa grep` 
# for usage, source this file (`source shmesa.sh`) and call: mesa help 
# hot tip: add `source $MESA_DIR/scripts/shmesa.sh` to your ~/.bashrc 

if [[ -z $MESA_DIR ]] || [[ ! -d $MESA_DIR ]]; then
  echo "Error: MESA_DIR is not set or does not point to a valid directory."
  echo "Please download and install MESA:"
  echo "https://docs.mesastar.org"
  exit 1
fi

SHMESA_DEBUG=0 # set to 1 for commentary 
SHMESA_BACKUP=1 # back up modified files before modification (e.g. to inlist.bak) 

mesa () {
    ### Define main utilities
    mesa_help () {
         cat << "EOF"
      _     __  __ _____ ____    _    
  ___| |__ |  \/  | ____/ ___|  / \   
 / __| '_ \| |\/| |  _| \___ \ / _ \  
 \__ \ | | | |  | | |___ ___) / ___ \ 
 |___/_| |_|_|  |_|_____|____/_/   \_\
                                      
EOF
        echo "Usage: mesa [work|change|defaults|cp|grep|zip|help] [arguments]"
        echo
        echo "Subcommands:"
        echo "  work      copy the work directory to the current location"
        echo "  change    change a parameter in the given inlist"
        echo "  defaults  copy the history/profile defaults to the current location"
        echo "  cp        copy a MESA directory without copying LOGS, photos, etc."
        echo "  grep      search the MESA source code for a given string"
        echo "  zip       prepare a MESA directory for sharing"
        echo "  help      display this helpful message"
        echo
        #echo "Run `mesa help full` for more options and information" (TODO)
    }
    
    mesa_work () {  
        # usage: mesa work [optional: target_name] 
        # Copies star/work to the current directory 
        local target_dir="."
        if [[ -n $1 ]]; then
            target_dir=$1
        fi
        cp -R "$MESA_DIR/star/work" "$target_dir"
    }

    local ESCAPE="s#[^^]#[&]#g; s#\^#\\^#g" # sed escape string; needed below
    mesa_change() {
        # usage: mesa change inlist parameter value [parameter value [parameter value]]
        # Modifies one or more parameters in the supplied inlist.
        # Uncomments the parameter if it's commented out.
        # Creates a backup of the inlist in `inlist.bak`

        if [[ -z $1 || -z $2 || -z $3 ]]; then
            echo "Error: Missing arguments."
            echo "   usage: mesa change inlist parameter value [parameter value [parameter value]]"
            echo " example: mesa change inlist_project initial_mass 1.3"
            echo " example: mesa change inlist_project log_directory 'LOGS_MS'"
            echo " example: mesa change inlist_project do_element_diffusion .true."
            echo "    or all at once:"
            echo " example: mesa change inlist_project initial_mass 1.3 do_element_diffusion .true."
            return 1
        fi

        local filename=$1
        shift

        # Create a backup of the inlist before making any changes
        backup_copy "$filename" "${filename}.bak"

        while [[ -n $1 && -n $2 ]]; do
            local param=$1
            local newval=$2
            shift 2

            local escapedParam=$(sed '$ESCAPE' <<< "$param")
            local search="^\s*\!*\s*$escapedParam\s*=.+$"
            local replace="    $param = $newval"

            # Check if the parameter is present in the inlist
            if ! grep -q "$search" "$filename"; then
                echo "Error: Parameter '$param' not found in the inlist '$filename'."
                return 1
            fi

            # Update its value
            sed -r -i -e "s#$search#$replace#g" "$filename"
        done
    }

    mesa_defaults() {
        # usage: mesa defaults [parameter [parameter]]
        # Copies profile_columns.list and history_columns.list to the current location.
        # Also uncomments any specified parameters.
        # If the files are already in the present directory, just uncomment the specified parameters.
        # Example: mesa defaults nu_max Delta_nu

        # Copy the files and create backups if they already exist in the current directory
        if [[ -f profile_columns.list ]]; then
            backup_copy profile_columns.list
        else
            cp "$MESA_DIR/star/defaults/profile_columns.list" .
        fi

        if [[ -f history_columns.list ]]; then
            backup_copy history_columns.list
        else
            cp "$MESA_DIR/star/defaults/history_columns.list" .
        fi

        # Uncomment the specified parameters
        while [[ -n $1 ]]; do
            local param=$1
            shift

            local escapedParam=$(sed '$ESCAPE' <<< "$param")
            local search="^\s*\!*\s*$escapedParam\s*=\s*.+$"
            local replace="    $param"

            # Uncomment parameter in profile_columns.list
            sed -r -i -e "s#^(\s*)\!(\s*)$escapedParam#$replace#g" profile_columns.list

            # Uncomment parameter in history_columns.list
            sed -r -i -e "s#^(\s*)\!(\s*)$escapedParam#$replace#g" history_columns.list
        done
    }

    mesa_cp () {
        # Copies a MESA working directory but without copying 
        # LOGS, photos, or .mesa_temp_cache
        if [[ -z $1 || -z $2 ]]; then
            echo "Error: Missing arguments."
            echo "Usage: mesa cp source_dir target_dir"
            return 1
        fi
        # args: ($1) source directory to be copied from
        #       ($2) target directory to be copied to
        local SOURCE=$1
        local TARGET=$2
        rsync -av --progress $SOURCE/ $TARGET \
            --exclude LOGS \
            --exclude photos \
            --exclude .mesa_temp_cache
    }
    
    mesa_grep () {
        # usage: mesa grep term [optional: directory or filename]
        if [[ -z $1 ]]; then
            echo "Error: Missing search term."
            echo "Usage: mesa grep term [optional: directory or filename]"
            return 1
        fi

        local search_term=$1
        local search_dir=$MESA_DIR

        if [[ -n $2 ]]; then
            search_dir=$MESA_DIR/$2
        fi

        grep -r --color=always "$search_term" "$search_dir"
    }

    mesa_zip () {
        # usage: mesa zip [directory] 
        # zips the inlists and models of the specified directory for sharing 
        local zip_name="mesa.zip"
        local dir_to_zip='.'
        if [[ ! -z $1 ]]; then
            dir_to_zip=$1
            zip_name="${dir_to_zip}_mesa.zip"
        fi

        # Create a zip file containing only inlists and models
        zip -r "$zip_name" "$dir_to_zip" -i '*inlist*' '*.mod'
    }

    # Test this function with different subcommands and arguments
    mesa_test () {
        echo "testing shmesa"
        set -Eeuo pipefail # exit if any commands fail 

        # store current value of SHMESA_DEBUG and turn on debugging 
        local temp_value=$SHMESA_DEBUG
        if [[ -n $1 ]]; then
            SHMESA_DEBUG=$1
        else
            SHMESA_DEBUG=1
        fi 
        
        # mesa work
        mesa work mesa_test
        cd mesa_test
        ./mk
        
        # mesa defaults
        mesa defaults nu_max Delta_nu
        mesa defaults logM

        # mesa change 
        mesa change inlist_project pgstar_flag .false.
        mesa change inlist_project \
                initial_mass 1.2 \
                mixing_length_alpha 1.5
        
        # mesa change with a grid 
        #for M in `seq 1.0 0.1 1.3`; do
        #    for A in `seq 1.6 0.1 1.9`; do
        #        mesa change inlist_project \
        #            initial_mass $M \
        #            mixing_length_alpha $A \
        #            log_directory "'$M_$alpha'"
        #        ./star inlist_project 
        #    done
        #done 

        # mesa cp
        # TODO

        # mesa zip
        # TODO

        # mesa grep
        # TODO

        SHMESA_DEBUG=$temp_value
        echo "all done!"
    }
    
    debug_print () {
        if [[ $SHMESA_DEBUG -ne 0 ]]; then
            echo "DEBUG: $@"
        fi
    }
    
    backup_copy () {
        if [[ $SHMESA_BACKUP -ne 0 && ! -z $1 ]]; then
            debug_print "BACKING UP: $@"
            cp "$1" "$1".bak
        fi
    }

    #############################
    ### Parse command line tokens
    ###
    if [[ -z $1 ]]; then
        mesa_help
        return 1
    fi

    local subcommand=$1
    shift

    case "$subcommand" in
        work)
            debug_print "Calling mesa_work with arguments: $@"
            mesa_work "$@"
            ;;
        change)
            debug_print "Calling mesa_change with arguments: $@"
            mesa_change "$@"
            ;;
        defaults)
            debug_print "Calling mesa_defaults with arguments: $@"
            mesa_defaults "$@"
            ;;
        cp)
            debug_print "Calling mesa_cp with arguments: $@"
            mesa_cp "$@"
            ;;
        grep)
            debug_print "Calling mesa_grep with arguments: $@"
            mesa_grep "$@"
            ;;
        zip)
            debug_print "Calling mesa_zip with arguments: $@"
            mesa_zip "$@"
            ;;
        test)
            debug_print "Calling mesa_test with arguments: $@"
            mesa_test "$@"
            ;;
        help)
            mesa_help
            ;;
        -h)
            mesa_help
            ;;
        *)
            echo "Invalid subcommand: $subcommand"
            mesa_help
            return 1
        ;;
    esac
}
