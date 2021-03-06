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
source "${FUT_TOPDIR}/shell/lib/onbrd_lib.sh"
[ -e "${PLATFORM_OVERRIDE_FILE}" ] && source "${PLATFORM_OVERRIDE_FILE}" || raise "${PLATFORM_OVERRIDE_FILE}" -ofm
[ -e "${MODEL_OVERRIDE_FILE}" ] && source "${MODEL_OVERRIDE_FILE}" || raise "${MODEL_OVERRIDE_FILE}" -ofm

tc_name="onbrd/$(basename "$0")"
manager_setup_file="onbrd/onbrd_setup.sh"
usage()
{
cat << usage_string
${tc_name} [-h] arguments
Description:
    - Validate device bridge mode settings
Arguments:
    -h : show this help message
    \$1 (wan_interface)  : Used to define WAN interface name  : (string)(required)
    \$2 (wan_ip)         : Used to define WAN IP              : (string)(required)
    \$3 (home_interface) : Used to define home interface name : (string)(required)
Testcase procedure:
    - On DEVICE: Run: ./${manager_setup_file} (see ${manager_setup_file} -h)
                 Run: ./${tc_name} <WAN-INTERFACE> <WAN-IP> <HOME-INTERFACE>
Script usage example:
   ./${tc_name} br-wan 192.168.200.10 br-home
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

check_kconfig_option "TARGET_CAP_EXTENDER" "y" ||
    raise "TARGET_CAP_EXTENDER != y - Testcase applicable only for EXTENDER-s" -l "${tc_name}" -s

NARGS=3
[ $# -lt ${NARGS} ] && usage && raise "Requires at least '${NARGS}' input argument(s)" -l "${tc_name}" -arg
# Fill variables with provided arguments or defaults.
wan_interface=${1}
wan_ip=${2}
home_interface=${3}

trap '
fut_info_dump_line
print_tables Wifi_Inet_State
ovs-vsctl show
fut_info_dump_line
' EXIT SIGINT SIGTERM

log "$tc_name: Checking if WANO is enabled, if yes, skip..."
check_kconfig_option "CONFIG_MANAGER_WANO" "y" &&
    raise "Test of bridge mode is not compatible if WANO is present on system" -l "${tc_name}" -s

log_title "$tc_name: ONBRD test - Verify Bridge Mode Settings"

# br-wan section
# Check if DHCP client is running on br-wan (wan bridge)
wait_for_function_response 0 "check_pid_udhcp $wan_interface" &&
    log "$tc_name: check_pid_udhcp - PID found, DHCP client running - Success" ||
    raise "FAIL: check_pid_udhcp - PID not found, DHCP client NOT running" -l "$tc_name" -tc

wait_ovsdb_entry Wifi_Inet_State -w if_name "$wan_interface" -is NAT true &&
    log "$tc_name: wait_ovsdb_entry - Wifi_Inet_Config reflected to Wifi_Inet_State::NAT is 'true' - Success" ||
    raise "FAIL: wait_ovsdb_entry - Failed to reflect Wifi_Inet_Config to Wifi_Inet_State::NAT is not 'true'" -l "$tc_name" -tc

wait_ovsdb_entry Wifi_Inet_State -w if_name "$wan_interface" -is ip_assign_scheme dhcp &&
    log "$tc_name: wait_ovsdb_entry - Wifi_Inet_Config reflected to Wifi_Inet_State::ip_assign_scheme is 'dhcp' - Success" ||
    raise "FAIL: wait_ovsdb_entry - Failed to reflect Wifi_Inet_Config to Wifi_Inet_State::ip_assign_scheme is not 'dhcp'" -l "$tc_name" -tc

wait_ovsdb_entry Wifi_Inet_State -w if_name "$wan_interface" -is inet_addr "$wan_ip" &&
    log "$tc_name: wait_ovsdb_entry - Wifi_Inet_Config reflected to Wifi_Inet_State::inet_addr is private - Success" ||
    raise "FAIL: wait_ovsdb_entry - Failed to reflect Wifi_Inet_Config to Wifi_Inet_State::inet_addr is not private" -l "$tc_name" -tc

# br-home section
wait_ovsdb_entry Wifi_Inet_State -w if_name "$home_interface" -is NAT false &&
    log "$tc_name: wait_ovsdb_entry - Wifi_Inet_Config reflected to Wifi_Inet_State::NAT is 'false' - Success" ||
    raise "FAIL: wait_ovsdb_entry - Failed to reflect Wifi_Inet_Config to Wifi_Inet_State::NAT is not 'false'" -l "$tc_name" -tc

wait_ovsdb_entry Wifi_Inet_State -w if_name "$home_interface" -is ip_assign_scheme none &&
    log "$tc_name: wait_ovsdb_entry - Wifi_Inet_Config reflected to Wifi_Inet_State::ip_assign_scheme is 'none' - Success" ||
    raise "FAIL: wait_ovsdb_entry - Failed to reflect Wifi_Inet_Config to Wifi_Inet_State::ip_assign_scheme is not 'none'" -l "$tc_name" -tc

wait_ovsdb_entry Wifi_Inet_State -w if_name "$home_interface" -is "dhcpd" "[\"map\",[]]" &&
    log "$tc_name: wait_ovsdb_entry - Wifi_Inet_Config reflected to Wifi_Inet_State::dhcpd is [\"map\",[]] - Success" ||
    raise "FAIL: wait_ovsdb_entry - Failed to reflect Wifi_Inet_Config to Wifi_Inet_State::dhcpd is not [\"map\",[]]" -l "$tc_name" -tc

wait_ovsdb_entry Wifi_Inet_State -w if_name "$home_interface" -is "netmask" "0.0.0.0" &&
    log "$tc_name: wait_ovsdb_entry - Wifi_Inet_Config reflected to Wifi_Inet_State::netmask is '0.0.0.0' - Success" ||
    raise "FAIL: wait_ovsdb_entry - Failed to reflect Wifi_Inet_Config to Wifi_Inet_State::netmask is not '0.0.0.0'" -l "$tc_name" -tc

wait_ovsdb_entry Wifi_Inet_State -w if_name "$home_interface" -is inet_addr "0.0.0.0" &&
    log "$tc_name: wait_ovsdb_entry - Wifi_Inet_Config reflected to Wifi_Inet_State::inet_addr is '0.0.0.0' - Success" ||
    raise "FAIL: wait_ovsdb_entry - Failed to reflect Wifi_Inet_Config to Wifi_Inet_State::inet_addr is not '0.0.0.0'" -l "$tc_name" -tc

pass
