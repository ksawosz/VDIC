package switch_tb_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"
  
    typedef struct packed {
        logic [7:0] addr;
        logic [7:0] data;
        bit          port;
        bit          is_prog;
        bit          rst_n;
        bit          is_err;
    } pkt_t;

    // terminal print colors
    typedef enum {
        COLOR_BOLD_BLACK_ON_GREEN,
        COLOR_BOLD_BLACK_ON_RED,
        COLOR_BOLD_BLACK_ON_YELLOW,
        COLOR_BOLD_BLUE_ON_WHITE,
        COLOR_BLUE_ON_WHITE,
        COLOR_DEFAULT
    } print_color;

    typedef enum {NONE, START, PARITY, STOP} e_mistake;

    typedef struct packed{
        logic [0:10] addr;
        logic [0:10] data;
        bit prog;
    } read_sin;
    
    typedef struct packed{
        logic [0:10] addr;
        logic [0:10] data;
        bit port;
    } read_sout;

//------------------------------------------------------------------------------
// package functions
//------------------------------------------------------------------------------

    // used to modify the color of the text printed on the terminal

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

    function e_mistake checking(input bit [0:10] packet);
        if(packet[0] != 0) begin
            return START;
        end
        if(packet[9] !=^ packet[1:8]) begin
            return PARITY;
        end
        if(packet[10] != 1) begin
            return STOP;
        end
        return NONE;
    endfunction

//------------------------------------------------------------------------------
// testbench classes
//------------------------------------------------------------------------------
`include "coverage.svh"
`include "base_tpgen.svh"
`include "random_tpgen.svh"
`include "corner_tpgen.svh"
`include "scoreboard.svh"
`include "driver.svh"
`include "packet_monitor.svh"
`include "result_monitor.svh"
`include "env.svh"

//------------------------------------------------------------------------------
// test classes
//------------------------------------------------------------------------------
`include "random_test.svh"
`include "corner_test.svh"
  
  endpackage : switch_tb_pkg
  