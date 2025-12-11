class scoreboard extends uvm_subscriber #(result_transaction);
    `uvm_component_utils(scoreboard)

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
        logic [0:10] addr;
        logic [0:10] data;
        bit port;
    } check_sin;

   // `define DEBUG

    //------------------------------------------------------------------------------
    // local variables
    //------------------------------------------------------------------------------

    //protected virtual switch_bfm bfm;
    uvm_tlm_analysis_fifo #(packet_transaction) pkt_f;

    local test_result tr = TEST_PASSED; // the result of the current test

    protected read_sin in_sin[$];
    protected read_sout out_sout[$];
    protected check_sin check_sin1[$];
    protected read_sout check_sin0[$];
    logic packet_end;
    logic [21:0] data_out;

    //------------------------------------------------------------------------------
    // constructor
    //------------------------------------------------------------------------------
    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

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
    // build phase
    //------------------------------------------------------------------------------
    function void build_phase(uvm_phase phase);
        pkt_f = new ("pkt_f", this);
    endfunction : build_phase


    //------------------------------------------------------------------------------
    // local tasks
    //------------------------------------------------------------------------------

    function void sin_checking(packet_transaction temp_sin);
        int x[$];
        read_sin temp0;
        check_sin temp1;
        read_sout temp2;
        temp0.addr = temp_sin.addr;
        temp0.data = temp_sin.data;
        temp0.prog = temp_sin.prog;
            // === DEBUG temp0 ===
        `ifdef DEBUG
        $display("[sin_checking] @%0t temp0.addr = %0b", $time, temp0.addr);
        $display("[sin_checking] @%0t temp0.data = %0b", $time, temp0.data);
        $display("[sin_checking] @%0t temp0.prog = %0d", $time, temp0.prog);
        $display("[sin_checking] @%0t in_sin.size after pop = %0d",
                $time, in_sin.size());
        `endif
        if((checking(temp0.addr) == NONE) && (checking(temp0.data) == NONE)) begin
            if(temp0.prog == 1) begin
                temp1.addr = temp0.addr;
                temp1.port = temp0.data[1];
                // === DEBUG temp1 ===
                `ifdef DEBUG
                $display("[sin_checking] temp1 created:");
                $display("[sin_checking]  temp1.addr = %0b", temp1.addr);
                $display("[sin_checking]  temp1.port = %0d", temp1.port);
                `endif
                check_sin1.push_back(temp1);
            end
            else if (temp0.prog == 0) begin
                x = check_sin1.find_index with (item.addr == temp0.addr);
                // === DEBUG wyszukiwanie ===
                `ifdef DEBUG
                $display("[sin_checking] x (found indexes) = %p", x);
                $display("[sin_checking] check_sin1.size = %0d", check_sin1.size());
                `endif
                if(x.size() > 0) begin
                    temp2.addr = temp0.addr;
                    temp2.data = temp0.data;
                    temp2.port = check_sin1[x[0]].port;
                    // === DEBUG temp2 ===
                    `ifdef DEBUG
                    $display("[sin_checking] temp2 created:");
                    $display("[sin_checking]  temp2.addr = %0b", temp2.addr);
                    $display("[sin_checking]  temp2.data = %0b", temp2.data);
                    $display("[sin_checking]  temp2.port = %0d", temp2.port);
                    `endif
                    check_sin0.push_back(temp2);
                end
            end
        end
        

        // === DEBUG kolejek ===
        `ifdef DEBUG
        $display("[sin_checking] check_sin1.size = %0d", check_sin1.size());
        $display("[sin_checking] check_sin0.size = %0d", check_sin0.size());
        `endif
    endfunction

    function void sout_checking(read_sout z);
        int y[$];
            // === DEBUG z ===
            `ifdef DEBUG
            $display("[sout_checking] @%0t Popped z:", $time);
            $display("[sout_checking]  z.addr = %p", z.addr);
            $display("[sout_checking]  z.data = %p", z.data);
            $display("[sout_checking]  z.port = %0d", z.port);
            $display("[sout_checking]  out_sout.size after pop = %0d", out_sout.size());
            `endif

        // === DEBUG: próbujemy znaleźć z w check_sin0 ===
        //$display("[sout_checking] check_sin0.size = %0d", check_sin0.size());
        y = check_sin0.find_index with (item.addr == z.addr && 
                                        item.data == z.data && 
                                        item.port == z.port);

        //$display("[sout_checking] Find_index result y = %p", y);

        if (y.size() > 0) begin
            // === DEBUG o znalezieniu ===
            `ifdef DEBUG
            $display("[sout_checking] MATCH found at index %0d — deleting", y[0]);
            $display("[sout_checking]  check_sin0[y[0]].addr = %p", check_sin0[y[0]].addr);
            $display("[sout_checking]  check_sin0[y[0]].data = %p", check_sin0[y[0]].data);
            $display("[sout_checking]  check_sin0[y[0]].port = %0d", check_sin0[y[0]].port);
            `endif

            check_sin0.delete(y[0]);
            
            `ifdef DEBUG
            $display("[sout_checking] New check_sin0.size = %0d",
                    check_sin0.size());
            `endif
        end
    endfunction

    //------------------------------------------------------------------------------
    // subscriber write function
    //------------------------------------------------------------------------------
        function void write(result_transaction t);
            packet_transaction pkt;
            while(!pkt_f.is_empty()) begin
                if(!pkt_f.try_get(pkt)) begin
                    sin_checking(pkt);
                end
            end
            sout_checking(t.result);
        endfunction

    //------------------------------------------------------------------------------
    // report phase
    //------------------------------------------------------------------------------
        function void report_phase(uvm_phase phase);
            super.report_phase(phase);
            if(check_sin0.size() != 0) begin
                tr = TEST_FAILED;
            end
            print_test_result(tr);
        endfunction : report_phase

endclass : scoreboard
