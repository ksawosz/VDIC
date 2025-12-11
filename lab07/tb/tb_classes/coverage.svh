class coverage extends uvm_subscriber #(packet_transaction);
    `uvm_component_utils(coverage)

    byte addr;
    byte data;
    bit err_packet;
    bit  rst_n;
    bit  sout0, sout1, sin, prog;
    
    covergroup cov_data;
    coverpoint addr {
        bins max0 = {8'b11111111};
        bins min0 = {8'b00000000};
    }
    coverpoint data {
        bins max1 = {8'b11111111};
        bins min1 = {8'b00000000};
    }
    coverpoint err_packet {
        bins err = {1};
        bins not_err = {0};
    }
    coverpoint sout1 {
        bins signal0 = {0};
        bins idle0 = {1};
    }
    coverpoint sout0 {
        bins signal0 = {0};
        bins idle0 = {1};
    }
    coverpoint sin {
        bins signal0 = {0};
        bins idle0 = {1};
    }
    coverpoint prog {
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
    // subscriber write function
    //------------------------------------------------------------------------------
        function void write(packet_transaction t);
            addr       = t.addr;
            data       = t.data;
            prog       = t.prog;
            cov_data.sample();
        endfunction : write
    
    
endclass : coverage
    