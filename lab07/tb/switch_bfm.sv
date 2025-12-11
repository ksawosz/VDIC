import switch_tb_pkg::*;
interface switch_bfm; 

bit                  clk;
bit                  sin;
bit                  rst_n;
bit                  prog;
bit                  sout0;
bit                  sout1;
logic [10:0]                 addr, port, target, data;
bit                  is_err;

//`define DEBUG
//------------------------------------------------------------------------------
// local variables
//------------------------------------------------------------------------------

packet_monitor packet_monitor_h;
result_monitor result_monitor_h;

read_sin in_sin[$];
read_sout out_sout[$];

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

task uart_send_byte(input byte data, input bit is_err);
    int i; 
    bit parity;
    sin = 0; repeat (16) @(posedge clk);
    parity = 0;
    for (i = 7; i >= 0; i--) begin
        sin = data[i];
        parity ^= data[i];
        repeat (16) @(posedge clk);
    end
    if(is_err == 0) begin
        sin = parity; repeat (16) @(posedge clk);
    end
    else begin
        sin = ~parity; repeat (16) @(posedge clk);
    end
    sin = 1; repeat (16) @(posedge clk);
endtask


//------------------------------------------------------------------------------
// write packet monitor
//------------------------------------------------------------------------------

initial begin
        int i;
        int j;
        packet_transaction temp;
        read_sin original;
        temp = new("temp");
        forever begin
            @(negedge sin);
            `ifdef DEBUG
            $display("[QS] Detected start bit at time %0t, sin=%0b", $time, sin);
            `endif
            repeat (8) @(posedge clk);
            for(i=0; i<=10; i++) begin
                original.addr[i] = sin;
                `ifdef DEBUG
                $display("[QS] ADDR[%0d] = %0b (time %0t)", i, original.addr[i], $time);
                `endif
                repeat (16) @(posedge clk);
            end
    
            for(j=0; j<=9; j++) begin
                original.data[j] = sin;
                `ifdef DEBUG
                $display("[QS] DATA[%0d] = %0b (time %0t)", j, original.data[j], $time);
                `endif
                repeat (16) @(posedge clk);
            end
    
            original.data[10] = sin;
            `ifdef DEBUG
            $display("[QS] DATA[10] = %0b (time %0t)", original.data[10], $time);
            `endif
    
            if(prog == 1) begin
                original.prog = 1;
            end
            else begin
                original.prog = 0;
            end
            `ifdef DEBUG
            $display("[QS] PROG = %0b (time %0t)", original.prog, $time);
            `endif

            temp.addr = original.addr;
            temp.data = original.data;
            temp.prog = original.prog;
    
            packet_monitor_h.write_to_monitor(temp);
    
            `ifdef DEBUG
            // WYŚWIETL STRUKTURĘ TEMP
            $display("[QS] --- TEMP STRUCTURE ADDED ---");
            $display("[QS] ADDR = %0b", temp.addr);
            $display("[QS] DATA = %0b", temp.data);
            $display("[QS] PROG = %0b", temp.prog);
    
            // WYŚWIETL ROZMIAR KOLEJKI
            $display("[QS] in_sin size = %0d", in_sin.size());
    
            // WYŚWIETL OSTATNI ELEMENT KOLEJKI
            $display("[QS] in_sin[$] = { addr=%0b, data=%0b, prog=%0b }",
                    in_sin[$].addr,
                    in_sin[$].data,
                    in_sin[$].prog);
    
            $display("[QS] -----------------------------\n");
            `endif
        end
end

initial begin
        int i, j, k, l;
        read_sout temp;
        result_transaction result;
        result = new("result");
        forever begin
            @(negedge sout0 or negedge sout1);
            `ifdef DEBUG
            $display("\n[QSOUT] Start of packet at time %0t (sout0=%0b sout1=%0b)",
                 $time, sout0, sout1);
            `endif
            repeat (8) @(posedge clk);
            if(sout0 == 0) begin
                // READ ADDR
                `ifdef DEBUG
                $display("[QSOUT] -- READING ADDR (port 0) --");
                `endif
                for(i=0; i<=10; i++) begin
                    temp.addr[i] = sout0;
                    `ifdef DEBUG
                    $display("[QSOUT] PORT0 ADDR[%0d] = %0b (time %0t)",
                         i, temp.addr[i], $time);
                    `endif
                    repeat (16) @(posedge clk);
                end
    
                // READ DATA
                for(j=0; j<=9; j++) begin
                    temp.data[j] = sout0;
                    `ifdef DEBUG
                    $display("[QSOUT] PORT0 DATA[%0d] = %0b (time %0t)",
                         j, temp.data[j], $time);
                    `endif
                    repeat (16) @(posedge clk);
                end
    
                temp.data[10] = sout0;
                `ifdef DEBUG
                $display("[QSOUT] PORT0 DATA[10] = %0b (time %0t)",
                     temp.data[10], $time);
                `endif
    
                temp.port = 0;
            end
            else begin
    
                // READ ADDR
                for(k=0; k<=10; k++) begin
                    temp.addr[k] = sout1;
                    `ifdef DEBUG
                    $display("[QSOUT] PORT1 ADDR[%0d] = %0b (time %0t)",
                         k, temp.addr[k], $time);
                    `endif
                    repeat (16) @(posedge clk);
                end
    
                // READ DATA
                for(l=0; l<=9; l++) begin
                    temp.data[l] = sout1;
                    `ifdef DEBUG
                    $display("[QSOUT] PORT1 DATA[%0d] = %0b (time %0t)",
                         l, temp.data[l], $time);
                    `endif
                    repeat (16) @(posedge clk);
                end
    
                temp.data[10] = sout1;
                `ifdef DEBUG
                $display("[QSOUT] PORT1 DATA[10] = %0b (time %0t)",
                     temp.data[10], $time);
                `endif
    
                temp.port = 1;
            end

            result.result = temp;
    
            // ======================================================
            // ADD TO QUEUE
            // ======================================================
            result_monitor_h.write_to_monitor(result);
    
            `ifdef DEBUG
            $display("[QSOUT] ---- TEMP STRUCTURE ADDED ----");
            $display("[QSOUT] ADDR = %0b", temp.addr);
            $display("[QSOUT] DATA = %0b", temp.data);
            $display("[QSOUT] PORT = %0d", temp.port);
    
            $display("[QSOUT] out_sout size = %0d", out_sout.size());
            $display("[QSOUT] out_sout[$] = { addr=%0b, data=%0b, port=%0d }\n",
                    out_sout[$].addr,
                    out_sout[$].data,
                    out_sout[$].port);
            `endif
        end
end




endinterface : switch_bfm
