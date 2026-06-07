`include "macros.v"

module addsub_TB ();

    reg  signed [`WL-1:0] x, y;
    reg                   op;
    wire signed [`WL-1:0] s;

    addsub DUT (x, y, op, s);

    wire [7:0] op_char = op ? "-" : "+";
    initial begin
        $monitor("%0d %s %0d = %0d", x, op_char, y, s);
        x =  10; y =   5; op = 0; #5;
        x =  10; y =   5; op = 1; #5;
        x = -20; y =  30; op = 0; #5;
        x =  50; y = -50; op = 1; #5;
        $stop;
    end
endmodule
