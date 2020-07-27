# Copyright (c) 2020, Sagemcom.
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
# 
# 2. Redistributions in binary form must reproduce the above copyright notice
#    this list of conditions and the following disclaimer in the documentatio
#    and/or other materials provided with the distribution.
# 
# 3. Neither the name of the copyright holder nor the names of its contributo
#    may be used to endorse or promote products derived from this software
#    without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

gen_maptconfig()
{
    local tag=${1}
    local value=${2}
    local mod=${3}

cat << EOF
  {
    "op": "insert",
    "table": "Node_Config",
    "row":
    {
      "key": "${tag}",
      "value": "${value}",
      "module": "${mod}",
      "persist": true
    }
  }
EOF
}

gen_maptstate()
{
    local tag=${1}
    local value=${2}
    local mod=${3}

cat << EOF
  {
    "op": "insert",
    "table": "Node_State",
    "row":
    {
      "key": "${tag}",
      "value": "${value}",
      "module": "${mod}",
      "persist": true
    }
  }
EOF
}
operations="$(gen_maptconfig 'maptParams' '{\"support\":\"true\",\"interface\":\"br-wan\"}' 'MAPTM')"
operations+=",$(gen_maptstate 'maptMode' 'Dual-Stack' 'MAPTM')"


cat << EOF
[
  "Open_vSwitch",${operations}
]
EOF
