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
    // reset task
    //------------------------------------------------------------------------------
    
    task reset_uart();
        rst_n = 0;
        prog = 0;
        sin = 1;
        repeat (5) @(posedge clk);
        rst_n = 1'b1;
        repeat (5) @(posedge clk);
    endtask 
    
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
        for(i = 0; i <= 8; i++) begin
            sin = data[i];
            parity ^= data[i];
            repeat (16) @(posedge clk);
        end

        sin = ~parity;
        repeat (16) @(posedge clk);

        sin = 1;
        repeat (16) @(posedge clk);

    endtask
    
    //------------------------
    // Tester main
    
    initial begin
        byte addr, port, target, data;
        reset_uart();

        prog = 1;
        repeat (1) begin
            //addr = get_data();
            //port = $urandom_range(0, 1);
            addr = 8'b11111110;
            port = 0;
            uart_send_byte(addr);
            uart_send_byte(port);
            $display("[%0t] Programmed addr=%0h -> port=%0d", $time, addr, port);
        end

        repeat (50) @(posedge clk);

        prog = 0;
        repeat (5) begin
            target = addr;
            data = 8'b11100010;
            uart_send_byte(target);
            uart_send_byte(data);
            $display("[%0t] Programmed target=%0h -> data=%0d", $time, target, data);
        end

        print_test_result(test_result);
        $finish;
    end
    
    //------------------------------------------------------------------------------
    // Temporary. The scoreboard will be later used for checking the data
    final begin : finish_of_the_test
        print_test_result(test_result);
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
    