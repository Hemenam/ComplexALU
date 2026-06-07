`include "macros.v"

module mul_TB ();

    reg  signed [`WL-1:0] x, y;
    wire signed [`WL-1:0] p;

    mul DUT (x, y, p);

    initial begin
        $monitor("%0d * %0d = %0d (truncated to %0d bits)", x, y, p, `WL);
        x =   3; y =   4; #5;
        x =  -5; y =   6; #5;
        x =  -7; y =  -8; #5;
        x =  10; y =  10; #5;   
        x =  12; y =  12; #5;   
        $stop;
    end
endmodule
