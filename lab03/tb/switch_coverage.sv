module switch_coverage(switch_bfm bfm);
import switch_tb_pkg::*;

bit                  prog;
bit                  sin;
bit                  sout0;
bit                  sout1;
byte                 addr, port, target, data;
bit                  err_packet;

covergroup cov_data @(posedge bfm.clk);
coverpoint addr {
    bins max0 = {8'b11111111};
    bins min0 = {8'b00000000};
}
coverpoint target {
    bins max1 = {8'b11111111};
    bins min1 = {8'b00000000};
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

cov_data cover_addr;

endmodule : switch_coverage
