`include "macros.v"


module mul (
    input  signed [`WL-1:0] x,
    input  signed [`WL-1:0] y,
    output signed [`WL-1:0] p
);
    assign p = x * y;
endmodule
