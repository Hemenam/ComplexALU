`include "macros.v"

module alu_TB ();

    reg clk = 0, rstN = 0;
    reg start;
    reg [1:0] op;
    reg `complex a, b;
    wire `complex result;
    wire done;

    alu DUT (clk, rstN, start, op, a, b, result, done);

    always #5 clk = ~clk;

    task do_op(input [1:0] o, input `complex aa, input `complex bb);
    begin
        @(negedge clk);
        op    = o;
        a     = aa;
        b     = bb;
        start = 1;
        @(negedge clk);
        start = 0;
        wait (done);
        $display("op=%b  (%0d, %0d)  ?  (%0d, %0d)  =  (%0d, %0d)",
                 o, `sRe(aa), `sIm(aa), `sRe(bb), `sIm(bb),
                 `sRe(result), `sIm(result));
    end
    endtask

    initial begin
        #12 rstN = 1;
        do_op(2'b00, {8'sd3, 8'sd4}, {8'sd1, 8'sd2});
        do_op(2'b01, {8'sd3, 8'sd4}, {8'sd1, 8'sd2});
        do_op(2'b10, {8'sd3, 8'sd4}, {8'sd1, 8'sd2});
        do_op(2'b00, {-8'sd7, 8'sd5}, {8'sd7, -8'sd5});
        #20 $stop;
    end

endmodule
