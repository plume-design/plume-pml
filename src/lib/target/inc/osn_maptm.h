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

#ifndef OSN_MAPTM_H_INCLUDED
#define OSN_MAPTM_H_INCLUDED

#include "schema.h"

#define MAPTM_CMD_LEN               256

/**
* @brief Initialize map-t module
* @return true on success
*/
bool osn_mapt_init(void);                       //Initialize MAP-T functionality 

/**
* @brief Configure and start MAP-T module 
* @param[in] brprefix string value of border relay prefix
* @param[in] ratio int value of address sharing ratio
* @param[in] intfname string value of interface name
* @param[in] wanintf string value of wan interface name
* @param[in] IPv6prefix string value of the IPv6 prefix
* @param[in] subnetcidr4 string value of CIDR subnet 
* @param[in] ipv4PublicAddress string value of IPv4 Shared Address  
* @param[in] PSIDoffset type of value of PSID offset
* @param[in] PSID type of value of PSID

* @return true on success
*/
bool osn_mapt_configure(const char* brprefix,     //Configure and start MAP-T module   
						   int ratio, 
						   const char* intfname, 
						   const char* wanintf, 
						   const char* IPv6prefix, 
						   const char* subnetcidr4, 
						   const char* ipv4PublicAddress, 
						   int PSIDoffset, 
						   int PSID);

/**
* @brief Stop map-t module
* @return true on success
*/						   
bool osn_mapt_stop();                             //Stop MAP-T functionality 

#endif /* OSN_MAPTM_H_INCLUDED */

