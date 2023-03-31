#!/bin/bash

#### MESA SHMESA 
#### Author: Earl Patrick Bellinger
#### Max Planck Institute for Astrophysics
#### bellinger@phys.au.dk

#### Command line utilies for MESA 
# provides commands such as `mesa cp` and `mesa sed` 
# for usage, source this file (`source shmesa.sh`) and execute: mesa help 
# hot tip: add `source $MESA_DIR/scripts/shmesa.sh` to your ~/.bashrc 

SHMESA_DEBUG=0

mesa () {
    ### Define main utilities
    mesa_help () {
        echo "Usage: mesa [cp|grep|sed|defaults|help] [arguments]"
        echo
        echo "Subcommands:"
        echo "  cp        "
        echo "  grep      "
        echo "  sed       "
        echo "  defaults  "
        echo "  help      Display this help message"
    }

    mesa_cp () {
        # usage: mesa cp source_dir target_dir
        #   Copies a MESA working directory but without copying 
        #   LOGS, photos, or .mesa_temp_cache
        echo "Calling mesa_cp with arguments: $@"
        SOURCE=$1
        TARGET=$2
        rsync -av --progress $SOURCE/ $TARGET \
            --exclude LOGS \
            --exclude photos \
            --exclude .mesa_temp_cache
    }

    mesa_change () {
        echo "Calling mesa_change with arguments: $@"
        # Modifies a parameter in the current inlist. 
        # args: ($1) name of parameter 
        #       ($2) new value 
        #       ($3) filename of inlist where change should occur 
        # example command: mesa change initial_mass 1.3 
        # example command: mesa change log_directory 'LOGS_MS' 
        # example command: mesa change do_element_diffusion .true. 
        param=$1 
        newval=$2 
        filename=$3 
        escapedParam=$(sed 's#[^^]#[&]#g; s#\^#\\^#g' <<< "$param")
        search="^\s*\!*\s*$escapedParam\s*=.+$" 
        replace="    $param = $newval" 
        if [ ! "$filename" == "" ]; then
            sed -r -i.bak -e "s#$search#$replace#g" $filename 
        fi
        if [ ! "$filename" == "$INLIST" ]; then 
            change $param $newval "$INLIST"
        fi 
    }

    mesa_grep () {
        # 
        echo "Calling mesa_grep with arguments: $@"

    }

    mesa_zip () {
        # 
    }

    # Test the mesa function with different subcommands and arguments
    mesa_test () {
        temp_value=$SHMESA_DEBUG
        if [[ -n $1 ]]; then
        SHMESA_DEBUG=$1
        else
        SHMESA_DEBUG=1
        fi
        echo "testing shmesa" 
        set -Eeuo pipefail # make the script exit if commands fail
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

    subcommand=$1
    shift

    case "$subcommand" in
        cp)
            mesa_cp "$@"
            ;;
        grep)
            mesa_grep "$@"
            ;;
        change)
            mesa_change "$@"
            ;;
        defaults)
            mesa_defaults "$@"
            ;;
        test)
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
