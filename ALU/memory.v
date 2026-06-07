`include "macros.v"

module memory #(
    parameter DEPTH = 32,
    parameter A_LEN = 5
) (
    input                   clk,
    input  [A_LEN-1:0]      raddr1,
    input  [A_LEN-1:0]      raddr2,
    output `complex         rdata1,
    output `complex         rdata2,
    input  [A_LEN-1:0]      waddr,
    input  `complex         wdata,
    input                   wen
);
    reg `complex mem [DEPTH-1:0];

    assign rdata1 = mem[raddr1];
    assign rdata2 = mem[raddr2];

    always @(posedge clk) begin
        if (wen) mem[waddr] <= wdata;
    end
endmodule
