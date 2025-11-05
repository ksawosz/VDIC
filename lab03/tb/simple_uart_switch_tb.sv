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

 History:
 2021-10-05 RSz, AGH UST - test modified to send all the data on negedge bfm.clk
 and check the data on the correct clock edge (covergroup on posedge
 and scoreboard on negedge). Scoreboard and coverage removed.
 */

module top;

    //------------------------------------------------------------------------------
    // Type definitions
    //------------------------------------------------------------------------------
    import switch_tb_pkg::*;

    //`define DEBUG
    //`define COVERAGE
    
    //------------------------------------------------------------------------------
    // Local variables
    //----------------------------
    
    test_result_t        test_result = TEST_PASSED;
    logic                [21:0] data_out;
    bit                  packet_end;
    
    pkt_t data_queue[$];
    switch_bfm bfm();
    
    //------------------------------------------------------------------------------
    // DUT instantiation
    //------------------------------------------------------------------------------
    
    simple_switch_uart DUT (.clk(bfm.clk), .rst_n(bfm.rst_n), .prog(bfm.prog), .sin(bfm.sin), .sout0(bfm.sout0), .sout1(bfm.sout1));
    
    //------------------------------------------------------------------------------
    // Tester
    //------------------------------------------------------------------------------
    
    function byte get_data();
    
        bit [1:0] zero_ones;
    
        zero_ones = 2'($random);
    
        if (zero_ones == 2'b00)
            return 8'h00;
        else if (zero_ones == 2'b11)
            return 8'hFF;
        else
            return 8'($random);
    endfunction : get_data

    initial begin
        int i;
        bit parity;
        logic [11:0] addr_port;
        pkt_t newpkt;
        parity = 0;
        data_out[21:0] = 0;
        bfm.err_packet = 0;

        forever begin
            @(negedge bfm.sin);
            bfm.err_packet = 0;

            for(int k = 0; k < 2; k++) begin
                parity = 0;
                repeat (8) @(posedge bfm.clk);
                `ifdef DEBUG
                $display("1 err = ", bfm.err_packet);
                `endif
                if(bfm.sin == 0) begin
                    if(!k) begin
                        data_out[0] = bfm.sin;
                    end
                    else begin
                        data_out[11] = bfm.sin;
                    end
                end
                else begin
                    bfm.err_packet = 1;
                end
                `ifdef DEBUG
                $display("2 err = ", bfm.err_packet);
                `endif

                for(i = 0; i < 8; i++) begin
                    repeat (16) @(posedge bfm.clk);
                    if(!k) begin
                        data_out[i+1] = bfm.sin;
                        parity ^= data_out[i+1];
                    end
                    else begin
                        data_out[i+12] = bfm.sin;
                        parity ^= data_out[i+12];
                    end
                end

                repeat (16) @(posedge bfm.clk);
                if(bfm.sin == parity) begin
                    if(!k) begin
                        data_out[9] = bfm.sin;
                    end
                    else begin
                        data_out[20] = bfm.sin;
                    end
                end
                else begin
                    bfm.err_packet = 1;
                end
                `ifdef DEBUG
                $display("3 err = ", bfm.err_packet);
                `endif

                repeat (16) @(posedge bfm.clk);
                if(bfm.sin == 1) begin
                    if(!k) begin
                        data_out[10] = bfm.sin;
                    end
                    else begin
                        data_out[21] = bfm.sin;
                    end
                end
                else begin
                    bfm.err_packet = 1;
                end
                `ifdef DEBUG
                $display("4 err = ", bfm.err_packet);
                `endif

                repeat (8) @(posedge bfm.clk);
            end
        
                newpkt.addr    = data_out[8:1];     
                newpkt.port    = data_out[12];       
                newpkt.is_prog = bfm.prog;               
                newpkt.is_err  = bfm.err_packet;
                data_queue.push_back(newpkt);        
                

            packet_end = 1;
        end
    end


    initial begin : monitor_and_check
        typedef struct {
            logic [10:0] addr;
            bit         port;
        } addr_map_t;
    
        addr_map_t prog_table[$]; 
        pkt_t      pkt;
        bit        expected_port;
    
        forever begin

            wait(packet_end == 1);
            `ifdef DEBUG
                $display("packet_end=",packet_end);
                $display("data_queue size = ", data_queue.size());
            `endif
            if (packet_end == 1 && data_queue.size() > 0) begin
                packet_end = 0;

                `ifdef DEBUG
                $display("packet_end=",packet_end);
                `endif

                for (int i = 0; i < data_queue.size(); i++) begin
                    pkt = data_queue[i];

                    `ifdef DEBUG
                    $display("[%0t] MONITOR: pkt[%0d] addr=0x%0h port=%0b is_prog=%0b is_err=%0b", 
                             $time, i, pkt.addr, pkt.port, pkt.is_prog, pkt.is_err);
                    `endif
    
                    if (pkt.is_prog) begin
                        int found_idx[$];
                        found_idx = prog_table.find_index with (item.addr == pkt.addr);
    
                        if (found_idx.size() == 0) begin
                            addr_map_t new_entry;
                            new_entry.addr = pkt.addr;
                            new_entry.port = pkt.port;
                            prog_table.push_back(new_entry);

                            `ifdef DEBUG
                            $display("[%0t] PROG: dodano addr=0x%0h -> port=%0b", $time, pkt.addr, pkt.port);
                            `endif
                        end
                        else begin
                            prog_table[found_idx[0]].port = pkt.port;

                            `ifdef DEBUG
                            $display("[%0t] PROG: nadpisano addr=0x%0h -> port=%0b", $time, pkt.addr, pkt.port);
                            `endif
                        end
                    end
                    else begin
                        int found_idx[$];
                        found_idx = prog_table.find_index with (item.addr == pkt.addr);
    
                        if (found_idx.size() == 0) begin

                            `ifdef DEBUG
                            $display("[%0t] ERR: Otrzymano pakiet danych dla nieznanego adresu 0x%0h — to błąd!", $time, pkt.addr);
                            `endif
                            test_result = TEST_FAILED;
                        end
                        else begin
                            expected_port = prog_table[found_idx[0]].port;
                            repeat (8) @(posedge bfm.clk);
                            
                            if (expected_port == 0) begin
                                if (bfm.sout0 == pkt.is_err) begin

                                    `ifdef DEBUG
                                    $display("\n[%0t] PASS: Dane dla addr=0x%0h pojawiły się na sout0\n", $time, pkt.addr);
                                    `endif
                                    
                                    if(pkt.is_err == 0) begin
                                        for(int h=0; h<22; h++) begin
                                            if(data_out[h] != bfm.sout0) begin

                                                `ifdef DEBUG
                                                $display("dataot = ", data_out[h]," sout0 = ", bfm.sout0);
                                                `endif

                                                test_result = TEST_FAILED;
                                            end
                                            repeat (16) @(posedge bfm.clk);
                                        end
                                    end
                                    else begin
                                        for(int h=0; h<22; h++) begin
                                            if(bfm.sout0 != 1) begin
                                                test_result = TEST_FAILED;
                                            end
                                        end
                                    end

                                end
                                else begin

                                    `ifdef DEBUG
                                    $display("[%0t] FAIL: Dane dla addr=0x%0h NIE pojawiły się na sout0", $time, pkt.addr);
                                    `endif

                                    test_result = TEST_FAILED;
                                end
                            end
                            else begin
                                if (bfm.sout1 == pkt.is_err) begin

                                    `ifdef DEBUG
                                    $display("[%0t] PASS: Dane dla addr=0x%0h pojawiły się na sout1", $time, pkt.addr);
                                    `endif

                                    if(pkt.is_err == 0) begin
                                        for(int h=0; h<22; h++) begin
                                            if(data_out[h] != bfm.sout1) begin

                                                `ifdef DEBUG
                                                $display("dataot = ", data_out[h]," sout1 = ", bfm.sout1);
                                                `endif

                                                test_result = TEST_FAILED;
                                            end
                                            repeat (16) @(posedge bfm.clk);
                                        end
                                    end
                                    else begin
                                        for(int h=0; h<22; h++) begin
                                            if(bfm.sout1 != 1) begin
                                                test_result = TEST_FAILED;
                                            end
                                        end
                                    end
                                end
                                else begin

                                    `ifdef DEBUG
                                    $display("[%0t] FAIL: Dane dla addr=0x%0h NIE pojawiły się na sout1", $time, pkt.addr);
                                    `endif

                                    test_result = TEST_FAILED;
                                end
                            end
                        end
                        data_queue.delete(i);
                    end
                end
            end 
        end 
    end 


    covergroup cov_data @(posedge bfm.clk);
        coverpoint bfm.addr {
            bins max0 = {8'b11111111};
            bins min0 = {8'b00000000};
        }
        coverpoint bfm.target {
            bins max1 = {8'b11111111};
            bins min1 = {8'b00000000};
        }
        coverpoint bfm.data {
            bins max1 = {8'b11111111};
            bins min1 = {8'b00000000};
        }
        coverpoint bfm.err_packet {
            bins err = {1};
            bins not_err = {0};
        }
        coverpoint bfm.sout1 {
            bins signal0 = {0};
            bins idle0 = {1};
        }
        coverpoint bfm.sout0 {
            bins signal0 = {0};
            bins idle0 = {1};
        }
        coverpoint bfm.sin {
            bins signal0 = {0};
            bins idle0 = {1};
        }
        coverpoint bfm.prog {
            bins progr = {0};
            bins funct = {1};
        }
        endgroup
        
        cov_data cover_addr;
    

    
    
    //------------------------
    // Tester main

    initial begin
        cover_addr = new();
        bfm.sin = 1;
        bfm.rst_n = 0;
        repeat (16) @(posedge bfm.clk);
        bfm.rst_n = 1;

        bfm.prog = 1;
        bfm.addr = 8'b11111111;
        bfm.port = 8'b10000000;
        bfm.uart_send_byte(bfm.addr);
        bfm.uart_send_byte(bfm.port);
        bfm.addr = 8'b00000000;
        bfm.port = 8'b00000000;
        bfm.uart_send_byte(bfm.addr);
        bfm.uart_send_byte(bfm.port);
        bfm.addr = 8'b11111110;
        bfm.port = 8'b00000000;
        bfm.uart_send_byte(bfm.addr);
        bfm.uart_send_byte(bfm.port);
        bfm.addr = 8'b11111110;
        bfm.port = 8'b00000000;
        bfm.uart_send_byte(bfm.addr);
        bfm.uart_send_byte(bfm.port);
        bfm.addr = 8'b11111110;
        bfm.port = 8'b00000000;
        bfm.uart_send_byte(bfm.addr);
        bfm.uart_send_byte(bfm.port);
        bfm.addr = 8'b11111100;
        bfm.port = 8'b10000000;
        bfm.uart_send_byte(bfm.addr);
        bfm.uart_send_byte(bfm.port);

        bfm.prog = 0;
        bfm.target = 8'b11111111;         
        bfm.data = 8'b11111111;
        bfm.uart_send_byte(bfm.target);
        bfm.uart_send_byte(bfm.data);
        repeat(300) @(posedge bfm.clk);
        bfm.target = 8'b00000000;         
        bfm.data = 8'b11111111;
        bfm.uart_send_byte(bfm.target);
        bfm.uart_send_byte(bfm.data);
        repeat(300) @(posedge bfm.clk);
        bfm.target = 8'b11111110;         
        bfm.data = 8'b11111111;
        bfm.uart_send_byte(bfm.target);
        bfm.uart_send_byte(bfm.data);
        repeat(300) @(posedge bfm.clk);
        bfm.target = 8'b11111110;         
        bfm.data = 8'b00000000;
        bfm.uart_send_byte(bfm.target);
        bfm.uart_send_byte(bfm.data);
        repeat(300) @(posedge bfm.clk);
        bfm.target = 8'b11111110;         
        bfm.data = 8'b11111111;
        bfm.uart_send_byte(bfm.target);
        bfm.uart_send_byte(bfm.data);
        repeat(300) @(posedge bfm.clk);
        bfm.target = 8'b11111100;         
        bfm.data = 8'b11111111;
        bfm.uart_send_byte(bfm.target);
        bfm.send_wrong_packet(bfm.data);

        repeat(1000)@(posedge bfm.clk);

        `ifdef COVERAGE
        $display("Coverage: %0.2f%%", $get_coverage());
        `endif

        print_test_result(test_result);
        $finish;

    end

    //------------------------------------------------------------------------------
    // Other functions
    //------------------------------------------------------------------------------
    
    // used to modify the color of the text printed on the terminal
    function void set_print_color ( print_color_t c );
        string ctl;
        case(c)
            COLOR_BOLD_BLACK_ON_GREEN : ctl  = "\033\[1;30m\033\[102m";
            COLOR_BOLD_BLACK_ON_RED : ctl    = "\033\[1;30m\033\[101m";
            COLOR_BOLD_BLACK_ON_YELLOW : ctl = "\033\[1;30m\033\[103m";
            COLOR_BOLD_BLUE_ON_WHITE : ctl   = "\033\[1;34m\033\[107m";
            COLOR_BLUE_ON_WHITE : ctl        = "\033\[0;34m\033\[107m";
            COLOR_DEFAULT : ctl              = "\033\[0m\n";
            default : begin
                $error("set_print_color: bad argument");
                ctl                          = "";
            end
        endcase
        $write(ctl);
    endfunction
    
    function void print_test_result (test_result_t r);
        if(r == TEST_PASSED) begin
            set_print_color(COLOR_BOLD_BLACK_ON_GREEN);
            $write ("-----------------------------------\n");
            $write ("----------- Test PASSED -----------\n");
            $write ("-----------------------------------");
            set_print_color(COLOR_DEFAULT);
            $write ("\n");
        end
        else begin
            set_print_color(COLOR_BOLD_BLACK_ON_RED);
            $write ("-----------------------------------\n");
            $write ("----------- Test FAILED -----------\n");
            $write ("-----------------------------------");
            set_print_color(COLOR_DEFAULT);
            $write ("\n");
        end
    endfunction
    
    
    endmodule : top
    