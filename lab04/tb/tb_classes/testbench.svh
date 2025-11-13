class testbench;

    virtual switch_bfm bfm;

    tbgen tbgen_h;
    coverage coverage_h;
    scoreboard scoreboard_h;

    function new (virtual switch_bfm b);
        bfm          = b;
        tbgen_h      = new(bfm);
        coverage_h   = new(bfm);
        scoreboard_h = new(bfm);
    endfunction : new

    task execute();
        fork
            coverage_h.execute();
            scoreboard_h.execute();
        join_none
        tbgen_h.execute();
        scoreboard_h.print_result();
    endtask : execute

endclass : testbench