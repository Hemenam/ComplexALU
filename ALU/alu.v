`include "macros.v"


module alu (
    input               clk,
    input               rstN,
    input               start,
    input  [1:0]        op,
    input  `complex     a,
    input  `complex     b,
    output reg `complex result,
    output reg          done
);

    reg  signed [`WL-1:0] mul_x, mul_y;
    wire signed [`WL-1:0] mul_p;
    mul    MUL    (mul_x, mul_y, mul_p);

    reg  signed [`WL-1:0] as_x, as_y;
    reg                   as_op;
    wire signed [`WL-1:0] as_s;
    addsub ADDSUB (as_x, as_y, as_op, as_s);

    localparam IDLE = 4'd0,
               AS1  = 4'd1,   // Re(a) +/- Re(b)  
               AS2  = 4'd2,   // Im(a) +/- Im(b)  
               M1   = 4'd3,   // mul Re*Re  ac
               M2   = 4'd4,   // mul Im*Im  bd, capture ac
               M3   = 4'd5,   // mul Re*Im  ad, capture bd, add ac-bd
               M4   = 4'd6,   // mul Im*Re  bc, capture ad, capture Re
               M5   = 4'd7;   // capture bc, add ad+bc => Im

    reg [3:0] state;
    reg signed [`WL-1:0] t_ac, t_bd, t_ad, t_bc;

    wire is_mul = op[1];
    wire sub    = op[0];    

    always @(*) begin
        mul_x = 0; mul_y = 0;
        as_x  = 0; as_y  = 0; as_op = 0;
        case (state)
            AS1: begin as_x = `sRe(a); as_y = `sRe(b); as_op = sub; end
            AS2: begin as_x = `sIm(a); as_y = `sIm(b); as_op = sub; end
            M1 : begin mul_x = `sRe(a); mul_y = `sRe(b); end
            M2 : begin mul_x = `sIm(a); mul_y = `sIm(b); end
            M3 : begin
                mul_x = `sRe(a); mul_y = `sIm(b);
                as_x  = t_ac;    as_y  = t_bd;    as_op = 1'b1; 
            end
            M4 : begin mul_x = `sIm(a); mul_y = `sRe(b); end
            M5 : begin
                as_x  = t_ad;    as_y  = t_bc;    as_op = 1'b0; 
            end
            default: ;
        endcase
    end

    always @(posedge clk or negedge rstN) begin
        if (!rstN) begin
            state <= IDLE;
            done  <= 1'b0;
        end else begin
            done <= 1'b0;
            case (state)
                IDLE: if (start) state <= is_mul ? M1 : AS1;
                AS1 : begin `Re(result) <= as_s;        state <= AS2;                  end
                AS2 : begin `Im(result) <= as_s;        state <= IDLE; done <= 1'b1;   end
                M1  : begin t_ac <= mul_p;              state <= M2;                   end
                M2  : begin t_bd <= mul_p;              state <= M3;                   end
                M3  : begin t_ad <= mul_p;
                            `Re(result) <= as_s;        state <= M4;                   end
                M4  : begin t_bc <= mul_p;              state <= M5;                   end
                M5  : begin `Im(result) <= as_s;        state <= IDLE; done <= 1'b1;   end
            endcase
        end
    end

endmodule
