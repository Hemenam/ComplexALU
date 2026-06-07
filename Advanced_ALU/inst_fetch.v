`include "macros.v"

module inst_fetch #(
    parameter DEPTH = 32,
    parameter A_LEN = 5
) (
    input              clk,
    input              rstN,
    input              stall,
    output [2:0]       op,
    output [A_LEN-1:0] waddr,
    output [A_LEN-1:0] raddr1,
    output [A_LEN-1:0] raddr2,
    output [A_LEN-1:0] pc_out      
);
    reg [17:0]      mem [DEPTH-1:0];
    reg [A_LEN-1:0] pc;

    initial $readmemb("data/inst_mem.txt", mem);

    assign {op, waddr, raddr1, raddr2} = mem[pc];
    assign pc_out = pc;

    always @(posedge clk or negedge rstN) begin
        if (!rstN)        pc <= 0;
        else if (!stall)  pc <= pc + 1'b1;
    end
endmodule