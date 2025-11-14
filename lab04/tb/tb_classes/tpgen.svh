class tbgen;
    protected virtual switch_bfm bfm;

    function new (virtual switch_bfm b);
        bfm = b;
    endfunction : new
    
    protected function byte get_data();
        bit [1:0] zero_ones;
        zero_ones = 2'($random);
        if (zero_ones == 2'b00)
            return 8'h00;
        else if (zero_ones == 2'b11)
            return 8'hFF;
        else
            return byte'($random);
    endfunction : get_data
    
    task execute();
        bfm.rst_n = 0;
        bfm.sin = 1;
        repeat(16) @(posedge bfm.clk); 
        bfm.rst_n = 1;
        repeat(16) @(posedge bfm.clk); 
        bfm.prog = 1;
        bfm.uart_send_byte(8'hFF);
        bfm.uart_send_byte(8'h00);
        repeat(1) @(posedge bfm.clk); 
        bfm.uart_send_byte(8'h00);
        bfm.uart_send_byte(8'h80);
        repeat(1) @(posedge bfm.clk); 
        bfm.prog = 0;
        bfm.uart_send_byte(8'h00);
        bfm.uart_send_byte(8'hFF);
        repeat(1) @(posedge bfm.clk); 
        bfm.uart_send_byte(8'hFF);
        bfm.uart_send_byte(8'h00);
        bfm.uart_send_byte(8'h00);
        bfm.send_wrong_packet(8'h00);
        bfm.rst_n = 0;
        bfm.prog = 1;
        bfm.uart_send_byte(8'hFF);
        bfm.uart_send_byte(8'h00);
        bfm.prog = 0;
        bfm.uart_send_byte(8'hFF);
        bfm.uart_send_byte(8'h00);
        repeat(1000) @(posedge bfm.clk);
        $display("Test sequence complete");
    
    endtask : execute
    
endclass : tbgen
    