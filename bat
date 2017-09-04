#!/bin/bash
# ******************************************************************************
# 
# Name:    bat
# Author:  Gabriel Gonzalez
# Email:   gabeg@bu.edu
# License: The MIT License (MIT)
# 
# Syntax: bat [options]
# 
# Description: Display battery charge.
# 
# Notes: None.
# 
# ******************************************************************************

# Globals
PROG=`basename $0`
BATDIR="/sys/class/power_supply/BAT0"

# Source utility
. ../lib/util.sh

# Exit statuses
STATUS_NORMAL=0
STATUS_GETOPT=1
STATUS_ARGS=2
STATUS_BATPRESENT=10

# ******************************************************************************
# Main
main()
{
    [ $# -eq 0 ] && usage && exit ${STATUS_NORMAL}

    short="hci"
    long="help,charge,info"
    args=$(getopt -o "${short}" --long "${long}" --name "${PROG}" -- "${@}")

    [ $? -ne 0 ] && usage && exit ${STATUS_GETOPT}
    eval set -- "${args}"

    # Parse options
    while true; do
        case "${1}" in
            # Print usage
            -h|--help)
                usage
                exit 0
                ;;

            # Print battery charge
            -c|--charge)
                print_charge 
                ;;

            # Display battery information
            -i|--info)
                print_charge 
                print_info 
                ;;

            # End of options
            --)
                break
                ;;
        esac
        shift
    done
}

# ******************************************************************************
# Print program usage
usage()
{
    echo "Usage: ${PROG} [options]"
    echo
    echo "Options:"
    echo "    -h, --help"
    echo "        Print program usage message."
    echo
    echo "    -c, --charge"
    echo "        Print the current battery charge."
    echo
    echo "    -i, --info"
    echo "        Print extra battery information."
}

# ******************************************************************************
# Print current battery charge
print_charge()
{
    # Check if battery is present
    if ! is_battery_present; then
        print_err "Battery not present."
        exit ${STATUS_BATPRESENT}
    fi

    local batnow=$(get_battery_charge)
    local batfull=$(get_battery_charge_full)
    local batstatus=$(get_battery_status)
    local charge=$(echo "scale=3; ${batnow} / ${batfull} * 100" \
        | bc \
        | sed 's/..$//')
    echo "Battery: ${charge}% (${batstatus})"
}

# ******************************************************************************
# Print extra battery information
print_info()
{
    # Check if battery is present
    if ! is_battery_present; then
        print_err "Battery not present."
        exit ${STATUS_BATPRESENT}
    fi

    local batfulldesign=$(get_battery_charge_full_design | sed 's/...$//')
    local batfull=$(get_battery_charge_full | sed 's/...$//')
    local battech=$(get_battery_technology)
    local capacity=$(echo "scale=3; ${batfull} / ${batfulldesign} * 100" \
        | bc \
        | sed 's/..$//')
    echo "* ${battech} battery"
    echo "* Design capacity ${batfulldesign} mAh"
    echo "* Current capacity ${batfull} mAh (${capacity}% of design)"
}

# ******************************************************************************
# Return battery charge
get_battery_charge()
{
    local file="${BATDIR}/charge_now"
    head -1 "${file}"
}

# ******************************************************************************
# Return battery charge at full
get_battery_charge_full()
{
    local file="${BATDIR}/charge_full"
    head -1 "${file}"
}

# ******************************************************************************
# Return battery charge at full by design
get_battery_charge_full_design()
{
    local file="${BATDIR}/charge_full_design"
    head -1 "${file}"
}

# ******************************************************************************
# Return battery status
get_battery_status()
{
    local file="${BATDIR}/status"
    head -1 "${file}"
}

# ******************************************************************************
# Return battery technology
get_battery_technology()
{
    local file="${BATDIR}/technology"
    head -1 "${file}"
}

# ******************************************************************************
# Check if battery is present
is_battery_present()
{
    local file="${BATDIR}/present"
    local status=$(head -1 "${file}")
    if [ ${status} -eq 1 ]; then
        return 0
    fi
    return 1
}

# ******************************************************************************
# Run script
main "${@}"
