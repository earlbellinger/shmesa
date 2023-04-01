#!/bin/bash

#### MESA SHMESA 
#### Author: Earl Patrick Bellinger
#### Max Planck Institute for Astrophysics
#### bellinger@phys.au.dk

#### Command line utilies for MESA 
# provides commands such as `mesa cp` and `mesa sed` 
# for usage, source this file (`source shmesa.sh`) and execute: mesa help 
# hot tip: add `source $MESA_DIR/scripts/shmesa.sh` to your ~/.bashrc 

SHMESA_DEBUG=0 # set to 1 for commentary 

mesa () {
    ### Define main utilities
    mesa_help () {
        echo "Usage: mesa [change|cp|grep|work|defaults|help] [arguments]"
        echo
        echo "Subcommands:"
        echo "  work      copy the work directory to the current location"
        echo "  change    change a parameter in the given inlist"
        echo "  defaults  copy the history/profile defaults to the current location"
        echo "  cp        copy a MESA directory without copying LOGS, photos, etc."
        echo "  grep      search the MESA source code for a given string"
        echo "  help      display this helpful message"
        echo
        echo "Run `mesa help full` for more options and information"
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

    mesa_change () {
        # usage: mesa change parameter value inlist
        # Modifies a parameter in the supplied inlist. 
        # Uncomments the parameter if it's commented out. 
        # Creates a backup of the inlist in `inlist.bak` 
        if [[ -z $1 || -z $2 || -z $3 ]]; then
            echo "Error: Missing arguments."
            echo "Usage: mesa change parameter value inlist"
            echo "example: mesa change initial_mass 1.3 inlist_project"
            echo "example: mesa change log_directory 'LOGS_MS' inlist"
            echo "example: mesa change do_element_diffusion .true. inlist"
            return 1
        fi
        # args: ($1) name of parameter 
        #       ($2) new value 
        #       ($3) filename of inlist where change should occur 
        local param=$1 
        local newval=$2 
        local filename=$3 

        local escapedParam=$(sed 's#[^^]#[&]#g; s#\^#\\^#g' <<< "$param")
        local search="^\s*\!*\s*$escapedParam\s*=.+$" 
        local replace="    $param = $newval" 
        
        # Check if the parameter is present in the inlist
        if ! grep -q "$search" "$filename"; then
            echo "Error: Parameter '$param' not found in the inlist '$filename'."
            return 1
        fi
        
        # Update its value 
        sed -r -i.bak -e "s#$search#$replace#g" $filename 
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
        # 
    }

    mesa_zip () {
        # 
    }

    mesa_defaults () {
        # 
    }
    
    # Test the mesa function with different subcommands and arguments
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
        
        mkdir mesa_test


        mesa cp src dest
        mesa grep "search_pattern" file.txt
        mesa sed "s/old/new/" file.txt
        SHMESA_DEBUG=$temp_value
        echo "all done!"
    }
    
    debug_print () {
        if [[ -n $SHMESA_DEBUG ]]; then
            echo "DEBUG: $@"
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
        cp)
            debug_print "Calling mesa_cp with arguments: $@"
            mesa_cp "$@"
            ;;
        grep)
            debug_print "Calling mesa_grep with arguments: $@"
            mesa_grep "$@"
            ;;
        change)
            debug_print "Calling mesa_change with arguments: $@"
            mesa_change "$@"
            ;;
        defaults)
            debug_print "Calling mesa_defaults with arguments: $@"
            mesa_defaults "$@"
            ;;
        test)
            debug_print "Calling mesa_test with arguments: $@"
            mesa_test "$@"
            ;;
        help)
            debug_print "Calling mesa_help with arguments: $@"
            mesa_help
            ;;
        -h)
            debug_print "Calling mesa_help with arguments: $@"
            mesa_help
            ;;
        *)
            echo "Invalid subcommand: $subcommand"
            mesa_help
            return 1
        ;;
    esac
}
