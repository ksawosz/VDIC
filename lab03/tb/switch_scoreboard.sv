module switch_scoreboard (switch_bfm bfm);

import switch_tb_pkg::*;

//------------------------------------------------------------------------------
// local typdefs
//------------------------------------------------------------------------------
typedef enum bit {
    TEST_PASSED,
    TEST_FAILED
} test_result;

typedef enum {
    COLOR_BOLD_BLACK_ON_GREEN,
    COLOR_BOLD_BLACK_ON_RED,
    COLOR_BOLD_BLACK_ON_YELLOW,
    COLOR_BOLD_BLUE_ON_WHITE,
    COLOR_BLUE_ON_WHITE,
    COLOR_DEFAULT
} print_color;

typedef struct{
    logic [7:0] addr;
    bit port;
} addr_map_t;

//`define DEBUG

//------------------------------------------------------------------------------
// local variables
//------------------------------------------------------------------------------

test_result   tr             = TEST_PASSED; // the result of the current test

addr_map_t prog_table[$];
pkt_t pkt;
pkt_t data_queue[$];
bit packet_end;
logic [21:0] data_out;

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

initial begin
    tr = TEST_PASSED;
    forever begin
        wait (packet_end == 1);
        packet_end = 0;

        for (int i = 0; i < data_queue.size(); i++) begin
            pkt = data_queue[i];

            if (pkt.is_prog) begin
                int idx[$] = prog_table.find_index with (item.addr == pkt.addr);
                if (idx.size() == 0) begin
                    addr_map_t new_entry = '{pkt.addr, pkt.port};
                    prog_table.push_back(new_entry);
                end 
                else begin
                    prog_table[idx[0]].port = pkt.port;
                end
            end 
            else begin
                int idx[$] = prog_table.find_index with (item.addr == pkt.addr);
                if (idx.size() == 0) begin
                    $display("Unknown address %0h at time %0t", pkt.addr, $time);
                end
            end
        end
    end
end

//------------------------------------------------------------------------------
// used to modify the color printed on the terminal
//------------------------------------------------------------------------------

function void set_print_color ( print_color c );
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

//------------------------------------------------------------------------------
// print the PASSED/FAILED in color
//------------------------------------------------------------------------------
function void print_test_result (test_result r);
    if(tr == TEST_PASSED) begin
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

//------------------------------------------------------------------------------
// print the test result at the simulation end
//------------------------------------------------------------------------------
final begin : finish_of_the_test
    print_test_result(tr);
end

endmodule : switch_scoreboard
