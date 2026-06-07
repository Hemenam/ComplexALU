`include "macros.v"


module pipeline (
    input clk,
    input rstN
);
    // IF op
    wire [2:0] if_op;
    wire [4:0] if_waddr, if_raddr1, if_raddr2;

    //  EX 
    reg [2:0]    cur_op;
    reg [4:0]    cur_waddr;
    reg `complex cur_a, cur_b;

    // ALU 
    reg           alu_start;
    wire `complex alu_result;
    wire          alu_done;

    
    wire `complex rdata1, rdata2;

    reg  busy;
    wire ready_to_issue = !busy || alu_done;     
    wire stall          = busy && !alu_done;     
    wire wb_en          = alu_done;              

    inst_fetch IF  (.clk(clk), .rstN(rstN), .stall(stall),
                    .op(if_op), .waddr(if_waddr),
                    .raddr1(if_raddr1), .raddr2(if_raddr2));

    memory     MEM (.clk(clk),
                    .raddr1(if_raddr1), .raddr2(if_raddr2),
                    .rdata1(rdata1),    .rdata2(rdata2),
                    .waddr(cur_waddr),  .wdata(alu_result), .wen(wb_en));

    alu        ALU (.clk(clk), .rstN(rstN),
                    .start(alu_start),
                    .op(cur_op), .a(cur_a), .b(cur_b),
                    .result(alu_result), .done(alu_done));

    always @(posedge clk or negedge rstN) begin
        if (!rstN) begin
            busy      <= 1'b0;
            alu_start <= 1'b0;
        end else begin
            alu_start <= 1'b0;
            if (ready_to_issue) begin
                cur_op    <= if_op;
                cur_waddr <= if_waddr;
                cur_a     <= rdata1;
                cur_b     <= rdata2;
                alu_start <= 1'b1;
                busy      <= 1'b1;
            end

            // ---------- debug trace ----------
            if (alu_done)
                $display("#%0t  WB  mem[%0d] <= (%0d, %0d)   (op=%b, a=(%0d,%0d), b=(%0d,%0d))",
                    $time, cur_waddr,
                    `sRe(alu_result), `sIm(alu_result),
                    cur_op,
                    `sRe(cur_a), `sIm(cur_a),
                    `sRe(cur_b), `sIm(cur_b));
        end
    end

endmodule