package switch_tb_pkg;
  
    typedef struct packed {
        logic [7:0] addr;
        bit          port;
        bit          is_prog;
        bit          is_err;
    } pkt_t;
  
`include "coverage.svh"
`include "tpgen.svh"
`include "scoreboard.svh"
`include "testbench.svh"
  
  endpackage : switch_tb_pkg
  