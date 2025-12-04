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
class random_tpgen extends base_tpgen;
    `uvm_component_utils (random_tpgen)
    
//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

//------------------------------------------------------------------------------
// function: get_data - generate random data for the tpgen
//------------------------------------------------------------------------------
    protected function byte get_data();
        bit [1:0] zero_ones;
        zero_ones = 2'($random);
        if (zero_ones == 2'b00)
            return 8'h00;
        else if (zero_ones == 2'b11)
            return 8'hFF;
        else
            return byte'($random);
    endfunction : get_data


    protected task send_packets();
        pkt_t pkt;
        
        pkt.is_prog = 1;
        pkt.is_err = 0;
        pkt.addr = 8'h12;
        pkt.data = 8'h00;
        pkt_port.put(pkt);
        pkt.addr = 8'h34;
        pkt.data = 8'h80;
        pkt_port.put(pkt);

        pkt.is_prog = 0;
        pkt.addr = 8'h12;
        pkt.data = get_data();
        pkt_port.put(pkt);
        pkt.addr = 8'h34;
        pkt.is_err = 1;
        pkt.data = get_data();
        pkt_port.put(pkt);

    endtask



endclass : random_tpgen






