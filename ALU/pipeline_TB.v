`include "macros.v"

module pipeline_TB ();

    reg clk = 1, rstN = 0;
    pipeline DUT (clk, rstN);

    always #10 clk = ~clk;

    initial begin
        $readmemb("data/inst_mem.txt",    DUT.IF.mem);
        $readmemb("data/initial_mem.txt", DUT.MEM.mem);

        #25 rstN = 1;

       
        #800;

        $display("---- final memory ----");
        begin : dump
            integer i;
            for (i = 0; i < 8; i = i + 1)
                $display("mem[%0d] = (%0d, %0d)", i,
                    `sRe(DUT.MEM.mem[i]), `sIm(DUT.MEM.mem[i]));
        end
        $writememb("data/final_mem.txt", DUT.MEM.mem);
        $stop;
    end

endmodule
