/*
 Copyright 2013 Ray Salemi

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */
class corner_tpgen extends random_tpgen;
    `uvm_component_utils(corner_tpgen)

    protected task send_packets();
        pkt_t pkt;

        pkt.is_prog = 1;
        pkt.addr = 8'hFF;
        pkt.data = 8'h00;
        pkt_port.put(pkt);
        pkt.addr = 8'h00;
        pkt.data = 8'h80;
        pkt_port.put(pkt);

        pkt.is_prog = 0;
        pkt.addr = 8'h00;
        pkt.data = get_data();
        pkt_port.put(pkt);
        pkt.addr = 8'hFF;
        pkt.data = get_data();
        pkt_port.put(pkt);

    endtask
  

//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new


endclass : corner_tpgen
