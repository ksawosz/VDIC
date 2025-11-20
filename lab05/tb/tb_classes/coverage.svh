class coverage extends uvm_component;
    `uvm_component_utils(coverage)

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

    //------------------------------------------------------------------------------
    // constructor
    //------------------------------------------------------------------------------
        function new (string name, uvm_component parent);
            super.new(name, parent);
            cov_data               = new();
        endfunction : new

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
            forever begin : sampling_block
                @(posedge bfm.clk);
                cov_data.sample();
            end : sampling_block
        endtask : run_phase

    
    
endclass : coverage
    