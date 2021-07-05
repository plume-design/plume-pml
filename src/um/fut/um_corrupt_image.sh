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
source "${FUT_TOPDIR}/shell/lib/um_lib.sh"
[ -e "${PLATFORM_OVERRIDE_FILE}" ] && source "${PLATFORM_OVERRIDE_FILE}" || raise "${PLATFORM_OVERRIDE_FILE}" -ofm
[ -e "${MODEL_OVERRIDE_FILE}" ] && source "${MODEL_OVERRIDE_FILE}" || raise "${MODEL_OVERRIDE_FILE}" -ofm

tc_name="um/$(basename "$0")"
manager_setup_file="um/um_setup.sh"
um_resource_path="resource/um/"
um_create_corrupt_image_file_path="tools/server/um/um_create_corrupt_image_file.sh"
um_create_md5_file_path="tools/server/um/um_create_md5_file.sh"
um_image_name_default="um_corrupt_fw"
usage()
{
cat << usage_string
${tc_name} [-h] arguments
Description:
    - Script validates AWLAN_Node 'upgrade_status' field proper code change if corrupt image is downloaded, fails otherwise
Arguments:
    -h  show this help message
    \$1 (fw_path) : download path of UM - used to clear the folder on UM setup  : (string)(required)
    \$2 (fw_url)  : used as firmware_url in AWLAN_Node table                    : (string)(required)
Testcase procedure:
    - On RPI SERVER: Prepare clean FW (.img) in ${um_resource_path}
                     Duplicate image with different name (example. ${um_image_name_default}_tmp.img) (cp <CLEAN-IMG> <NEW-IMG>)
                     Create corrupted image of duplicated FW image (example. ${um_image_name_default}.img) (see ${um_create_corrupt_image_file_path} -h)
                     Create MD5 sum for corrupted image (example. ${um_image_name_default}.img.md5) (see ${um_create_md5_file_path} -h)
    - On DEVICE: Run: ./${manager_setup_file} (see ${manager_setup_file} -h)
                 Run: ./${tc_name} <FW-PATH> <FW-URL>
Script usage example:
   ./${tc_name} /tmp/pfirmware http://192.168.4.1:8000/fut-base/resource/um/${um_image_name_default}.img
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

NARGS=2
[ $# -lt ${NARGS} ] && usage && raise "Requires at least '${NARGS}' input argument(s)" -l "${tc_name}" -arg
fw_path=$1
fw_url=$2

trap '
    fut_info_dump_line
    print_tables AWLAN_Node
    fut_info_dump_line
    reset_um_triggers $fw_path || true
    run_setup_if_crashed um || true
' EXIT SIGINT SIGTERM

log_title "$tc_name: UM test - Corrupt FW image"

log "$tc_name: Setting firmware_url to $fw_url"
update_ovsdb_entry AWLAN_Node -u firmware_url "$fw_url" &&
    log "$tc_name: update_ovsdb_entry - AWLAN_Node::firmware_url is $fw_url - Success" ||
    raise "FAIL: update_ovsdb_entry - AWLAN_Node::firmware_url is not $fw_url" -l "$tc_name" -oe

fw_start_code=$(get_um_code "UPG_STS_FW_DL_START")
log "$tc_name: Waiting for FW download to start"
wait_ovsdb_entry AWLAN_Node -is upgrade_status "$fw_start_code" &&
    log "$tc_name: wait_ovsdb_entry - AWLAN_Node::upgrade_status is $fw_start_code - Success" ||
    raise "FAIL: wait_ovsdb_entry - AWLAN_Node::upgrade_status is not $fw_start_code" -l "$tc_name" -tc

fw_stop_code=$(get_um_code "UPG_STS_FW_DL_END")
log "$tc_name: Waiting for FW download to finish"
wait_ovsdb_entry AWLAN_Node -is upgrade_status "$fw_stop_code" &&
    log "$tc_name: wait_ovsdb_entry - AWLAN_Node::upgrade_status is $fw_stop_code - Success" ||
    raise "FAIL: wait_ovsdb_entry - AWLAN_Node::upgrade_status is not $fw_stop_code" -l "$tc_name" -tc

log "$tc_name: Setting AWLAN_Node upgrade_timer to 1 - Starting upgrade in 1 sec"
update_ovsdb_entry AWLAN_Node -u upgrade_timer 1 &&
    log "$tc_name: update_ovsdb_entry - AWLAN_Node::upgrade_timer is 1 - Success" ||
    raise "FAIL: update_ovsdb_entry - AWLAN_Node::upgrade_timer is not 1" -l "$tc_name" -oe

fw_fail_code=$(get_um_code "UPG_ERR_FL_WRITE")
log "$tc_name: Waiting for AWLAN_Node::upgrade_status to become UPG_ERR_FL_WRITE ($fw_fail_code)"
wait_ovsdb_entry AWLAN_Node -is upgrade_status "$fw_fail_code" &&
    log "$tc_name: wait_ovsdb_entry - AWLAN_Node::upgrade_status is $fw_fail_code - Success" ||
    raise "FAIL: wait_ovsdb_entry - AWLAN_Node::upgrade_status is not $fw_fail_code" -l "$tc_name" -tc

pass
