#!/bin/bash
## **********************************************************************************
## 
## Name:    bat
## Author:  Gabriel Gonzalez
## Email:   gabeg@bu.edu
## License: The MIT License (MIT)
## 
## Syntax: bat [options] <arguments>
##         
##         Use '--help' for more details.
##         
## Description: Display current battery charge.
##              
## Notes: None.
## 
## **********************************************************************************



## ================
## GLOBAL VARIABLES
## ================

## Program information
ARGV=("$@")
PROG_NAME=`basename $0`

## Battery files
DIR="/sys/class/power_supply/BAT0"
FILE_BAT_PRES="${DIR}/present"
FILE_BAT_STAT="${DIR}/status"
FILE_BAT_NOW="${DIR}/charge_now"
FILE_BAT_FULL="${DIR}/charge_full"
FILE_BAT_FULL_DES="${DIR}/charge_full_design"
FILE_BAT_TECH="${DIR}/technology"

## Battery information
BAT_ALARM_TIME=1
BAT_THRESHOLD=30
BAT_PRES=`head -1 ${FILE_BAT_PRES}`
BAT_STAT=`head -1 ${FILE_BAT_STAT}`
BAT_NOW=`head -1 ${FILE_BAT_NOW}`
BAT_FULL=`head -1 ${FILE_BAT_FULL}`
BAT_FULL_DES=`head -1 ${FILE_BAT_FULL_DES}`
BAT_TECH=`head -1 ${FILE_BAT_TECH}`

## Gui notification bubble
NOTIFY="noti"
NOTIFY_PATH=`hash "${NOTIFY}" 2>&1`



## #######################################
## ##### DISPLAY BATTERY INFORMATION ##### 
## #######################################

## Display battery information
main() {
    
    ## Stop execution if no battery present
    if [ "${BAT_PRES}" -eq 0 ]; then
        echo "${PROG_NAME}: Battery not present."
        exit 1
    fi
    
    ## Print battery information
    case "${ARGV[0]}" in
        "-c"|"--charge")
            print_charge 
            ;;
        "-i"|"--info")
            print_charge 
            print_info 
            ;;
        ""|"-h"|"--help")
            usage
            exit 0
            ;;
        *)
            echo "${PROG_NAME}: Invalid input '${ARGV[0]}'." 1>&2
            echo 1>&2
            usage 1>&2
            exit 1
            ;;
    esac
    
    exit 0
}



## ###############################
## ##### PRINT PROGRAM USAGE #####
## ###############################

## Print program usage
usage() {
    echo "Usage: ${PROG_NAME} [options]"
    echo
    echo "Options:"
    echo "    -h, --help      Print program usage message"
    echo "    -c, --charge    Print the current battery charge"
    echo "    -i, --info      Print extra battery information"
}



## #####################################
## ##### PRINT BATTERY INFORMATION #####
## #####################################

## Print current battery charge
print_charge() {
    charge=`echo "scale=3; ${BAT_NOW} / ${BAT_FULL} * 100" | bc | sed 's/..$//'`
    charge_alarm "${charge}" &> /dev/tty10 &
    
    echo "Battery: ${charge}% (${BAT_STAT})"
}



## Print extra battery information
print_info() {
    local des=`echo ${BAT_FULL_DES} | sed 's/...$//'`
    local curr=`echo ${BAT_FULL} | sed 's/...$//'` 
    local cap=`echo "scale=3; ${BAT_FULL} / ${BAT_FULL_DES} * 100" | bc | sed 's/..$//'`
    echo "* ${BAT_TECH} battery"
    echo "* Design capacity ${des} mAh, current capacity ${curr} mAh = ${cap}%"
}



## ################################
## ##### SYSTEM BATTERY ALARM ##### 
## ################################

## Enable system alarm if battery level is too low
charge_alarm() {
    
    ## Battery charge
    local charge="$1"
    local charge_round=`echo "${charge} / 1" | bc`
    
    ## Check if battery level is below a threshold
    if [ ${charge_round} -le ${BAT_THRESHOLD} ]; then
        
        ## Timer information for alarm duration 
        local timer_start=`echo "scale=2; $(date +%-N) / 10^9" | bc`
        local timer_now=${timer_start}
        local timer_prev=${timer_start}
        local timer_sec=0
        
        ## Alarm duration
        while [ ${timer_sec} -le ${BAT_ALARM_TIME} ]; do
            
            ## Elapsed time
            timer_now=`echo "scale=2; ${timer_sec} + $(date +%-N) / 10^9" | bc`
            
            ## Add on another second once it loops around 0.99
            new_timer_now=`echo "scale=0; ${timer_now} * 100" | bc | sed 's/...$//'`
            new_timer_prev=`echo "scale=0; ${timer_prev} * 100" | bc | sed 's/...$//'`
            
            if [ ${new_timer_prev} -gt ${new_timer_now} ]; then
                timer_sec=$[ ${timer_sec} + 1 ]
            fi
            
            ## Trigger alarm
            echo -en "\a"
            
            ## Previous time
            timer_prev=${timer_now}
        done
    fi
}



## ============
## Execute Main
## ============

main
