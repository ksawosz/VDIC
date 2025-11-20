class scoreboard;

    //------------------------------------------------------------------------------
    // local typdefs
    //------------------------------------------------------------------------------
    protected typedef enum bit {
        TEST_PASSED,
        TEST_FAILED
    } test_result;

    protected typedef enum {
        COLOR_BOLD_BLACK_ON_GREEN,
        COLOR_BOLD_BLACK_ON_RED,
        COLOR_BOLD_BLACK_ON_YELLOW,
        COLOR_BOLD_BLUE_ON_WHITE,
        COLOR_BLUE_ON_WHITE,
        COLOR_DEFAULT
    } print_color;

    protected typedef struct packed{
        logic [7:0] addr;
        bit port;
    } addr_map_t;

    //`define DEBUG

    //------------------------------------------------------------------------------
    // local variables
    //------------------------------------------------------------------------------

    local virtual switch_bfm bfm;
    local test_result tr = TEST_PASSED; // the result of the current test

    local addr_map_t prog_table[$];
    pkt_t pkt;
    pkt_t data_queue[$];
    logic packet_end;
    logic [21:0] data_out;

    //------------------------------------------------------------------------------
    // constructor
    //------------------------------------------------------------------------------
    function new (virtual switch_bfm b);
        bfm = b;
    endfunction : new

    //------------------------------------------------------------------------------
    // local tasks
    //------------------------------------------------------------------------------
    local task store_packet();
        int i;
        bit parity;
        logic [11:0] addr_port;
        pkt_t newpkt;
        parity = 0;
        data_out[21:0] = 0;
        bfm.err_packet = 0;

        forever begin
            @(negedge bfm.sin);
            newpkt.is_prog = bfm.prog;
            bfm.err_packet = 0;
            data_out[21:0] = 0;
            bfm.err_packet = 0;

            for(int k = 0; k < 2; k++) begin
                parity = 0;
                repeat (8) @(posedge bfm.clk);
                `ifdef DEBUG
                $display("1 err = ", bfm.err_packet);
                `endif
                if(bfm.sin == 0) begin
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
                $display("2 err = ", bfm.err_packet);
                `endif

                for(i = 9; i > 1; i--) begin
                    repeat (16) @(posedge bfm.clk);
                    if(!k) begin
                        data_out[i] = bfm.sin;
                        parity ^= data_out[i];
                    end
                    else begin
                        data_out[i+11] = bfm.sin;
                        parity ^= data_out[i+11];
                    end
                end

                repeat (16) @(posedge bfm.clk);
                if(bfm.sin == parity) begin
                    if(!k) begin
                        data_out[1] = bfm.sin;
                    end
                    else begin
                        data_out[12] = bfm.sin;
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
                $display("4 err = ", bfm.err_packet);
                `endif

                repeat (8) @(posedge bfm.clk);
            end

            newpkt.addr    = data_out[9:2];
            newpkt.port    = data_out[20];
            newpkt.is_err  = bfm.err_packet;
            data_queue.push_back(newpkt);


            packet_end = 1;
        end
    endtask

    local task compare_output();
        bit expected_port;

        forever begin
            wait (packet_end == 1);
            packet_end = 0;

            for (int i = 0; i < data_queue.size(); i++) begin
                pkt_t pkt = data_queue[i];

                if (pkt.is_err) begin
                    `ifdef DEBUG
                    $display("[SB] ERR: DUT received wrong packet: addr=%0h port=%0b",
                        pkt.addr, pkt.port);
                    `endif
                    if(bfm.sout0 == 0 || bfm.sout1 == 0) begin
                        tr = TEST_FAILED;
                    end
                    continue;
                end

                if (pkt.is_prog) begin
                    int idx[$] = prog_table.find_index with (item.addr == pkt.addr);

                    if (idx.size() == 0) begin
                        addr_map_t entry = '{pkt.addr, pkt.port};
                        prog_table.push_back(entry);
                        `ifdef DEBUG
                        $display("[SB] Added new mapping: addr=%0h -> port=%0b",
                            pkt.addr, pkt.port);
                        `endif
                    end else begin
                        prog_table[idx[0]].port = pkt.port;
                        `ifdef DEBUG
                        $display("[SB] Updated mapping: addr=%0h -> port=%0b",
                            pkt.addr, pkt.port);
                        `endif
                    end
                end
                else begin
                    int idx[$] = prog_table.find_index with (item.addr == pkt.addr);

                    if (idx.size() == 0) begin
                        $display("[SB] prog=0 ERR: Unknown address %0h (not programmed!)", pkt.addr);
                        continue;
                    end

                    expected_port = prog_table[idx[0]].port;

                    if (expected_port !== pkt.port) begin
                        `ifdef DEBUG
                        $display("[SB] ERR: Port mismatch for addr %0h: expected=%0b got=%0b",
                            pkt.addr, expected_port, pkt.port);
                        `endif
                        tr = TEST_FAILED;
                    end
                end
            end

            // clear queue after processing
            data_queue.delete();
        end
    endtask

    task execute();
        fork
            store_packet();
            compare_output();
        join_none
    endtask

    //------------------------------------------------------------------------------
    // used to modify the color printed on the terminal
    //------------------------------------------------------------------------------

    local function void set_print_color ( print_color c );
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
    local function void print_test_result (test_result r);
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
    function void print_result();
        print_test_result(tr);
    endfunction

endclass : scoreboard
