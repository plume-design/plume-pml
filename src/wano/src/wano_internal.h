/*
Copyright (c) 2015, Plume Design Inc. All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:
   1. Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
   2. Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
   3. Neither the name of the Plume Design Inc. nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL Plume Design Inc. BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#ifndef WANO_INTERNAL_H_INCLUDED
#define WANO_INTERNAL_H_INCLUDED

#include <stdbool.h>

#include "wano.h"
#include "const.h"
#include "ds_dlist.h"

/*
 * ===========================================================================
 *  Wifi_Inet_State/Wifi_Master_State
 * ===========================================================================
 */
bool wano_inet_state_init(void);

/*
 * ===========================================================================
 *  Connection_Manager_Uplink
 * ===========================================================================
 */
bool wano_connmgr_uplink_init(void);

/*
 * ===========================================================================
 *  Port table
 * ===========================================================================
 */
bool wano_ovs_port_init(void);

/*
 * ===========================================================================
 *  WAN Configuration
 * ===========================================================================
 */
bool wano_wan_config_init();

#endif /* WANO_INTERNAL_H_INCLUDED */
