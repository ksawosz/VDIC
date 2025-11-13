class coverage;
    protected virtual switch_bfm bfm;
    
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


    function new (virtual switch_bfm b);
        cov_data             = new();
        bfm                  = b;
    endfunction : new
    
    task execute();
        forever begin : sampling_block
            @(posedge bfm.clk);
            cov_data.sample();
        end : sampling_block
    endtask : execute
    
endclass : coverage
    