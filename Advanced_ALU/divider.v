`include "macros.v"
 
// One real signed divider (WL-bit). Truncated integer division.
// Shared by the ALU between the two division cycles (D8, D9).
// Returns 0 on divide-by-zero to keep simulation safe.
module divider (
    input  signed [`WL-1:0] n,    // numerator
    input  signed [`WL-1:0] d,    // denominator
    output signed [`WL-1:0] q
);
    assign q = (d == 0) ? 0 : n / d;
endmodule