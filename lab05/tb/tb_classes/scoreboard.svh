class scoreboard extends uvm_component;
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
        bit prog;
    } read_sin;

    protected typedef struct packed{
        logic [0:10] addr;
        logic [0:10] data;
        bit port;
    } read_sout;

    protected typedef struct packed{
        logic [0:10] addr;
        logic [0:10] data;
        bit port;
    } check_sin;

    //`define DEBUG

    //------------------------------------------------------------------------------
    // local variables
    //------------------------------------------------------------------------------

    protected virtual switch_bfm bfm;
    protected test_result tr = TEST_PASSED; // the result of the current test

    protected read_sin in_sin[$];
    protected read_sout out_sout[$];
    protected check_sin check_sin1[$];
    protected read_sout check_sin0[$];
    pkt_t pkt;
    pkt_t data_queue[$];
    logic packet_end;
    logic [21:0] data_out;

    //------------------------------------------------------------------------------
    // constructor
    //------------------------------------------------------------------------------
    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    //------------------------------------------------------------------------------
    // local tasks
    //------------------------------------------------------------------------------
    protected task queue_sin();
        int i;
        int j;
        read_sin temp;
        forever begin
            @(negedge bfm.sin);
            repeat (8) @(posedge bfm.clk);
            for(i=0; i<=10; i++) begin
                temp.addr[i] = bfm.sin;
                repeat (16) @(posedge bfm.clk);
            end

            for(j=0; j<=9; j++) begin
                temp.data[j] = bfm.sin;
                repeat (16) @(posedge bfm.clk);
            end

            temp.data[10] = bfm.sin;

            if(bfm.prog == 1) begin
                temp.prog = 1;
            end
            else begin
                temp.prog = 0;
            end

            in_sin.push_back(temp);
        end
    endtask

    protected task queue_sout();
        int i, j, k, l;
        read_sout temp;
        forever begin
            @(negedge bfm.sout0 or negedge bfm.sout1);
            repeat (8) @(posedge bfm.clk);
            if(bfm.sout0 == 0) begin
                for(i=0; i<=10; i++) begin
                    temp.addr[i] = bfm.sout0;
                    repeat (16) @(posedge bfm.clk);
                end

                for(j=0; j<=9; j++) begin
                    temp.data[j] = bfm.sout0;
                    repeat (16) @(posedge bfm.clk);
                end

                temp.data[10] = bfm.sout0;

                temp.port = 0;
            end
            else begin
                for(k=0; k<=10; k++) begin
                    temp.addr[k] = bfm.sout1;
                    repeat (16) @(posedge bfm.clk);
                end

                for(l=0; l<=9; l++) begin
                    temp.data[l] = bfm.sout1;
                    repeat (16) @(posedge bfm.clk);
                end

                temp.data[10] = bfm.sout1;

                temp.port = 1;
            end

            out_sout.push_back(temp);
        end
    endtask

    protected task sin_checking();
        int x[$];
        check_sin temp1;
        read_sout temp2;
        read_sin temp0;
        forever begin
            @(posedge bfm.clk);
            if(in_sin.size() != 0) begin
                temp0 = in_sin.pop_front();
                if((checking(temp0.addr) == NONE) && (checking(temp0.data) == NONE)) begin
                    if(temp0.prog == 1) begin
                        temp1.addr = temp0.addr;
                        temp1.port = temp0.data[1];
                    end
                    else if (temp0.prog == 0) begin
                        x = check_sin1.find_index with (item.addr == temp0.addr);
                        if(x.size() > 0) begin
                            temp2.addr = temp0.addr;
                            temp2.data = temp0.data;
                            temp2.port = check_sin1[x[0]].port;
                        end
                    end
                end

                check_sin1.push_back(temp1);
                check_sin0.push_back(temp2);
            end
        end
    endtask

    protected task sout_checking();
        read_sout z;
        int y[$];
        forever begin
            @(posedge bfm.clk);
            if (out_sout.size() > 0) begin
                z = out_sout.pop_front();
            end
        
            y = check_sin0.find_index with (item.addr == z.addr && 
                                            item.data == z.data && 
                                            item.port == z.port);
        
            if (y.size() > 0) begin
                check_sin0.delete(y[0]);
            end
        end
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
            fork
                queue_sin();
                queue_sout();
                sin_checking();
                sout_checking();
            join_none
        endtask : run_phase

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
