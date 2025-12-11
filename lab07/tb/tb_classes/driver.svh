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
class driver extends uvm_component;
    `uvm_component_utils(driver)
    
//------------------------------------------------------------------------------
// local variables
//------------------------------------------------------------------------------
    protected virtual switch_bfm bfm;
    uvm_get_port #(packet_transaction) pkt_port;
    
//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------
    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

//------------------------------------------------------------------------------
// build phase
//------------------------------------------------------------------------------
    function void build_phase(uvm_phase phase);
        if(!uvm_config_db #(virtual switch_bfm)::get(null, "*","bfm", bfm))
            $fatal(1, "Failed to get BFM");
        pkt_port = new("pkt_port",this);
    endfunction : build_phase
    
//------------------------------------------------------------------------------
// run phase
//------------------------------------------------------------------------------
    task run_phase(uvm_phase phase);
        packet_transaction pkt;
        bfm.sin = 1;
        bfm.rst_n = 0;
        repeat(16) @(posedge bfm.clk);
        bfm.rst_n = 1;

        forever begin : command_loop
            pkt_port.get(pkt);
            bfm.prog = pkt.prog;
            bfm.rst_n = pkt.rst_n;

            if(bfm.is_err == 0) begin
                bfm.uart_send_byte(pkt.addr[9:2], 0);
                bfm.uart_send_byte(pkt.data[9:2], 0);
            end

            else begin
                bfm.uart_send_byte(pkt.addr[9:2], 0);
                bfm.uart_send_byte(pkt.data[9:2], 1);
            end
        end : command_loop
    endtask : run_phase
    

endclass : driver

