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
virtual class base_tpgen extends uvm_component;

    // The macro is not there as we never instantiate/use the base_tpgen
    //    `uvm_component_utils(base_tpgen)
    
    //------------------------------------------------------------------------------
    // local variables
    //------------------------------------------------------------------------------
        protected virtual switch_bfm bfm;
    
    //------------------------------------------------------------------------------
    // constructor
    //------------------------------------------------------------------------------
        function new (string name, uvm_component parent);
            super.new(name, parent);
        endfunction : new
        
    //------------------------------------------------------------------------------
    // function prototypes
    //------------------------------------------------------------------------------
        pure virtual protected function byte get_data();
    
    //------------------------------------------------------------------------------
    // build phase
    //------------------------------------------------------------------------------
        function void build_phase(uvm_phase phase);
            if(!uvm_config_db #(virtual switch_bfm)::get(null, "*","bfm", bfm))
                $fatal(1,"Failed to get BFM");
        endfunction : build_phase
    
    //------------------------------------------------------------------------------
    // run phase
    //------------------------------------------------------------------------------
        task run_phase(uvm_phase phase);
        
            bfm.rst_n = 0;
            bfm.sin = 1;
            repeat(16) @(posedge bfm.clk); 
            bfm.rst_n = 1;
            repeat(16) @(posedge bfm.clk); 
            bfm.prog = 1;
            bfm.uart_send_byte(8'hFF);
            bfm.uart_send_byte(8'h00);
            repeat(1) @(posedge bfm.clk); 
            bfm.uart_send_byte(8'h00);
            bfm.uart_send_byte(8'h80);
            repeat(1) @(posedge bfm.clk); 
            bfm.prog = 0;
            bfm.uart_send_byte(8'h00);
            bfm.uart_send_byte(8'hFF);
            repeat(1) @(posedge bfm.clk); 
            bfm.uart_send_byte(8'hFF);
            bfm.uart_send_byte(8'h00);
            bfm.uart_send_byte(8'h00);
            bfm.send_wrong_packet(8'h00);
            bfm.rst_n = 0;
            bfm.prog = 1;
            bfm.uart_send_byte(8'hFF);
            bfm.uart_send_byte(8'h00);
            bfm.prog = 0;
            bfm.uart_send_byte(8'hFF);
            bfm.uart_send_byte(8'h00);
            repeat(1000) @(posedge bfm.clk);
            $display("Test sequence complete");

            phase.raise_objection(this);
    
    
        endtask : run_phase
    
    
    endclass : base_tpgen
    