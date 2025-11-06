interface switch_bfm; 
import switch_tb_pkg::*;

bit                  clk;
bit                  sin;
bit                  rst_n;
bit                  prog;
bit                  sout0;
bit                  sout1;
byte                 addr, port, target, data;
bit                  err_packet;

modport tlm (import uart_send_byte, send_wrong_packet);

//------------------------------------------------------------------------------
// clock generator  
//------------------------------------------------------------------------------
initial begin
    clk = 0;
    forever begin
        #10;
        clk = ~clk;
    end
end

task uart_send_byte(input byte data);
    int i; 
    bit parity;
    sin = 0; repeat (16) @(posedge clk);
    parity = 0;
    for (i = 7; i >= 0; i--) begin
        sin = data[i];
        parity ^= data[i];
        repeat (16) @(posedge clk);
    end
    sin = parity; repeat (16) @(posedge clk);
    sin = 1; repeat (16) @(posedge clk);
endtask

task send_wrong_packet(input byte data);
    int i; 
    bit parity;
    sin = 0; repeat (16) @(posedge clk);
    parity = 0;
    for (i = 7; i >= 0; i--) begin
        sin = data[i];
        parity ^= data[i];
        repeat (16) @(posedge clk);
    end
    sin = ~parity; repeat (16) @(posedge clk);
    sin = 1; repeat (16) @(posedge clk);
endtask

endinterface : switch_bfm
