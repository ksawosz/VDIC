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
    // port for sending the transactions
    //------------------------------------------------------------------------------
        uvm_put_port #(pkt_t) pkt_port;
    
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
        pure virtual protected task send_packets();
    
    //------------------------------------------------------------------------------
    // build phase
    //------------------------------------------------------------------------------
        function void build_phase(uvm_phase phase);
            pkt_port = new("pkt_port", this);
        endfunction : build_phase
    
    //------------------------------------------------------------------------------
    // run phase
    //------------------------------------------------------------------------------
        task run_phase(uvm_phase phase);

            pkt_t pkt;

            phase.raise_objection(this);
            pkt_port.put(pkt);
             
            repeat (500) send_packets();
            $display("Test sequence complete");

            phase.drop_objection(this);    
    
        endtask : run_phase
    
    
    endclass : base_tpgen
    