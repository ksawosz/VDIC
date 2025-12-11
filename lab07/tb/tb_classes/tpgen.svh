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
class tpgen extends uvm_component;
    `uvm_component_utils (tpgen)

//------------------------------------------------------------------------------
// local variables
//------------------------------------------------------------------------------

    uvm_put_port #(packet_transaction) packet_port;

//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------

    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    function void build_phase(uvm_phase phase);
        packet_port = new("packet_port", this);
    endfunction : build_phase

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

//------------------------------------------------------------------------------
// run phase
//------------------------------------------------------------------------------

    task run_phase(uvm_phase phase);
        packet_transaction packet;

        phase.raise_objection(this);

        packet    = new("packet");

        packet.prog = 1;
        packet.is_err = 0;
        packet.addr = 11'h12;
        packet.data = 11'h00;
        packet_port.put(packet);
        packet.addr = 11'h34;
        packet.data = 11'h80;
        packet_port.put(packet);

        packet.prog = 0;
        packet.addr = 11'h12;
        packet.data = 11'b01100110111;
        packet_port.put(packet);
        packet.addr = 11'h34;
        packet.is_err = 1;
        packet.data = 11'b01100110111;
        packet_port.put(packet);

        #100000;
        phase.drop_objection(this);
    endtask : run_phase


endclass : tpgen






