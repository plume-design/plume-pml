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
source "${FUT_TOPDIR}/shell/lib/cm2_lib.sh"
[ -e "${PLATFORM_OVERRIDE_FILE}" ] && source "${PLATFORM_OVERRIDE_FILE}" || raise "${PLATFORM_OVERRIDE_FILE}" -ofm
[ -e "${MODEL_OVERRIDE_FILE}" ] && source "${MODEL_OVERRIDE_FILE}" || raise "${MODEL_OVERRIDE_FILE}" -ofm

tc_name="cm2/$(basename "$0")"
cm_setup_file="cm2/cm2_setup.sh"
adr_internet_man_file="tools/server/cm/address_internet_man.sh"
step_1_name="check_counter"
step_2_name="internet_recovered"
counter_default=4
usage()
{
cat << usage_string
${tc_name} [-h] arguments
Description:
    - Script checks if CM updates Connection_Manager_Uplink field 'unreachable_internet_counter' reaches given value when internet is unreachable
      If the field 'unreachable_internet_counter' doesen't reach given value, test fails
Arguments:
    -h : show this help message
    \$1 (if_name)                      : WAN interface name               : (string)(required)
    \$2 (unreachable_internet_counter) : used as value counter must reach : (int)(optional)    : (default:${counter_default})
    \$3 (test_step)                    : used as test step                : (string)(optional) : (default:${step_1_name}) : (${step_1_name}, ${step_2_name})
Testcase procedure:
    - On DEVICE: Run: ./${cm_setup_file} (see ${cm_setup_file} -h)
                 Run: ./${tc_name} <WAN_IF_NAME> <UNRCH-CLOUD-COUNTER> ${step_1_name}
    - On RPI SERVER: Run: ./${adr_internet_man_file} <WAN-IP-ADDRESS> block
    - On DEVICE: Run: ./${tc_name} <WAN_IF_NAME> <UNRCH-CLOUD-COUNTER> ${step_2_name}
    - On RPI SERVER: Run: ./${adr_internet_man_file} <WAN-IP-ADDRESS> unblock
Script usage example:
    ./${tc_name} eth0 ${counter_default} ${step_1_name}
    ./${tc_name} eth0 0 ${step_2_name}
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

NARGS=1
[ $# -lt ${NARGS} ] && usage && raise "Requires at least '${NARGS}' input argument(s)" -l "${tc_name}" -arg
if_name=${1}
unreachable_internet_counter=${2:-${counter_default}}
test_type=${3:-"${step_1_name}"}

trap '
fut_info_dump_line
print_tables Connection_Manager_Uplink
fut_info_dump_line
check_restore_management_access || true
run_setup_if_crashed cm || true
' EXIT SIGINT SIGTERM

log_title "$tc_name: CM2 test - Internet Lost - $test_type"

if [ "$test_type" = "${step_1_name}" ]; then
    log "$tc_name: Waiting for unreachable_internet_counter to reach $unreachable_internet_counter"
    wait_ovsdb_entry Connection_Manager_Uplink -w if_name "${if_name}" -is unreachable_internet_counter "$unreachable_internet_counter" &&
        log "$tc_name: Connection_Manager_Uplink::unreachable_internet_counter is $unreachable_internet_counter - Success" ||
        raise "FAIL: Connection_Manager_Uplink::unreachable_internet_counter is not $unreachable_internet_counter" -l "$tc_name" -ow
elif [ "$test_type" = "${step_2_name}" ]; then
    log "$tc_name: Waiting for unreachable_internet_counter to reset to 0"
    wait_ovsdb_entry Connection_Manager_Uplink -w if_name "${if_name}" -is unreachable_internet_counter "0" &&
        log "$tc_name: Connection_Manager_Uplink::unreachable_internet_counter reset to 0 - Success" ||
        raise "FAIL: Connection_Manager_Uplink::unreachable_internet_counter is not 0" -l "$tc_name" -ow
else
    raise "FAIL: Wrong test type option" -l "$tc_name" -arg
fi

pass
