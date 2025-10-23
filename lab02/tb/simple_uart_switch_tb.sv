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
 2021-10-05 RSz, AGH UST - test modified to send all the data on negedge clk
 and check the data on the correct clock edge (covergroup on posedge
 and scoreboard on negedge). Scoreboard and coverage removed.
 */
module top;

    //------------------------------------------------------------------------------
    // Type definitions
    //------------------------------------------------------------------------------
    
    typedef enum bit {
        TEST_PASSED,
        TEST_FAILED
    } test_result_t;

    typedef enum {
        COLOR_BOLD_BLACK_ON_GREEN,
        COLOR_BOLD_BLACK_ON_RED,
        COLOR_BOLD_BLACK_ON_YELLOW,
        COLOR_BOLD_BLUE_ON_WHITE,
        COLOR_BLUE_ON_WHITE,
        COLOR_DEFAULT
    } print_color_t;

    //`define DEBUG
    
    //------------------------------------------------------------------------------
    // Local variables
    //------------------------------------------------------------------------------

    bit                  clk;
    bit                  rst_n;
    bit                  prog;
    bit                  sin;
    bit                  sout0;
    bit                  sout1;
    
    test_result_t        test_result = TEST_PASSED;
    logic                [21:0] data_out;
    bit                  packet_end;

    typedef struct packed {
        logic [10:0] addr;  
        bit         port;   
        bit         is_prog; 
        bit         is_err;
    } pkt_t;
    
    pkt_t data_queue[$];
    
    
    //------------------------------------------------------------------------------
    // DUT instantiation
    //------------------------------------------------------------------------------
    
    simple_switch_uart DUT (.clk, .rst_n, .prog, .sin, .sout0, .sout1);
    
    //------------------------------------------------------------------------------
    // Clock generator
    //------------------------------------------------------------------------------
    
    initial begin : clk_gen_blk
        clk = 0;
        forever begin : clk_frv_blk
            #10;
            clk = ~clk;
        end
    end
    
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

    task uart_send_byte(input byte data);
        int i;
        bit parity;
        
        sin = 0;
        repeat (16) @(posedge clk);

        parity = 0;
        for(i = 7; i >= 0; i--) begin
            sin = data[i];
            parity ^= data[i];
            repeat (16) @(posedge clk);
        end

        sin = parity;
        repeat (16) @(posedge clk);

        sin = 1;
        repeat (16) @(posedge clk);

    endtask


    task send_wrong_packet(input byte data);
        int i;
        bit parity;
        
        sin = 0;
        repeat (16) @(posedge clk);

        parity = 0;
        for(i = 7; i >= 0; i--) begin
            sin = data[i];
            parity ^= data[i];
            repeat (16) @(posedge clk);
        end

        sin = ~parity;
        repeat (16) @(posedge clk);

        sin = 1;
        repeat (16) @(posedge clk);

    endtask

    task check_sout(input byte port);
    endtask

    initial begin
        int i;
        bit parity;
        logic [11:0] addr_port;
        pkt_t newpkt;
        bit err_packet;
        parity = 0;
        data_out[21:0] = 0;
        err_packet = 0;

        forever begin
            @(negedge sin);
            err_packet = 0;

            for(int k = 0; k < 2; k++) begin
                parity = 0;
                repeat (8) @(posedge clk);
                `ifdef DEBUG
                $display("1 err = ", err_packet);
                `endif
                if(sin == 0) begin
                    if(!k) begin
                        data_out[0] = sin;
                    end
                    else begin
                        data_out[11] = sin;
                    end
                end
                else begin
                    err_packet = 1;
                end
                `ifdef DEBUG
                $display("2 err = ", err_packet);
                `endif

                for(i = 0; i < 8; i++) begin
                    repeat (16) @(posedge clk);
                    if(!k) begin
                        data_out[i+1] = sin;
                        parity ^= data_out[i+1];
                    end
                    else begin
                        data_out[i+12] = sin;
                        parity ^= data_out[i+12];
                    end
                end

                repeat (16) @(posedge clk);
                if(sin == parity) begin
                    if(!k) begin
                        data_out[9] = sin;
                    end
                    else begin
                        data_out[20] = sin;
                    end
                end
                else begin
                    err_packet = 1;
                end
                `ifdef DEBUG
                $display("3 err = ", err_packet);
                `endif

                repeat (16) @(posedge clk);
                if(sin == 1) begin
                    if(!k) begin
                        data_out[10] = sin;
                    end
                    else begin
                        data_out[21] = sin;
                    end
                end
                else begin
                    err_packet = 1;
                end
                `ifdef DEBUG
                $display("4 err = ", err_packet);
                `endif

                repeat (8) @(posedge clk);
            end
        
                newpkt.addr    = data_out[8:1];     
                newpkt.port    = data_out[12];       
                newpkt.is_prog = prog;               
                newpkt.is_err  = err_packet;
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
        int        fi;
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
                            repeat (8) @(posedge clk);
                            
                            if (expected_port == 0) begin
                                if (sout0 == pkt.is_err) begin

                                    `ifdef DEBUG
                                    $display("\n[%0t] PASS: Dane dla addr=0x%0h pojawiły się na sout0\n", $time, pkt.addr);
                                    `endif
                                    
                                    if(pkt.is_err == 0) begin
                                        for(int h=0; h<22; h++) begin
                                            if(data_out[h] != sout0) begin

                                                `ifdef DEBUG
                                                $display("dataot = ", data_out[h]," sout0 = ", sout0);
                                                `endif

                                                test_result = TEST_FAILED;
                                            end
                                            repeat (16) @(posedge clk);
                                        end
                                    end
                                    else begin
                                        for(int h=0; h<22; h++) begin
                                            if(sout0 != 1) begin
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
                                if (sout1 == pkt.is_err) begin

                                    `ifdef DEBUG
                                    $display("[%0t] PASS: Dane dla addr=0x%0h pojawiły się na sout1", $time, pkt.addr);
                                    `endif

                                    if(pkt.is_err == 0) begin
                                        for(int h=0; h<22; h++) begin
                                            if(data_out[h] != sout1) begin

                                                `ifdef DEBUG
                                                $display("dataot = ", data_out[h]," sout1 = ", sout1);
                                                `endif

                                                test_result = TEST_FAILED;
                                            end
                                            repeat (16) @(posedge clk);
                                        end
                                    end
                                    else begin
                                        for(int h=0; h<22; h++) begin
                                            if(sout1 != 1) begin
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
    

    
    
    //------------------------
    // Tester main

    initial begin
        byte addr, port, target, data;
        sin = 1;
        rst_n = 0;
        repeat (16) @(posedge clk);
        rst_n = 1;

        prog = 1;
        addr = 8'b11100011;
        port = 8'b10000000;
        uart_send_byte(addr);
        uart_send_byte(port);
        addr = 8'b11111110;
        port = 8'b00000000;
        uart_send_byte(addr);
        uart_send_byte(port);
        addr = 8'b11111110;
        port = 8'b00000000;
        uart_send_byte(addr);
        uart_send_byte(port);
        addr = 8'b11111110;
        port = 8'b00000000;
        uart_send_byte(addr);
        uart_send_byte(port);
        addr = 8'b11111110;
        port = 8'b00000000;
        uart_send_byte(addr);
        uart_send_byte(port);
        addr = 8'b11111100;
        port = 8'b10000000;
        uart_send_byte(addr);
        uart_send_byte(port);

        prog = 0;
        target = 8'b11100011;         
        data = 8'b11111111;
        uart_send_byte(target);
        uart_send_byte(data);
        repeat(300) @(posedge clk);
        target = 8'b11111110;         
        data = 8'b11111111;
        uart_send_byte(target);
        uart_send_byte(data);
        repeat(300) @(posedge clk);
        target = 8'b11111110;         
        data = 8'b11111111;
        uart_send_byte(target);
        uart_send_byte(data);
        repeat(300) @(posedge clk);
        target = 8'b11111110;         
        data = 8'b11111111;
        uart_send_byte(target);
        uart_send_byte(data);
        repeat(300) @(posedge clk);
        target = 8'b11111110;         
        data = 8'b11111111;
        uart_send_byte(target);
        uart_send_byte(data);
        repeat(300) @(posedge clk);
        target = 8'b11111100;         
        data = 8'b11111111;
        uart_send_byte(target);
        send_wrong_packet(data);

        repeat(1000)@(posedge clk);

        /*if(OK_bit == function_call * 11) begin
            test_result = TEST_PASSED;
        end
        else begin
            test_result = TEST_FAILED;
        end*/
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
    