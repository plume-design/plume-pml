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

#include "log.h"
#include "memutil.h"

#include "linux/lnx_vlan.h"

#include "osn_vlan.h"

struct osn_vlan
{
    lnx_vlan_t  ov_vlan;
};

osn_vlan_t *osn_vlan_new(const char *ifname)
{
    osn_vlan_t *self = CALLOC(1, sizeof(osn_vlan_t));

    if (!lnx_vlan_init(&self->ov_vlan, ifname))
    {
        LOG(ERR, "osn_vlan: %s: Error initializing the VLAN object.", ifname);
        FREE(self);
        return NULL;
    }

    return self;
}

bool osn_vlan_del(osn_vlan_t *self)
{
    bool retval = true;

    if (!lnx_vlan_fini(&self->ov_vlan))
    {
        LOG(WARN, "osn_vlan: %s: Error destroying the VLAN object.", self->ov_vlan.lv_ifname);
        retval = false;
    }

    FREE(self);

    return retval;
}

bool osn_vlan_parent_set(osn_vlan_t *self, const char *parent_ifname)
{
    return lnx_vlan_parent_ifname_set(&self->ov_vlan, parent_ifname);
}

bool osn_vlan_vid_set(osn_vlan_t *self, int vlanid)
{
    return lnx_vlan_vid_set(&self->ov_vlan, vlanid);
}

bool osn_vlan_apply(osn_vlan_t *self)
{
    return lnx_vlan_apply(&self->ov_vlan);
}

bool osn_vlan_egress_qos_map_set(osn_vlan_t *self, const char *qos_map)
{
    return lnx_vlan_egress_qos_map_set(&self->ov_vlan, qos_map);
}
