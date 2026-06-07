`include "macros.v"

module addsub (
    input  signed [`WL-1:0] x,
    input  signed [`WL-1:0] y,
    input                   op,   // 0: add 1:sub
    output signed [`WL-1:0] s
);
    assign s = op ? (x - y) : (x + y);
endmodule
