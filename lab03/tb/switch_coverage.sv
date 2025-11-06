module switch_coverage(switch_bfm bfm);
import switch_tb_pkg::*;

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

cov_data cover_addr;

initial begin : coverage_block
    cover_addr      = new();
    forever begin : sampling_block
        @(posedge bfm.clk);
        cover_addr.sample();
    end : sampling_block
end : coverage_block

endmodule : switch_coverage
