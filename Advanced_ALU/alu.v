`include "macros.v"


//  000 :  a + b                
//  001 :  a - b                
//  010 :  a * b                
//  011 :  a / b                
//  100 :  |a|^2    
module alu (
    input               clk,
    input               rstN,
    input               start,
    input  [2:0]        op,
    input  `complex     a,
    input  `complex     b,
    output reg `complex result,
    output reg          done
);

    //  op 
    localparam OP_ADD   = 3'b000,
               OP_SUB   = 3'b001,
               OP_MUL   = 3'b010,
               OP_DIV   = 3'b011,
               OP_MAGSQ = 3'b100;

    //  mult
    reg  signed [`WL-1:0] mul_x, mul_y;
    wire signed [`WL-1:0] mul_p;
    mul MUL (mul_x, mul_y, mul_p);

    //  adder/subber
    reg  signed [`WL-1:0] as_x, as_y;
    reg                   as_op;
    wire signed [`WL-1:0] as_s;
    addsub ADDSUB (as_x, as_y, as_op, as_s);

    // divider
    reg  signed [`WL-1:0] div_n, div_d;
    wire signed [`WL-1:0] div_q;
    divider DIV (div_n, div_d, div_q);

    //  FSM states 
    localparam IDLE = 5'd0,
               AS1  = 5'd1,  AS2 = 5'd2,
               M1   = 5'd3,  M2  = 5'd4, M3 = 5'd5, M4 = 5'd6, M5 = 5'd7,
               D1   = 5'd8,  D2  = 5'd9,  D3 = 5'd10, D4 = 5'd11,
               D5   = 5'd12, D6  = 5'd13, D7 = 5'd14, D8 = 5'd15, D9 = 5'd16,
               Q1   = 5'd17, Q2  = 5'd18, Q3 = 5'd19;

    reg [4:0] state;

    // temp
    reg signed [`WL-1:0] t_ac, t_bd, t_ad, t_bc;
    // div temp
    reg signed [`WL-1:0] t_cc, t_dd;
    reg signed [`WL-1:0] num_re, num_im, denom;

    wire is_as    = (op == OP_ADD) || (op == OP_SUB);
    wire is_mul   = (op == OP_MUL);
    wire is_div   = (op == OP_DIV);
    wire is_magsq = (op == OP_MAGSQ);
    wire sub      = (op == OP_SUB);

   
    always @(*) begin
        mul_x = 0; mul_y = 0;
        as_x  = 0; as_y  = 0; as_op = 0;
        div_n = 0; div_d = 1;  
        case (state)
            // add / sub
            AS1: begin as_x = `sRe(a); as_y = `sRe(b); as_op = sub; end
            AS2: begin as_x = `sIm(a); as_y = `sIm(b); as_op = sub; end

            // mult (a+bi)(c+di) = (ac-bd) + (ad+bc)i
            M1 : begin mul_x = `sRe(a); mul_y = `sRe(b); end              // ac
            M2 : begin mul_x = `sIm(a); mul_y = `sIm(b); end               // bd
            M3 : begin mul_x = `sRe(a); mul_y = `sIm(b);          // ad
                       as_x  = t_ac;    as_y  = t_bd;    as_op = 1'b1; end  // ac -bd
            M4 : begin mul_x = `sIm(a); mul_y = `sRe(b); end                // bc
            M5 : begin as_x  = t_ad;    as_y  = t_bc;    as_op = 1'b0; end  // ad +bc

            // divide: (a+bi)/(c+di) = ((ac+bd) + (bc-ad)i) / (c^2+d^2)
            D1 : begin mul_x = `sRe(a); mul_y = `sRe(b); end                // ac
            D2 : begin mul_x = `sIm(a); mul_y = `sIm(b); end                // bd
            D3 : begin mul_x = `sRe(a); mul_y = `sIm(b);                    // ad
                       as_x  = t_ac;    as_y  = t_bd;    as_op = 1'b0; end  // ac + bd
            D4 : begin mul_x = `sIm(a); mul_y = `sRe(b); end                // bc
            D5 : begin mul_x = `sRe(b); mul_y = `sRe(b);                    // c*c
                       as_x  = t_bc;    as_y  = t_ad;    as_op = 1'b1; end  // bc - ad
            D6 : begin mul_x = `sIm(b); mul_y = `sIm(b); end                // d*d
            D7 : begin as_x  = t_cc;    as_y  = t_dd;    as_op = 1'b0; end  // c^2 + d^2
            D8 : begin div_n = num_re;  div_d = denom; end                  // (ac+bd)/c^2+d^2
            D9 : begin div_n = num_im;  div_d = denom; end                  // (bc-ad)/c^2+d^2

            //  squared: |a|^2  
            Q1 : begin mul_x = `sRe(a); mul_y = `sRe(a); end   // R*R
            Q2 : begin mul_x = `sIm(a); mul_y = `sIm(a); end                // I*I
            Q3 : begin as_x  = t_ac;    as_y  = t_bd;    as_op = 1'b0; end 

            default: ;
        endcase
    end

    // seq FSM -
    always @(posedge clk or negedge rstN) begin
        if (!rstN) begin
            state <= IDLE;
            done  <= 1'b0;
        end else begin
            done <= 1'b0;
            case (state)
                IDLE: if (start) begin
                    if      (is_as)    state <= AS1;
                    else if (is_mul)   state <= M1;
                    else if (is_div)   state <= D1;
                    else if (is_magsq) state <= Q1;
                end

                // add / sub
                AS1 : begin `Re(result) <= as_s;  state <= AS2;                end
                AS2 : begin `Im(result) <= as_s;  state <= IDLE; done <= 1'b1; end

                // multiply
                M1  : begin t_ac <= mul_p;        state <= M2; end
                M2  : begin t_bd <= mul_p;        state <= M3; end
                M3  : begin t_ad <= mul_p;
                            `Re(result) <= as_s;  state <= M4; end
                M4  : begin t_bc <= mul_p;        state <= M5; end
                M5  : begin `Im(result) <= as_s;  state <= IDLE; done <= 1'b1; end

                // divide
                D1  : begin t_ac <= mul_p;        state <= D2; end
                D2  : begin t_bd <= mul_p;        state <= D3; end
                D3  : begin t_ad <= mul_p;
                            num_re <= as_s;       state <= D4; end
                D4  : begin t_bc <= mul_p;        state <= D5; end
                D5  : begin t_cc <= mul_p;
                            num_im <= as_s;       state <= D6; end
                D6  : begin t_dd <= mul_p;        state <= D7; end
                D7  : begin denom  <= as_s;       state <= D8; end
                D8  : begin `Re(result) <= div_q; state <= D9; end
                D9  : begin `Im(result) <= div_q; state <= IDLE; done <= 1'b1; end

                // magnitude squared
                Q1  : begin t_ac <= mul_p;        state <= Q2; end
                Q2  : begin t_bd <= mul_p;        state <= Q3; end
                Q3  : begin `Re(result) <= as_s;
                            `Im(result) <= 0;
                            state <= IDLE; done <= 1'b1; end
            endcase
        end
    end

endmodule