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
        bfm.prog = 1;
        bfm.uart_send_byte(8'h12);
        bfm.uart_send_byte(8'h00);
        bfm.uart_send_byte(8'h34);
        bfm.uart_send_byte(8'h80);

        bfm.prog = 0;
        bfm.uart_send_byte(8'h12);
        bfm.uart_send_byte(get_data());
        bfm.uart_send_byte(8'h34);
        bfm.uart_send_byte(get_data());

    endtask

    protected task send_wrong_packets();
        bfm.prog = 1;
        bfm.send_wrong_packet(get_data());
        bfm.uart_send_byte(8'h00);
        bfm.uart_send_byte(get_data());
        bfm.send_wrong_packet(8'h80);

        bfm.prog = 0;
        bfm.uart_send_byte(get_data());
        bfm.send_wrong_packet(get_data());
        bfm.uart_send_byte(get_data());
        bfm.uart_send_byte(get_data());

    endtask



endclass : random_tpgen






