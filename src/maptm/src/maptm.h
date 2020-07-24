/*
* Copyright (c) 2020, Sagemcom.
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without
* modification, are permitted provided that the following conditions are met:
*
* 1. Redistributions of source code must retain the above copyright notice,
*    this list of conditions and the following disclaimer.
*
* 2. Redistributions in binary form must reproduce the above copyright notice,
*    this list of conditions and the following disclaimer in the documentation
*    and/or other materials provided with the distribution.
*
* 3. Neither the name of the copyright holder nor the names of its contributors
*    may be used to endorse or promote products derived from this software
*    without specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
* AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
* IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
* ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
* LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
* CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
* SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
* INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
* CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
* POSSIBILITY OF SUCH DAMAGE.
*/

#ifndef MAPTM_H_INCLUDED
#define MAPTM_H_INCLUDED

#include "ovsdb_table.h"
#include "schema.h"
#include "osp.h"
#include "osp_ps.h"

#define MAPTM_MODULE_NAME          "MAPTM"

#define MAPTM_TIMEOUT_INTERVAL           5 /* Interval to verify timer condition */
    
extern int maptm_ovsdb_init(void);
extern bool maptm_ovsdb_nfm_add_rules(void);
extern bool maptm_ovsdb_nfm_del_rules(void);
extern void maptm_timerStart(void);
extern void maptm_timerStop(void);
extern void maptm_disableAccess(void);
extern void maptm_eligibilityStart(int WanConfig);
extern bool config_mapt(void);
extern bool stop_mapt(void);
extern void Parse_95_option(void);
extern void maptm_eligibilityStop(void);
extern void maptm_callback_Timer(void);
extern int maptm_dhcp_option_init(void);
extern bool maptm_dhcp_option_update_15_option(bool maptSupport);
extern bool maptm_dhcp_option_update_95_option(bool maptSupport);
int maptm_main(int argc, char **argv);
#define MAPTM_NO_ELIGIBLE_NO_IPV6 0x00 
#define MAPTM_NO_ELIGIBLE_IPV6 0x01 
#define MAPTM_ELIGIBLE_NO_IPV6 0x10 
#define MAPTM_ELIGIBLE_IPV6 0x11
#define MAPTM_ELIGIBILITY_ENABLE    0x10
#define MAPTM_IPV6_ENABLE    0x01

#define OVSDB_UUID_LEN    40
struct maptm_MAPT
{
    int mapt_support;
    bool mapt_95_Option;
    char mapt_95_value[8200];
    char iapd[256];
    int mapt_EnableIpv6;
    char mapt_mode[20];
    bool link_up;
    char option_23[OVSDB_UUID_LEN];
    char option_24[OVSDB_UUID_LEN];
};
#define IPV4_ADDRESS_SIZE       32
#define IPV6_PREFIX_MAX_SIZE    64

struct mapt
{
    uint8_t ealen;
    uint8_t prefix4len;
    uint8_t prefix6len;
    char *ipv4prefix;
    char *ipv6prefix;
    uint8_t offset;
    uint8_t psidlen;
    uint16_t psid;
    char *dmr;
    uint16_t domaine_pssid;
    uint16_t domaine_psidlen;
    uint16_t ratio;
    char ipv4PublicAddress[100];
};
struct list_rules
{
    char *value;
    ds_dlist_t d_node;
};

struct maptm_MAPT strucWanConfig; 
extern struct ovsdb_table table_DHCPv6_Client;
extern struct ovsdb_table table_DHCP_Client;
extern struct ovsdb_table table_Wifi_Inet_Config;
extern struct ovsdb_table table_mapt;
extern struct ovsdb_table table_Node_State;
bool maptm_persistent(void);

#endif  /* MAPTM_H_INCLUDED */
