#!/bin/sh

# Copyright (c) 2015, Plume Design Inc. All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#    1. Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#    2. Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#    3. Neither the name of the Plume Design Inc. nor the
#       names of its contributors may be used to endorse or promote products
#       derived from this software without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL Plume Design Inc. BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


# FUT environment loading
# shellcheck disable=SC1091
source /tmp/fut-base/shell/config/default_shell.sh
[ -e "/tmp/fut-base/fut_set_env.sh" ] && source /tmp/fut-base/fut_set_env.sh
source "${FUT_TOPDIR}/shell/lib/nm2_lib.sh"
[ -e "${PLATFORM_OVERRIDE_FILE}" ] && source "${PLATFORM_OVERRIDE_FILE}" || raise "${PLATFORM_OVERRIDE_FILE}" -ofm
[ -e "${MODEL_OVERRIDE_FILE}" ] && source "${MODEL_OVERRIDE_FILE}" || raise "${MODEL_OVERRIDE_FILE}" -ofm

tc_name="nm2/$(basename "$0")"
manager_setup_file="nm2/nm2_setup.sh"
usage()
{
cat << usage_string
${tc_name} [-h] arguments
Description:
    - Script configures interfaces broadcast through Wifi_inet_Config 'broadcast' field and checks if it is propagated
      into Wifi_Inet_State table and to the system, fails otherwise
Arguments:
    -h  show this help message
    \$1 (if_name)   : used as if_name in Wifi_Inet_Config table   : (string)(required)
    \$2 (if_type)   : used as if_type in Wifi_Inet_Config table   : (string)(required)
    \$3 (broadcast) : used as broadcast in Wifi_Inet_Config table : (string)(required)
Testcase procedure:
    - On DEVICE: Run: ./${manager_setup_file} (see ${manager_setup_file} -h)
                 Run: ./${tc_name} <IF-NAME> <IF-TYPE> <BROADCAST>
Script usage example:
   ./${tc_name} wifi0 vif 10.0.0.10
usage_string
}
if [ -n "${1}" ]; then
    case "${1}" in
        help | \
        --help | \
        -h)
            usage && exit 1
            ;;
        *)
            ;;
    esac
fi
NARGS=3
[ $# -lt ${NARGS} ] && usage && raise "Requires at least '${NARGS}' input argument(s)" -l "${tc_name}" -arg
if_name=$1
if_type=$2
broadcast=$3

trap '
    fut_info_dump_line
    print_tables Wifi_Inet_Config Wifi_Inet_State
    fut_info_dump_line
    reset_inet_entry $if_name || true
    run_setup_if_crashed nm || true
    check_restore_management_access || true
' EXIT SIGINT SIGTERM

log_title "$tc_name: NM2 test - Testing table Wifi_Inet_Config field broadcast"

log "$tc_name: Creating Wifi_Inet_Config entries for $if_name"
create_inet_entry \
    -if_name "$if_name" \
    -enabled true \
    -network true \
    -ip_assign_scheme static \
    -inet_addr 10.10.10.30 \
    -netmask "255.255.255.0" \
    -if_type "$if_type" &&
        log "$tc_name: Interface $if_name created - Success" ||
        raise "FAIL: Failed to create $if_name interface" -l "$tc_name" -ds

log "$tc_name: Setting BROADCAST for $if_name to $broadcast"
update_ovsdb_entry Wifi_Inet_Config -w if_name "$if_name" -u broadcast "$broadcast" &&
    log "$tc_name: update_ovsdb_entry - Wifi_Inet_Config::broadcast is '$broadcast' - Success" ||
    raise "FAIL: update_ovsdb_entry - Wifi_Inet_Config::broadcast is not '$broadcast'" -l "$tc_name" -oe

wait_ovsdb_entry Wifi_Inet_State -w if_name "$if_name" -is broadcast "$broadcast" &&
    log "$tc_name: wait_ovsdb_entry - Wifi_Inet_Config reflected to Wifi_Inet_State::broadcast is '$broadcast' - Success" ||
    raise "wait_ovsdb_entry - Failed to reflect Wifi_Inet_Config to Wifi_Inet_State::broadcast is not '$broadcast'" -l "$tc_name" -tc

log "$tc_name: Check if BROADCAST was properly applied to $if_name - LEVEL2"
wait_for_function_response 0 "get_interface_broadcast_from_system $if_name | grep -q \"$broadcast\"" &&
    log "$tc_name: LEVEL2 - BROADCAST applied to ifconfig - broadcast is $broadcast - Success" ||
    raise "FAIL: LEVEL2 - Failed to apply BROADCAST to ifconfig - broadcast is not $broadcast" -l "$tc_name" -tc

log "$tc_name: Removing broadcast from Wifi_Inet_Config for $if_name"
update_ovsdb_entry Wifi_Inet_Config -w if_name "$if_name" \
    -u broadcast 0.0.0.0 \
    -u ip_assign_scheme none &&
        log "$tc_name: update_ovsdb_entry - Wifi_Inet_Config::broadcast is '0.0.0.0' - Success" ||
        raise "FAIL: update_ovsdb_entry - Wifi_Inet_Config::broadcast is not '0.0.0.0'" -l "$tc_name" -oe

wait_ovsdb_entry Wifi_Inet_State -w if_name "$if_name" \
    -is broadcast 0.0.0.0 \
    -is ip_assign_scheme none &&
        log "$tc_name: wait_ovsdb_entry - Wifi_Inet_Config reflected to Wifi_Inet_State::broadcast is '0.0.0.0' - Success" ||
        raise "FAIL: wait_ovsdb_entry - Failed to reflect Wifi_Inet_Config to Wifi_Inet_State::broadcast is not '0.0.0.0'" -l "$tc_name" -tc

log "$tc_name: Checking if BROADCAST was properly removed for $if_name - LEVEL2"
wait_for_function_response 1 "get_interface_broadcast_from_system $if_name | grep -q \"$broadcast\"" &&
    log "$tc_name: LEVEL2 - BROADCAST removed from ifconfig for interface $if_name - Success" ||
    raise "FAIL: LEVEL2 - Failed to remove BROADCAST from ifconfig for interface $if_name" -l "$tc_name" -tc

pass
