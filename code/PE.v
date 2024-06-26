/*
 * This module is used to calculate the following equation:
 *      out = (b + (in_1 + in_2) - 6 * (in_3 + in_4) + 13 * (in_5 + in_6)) / 20
 * The total delay is 3
 */
module PE (input clk, 
           input reset,
           input signed [31:0] in_1, in_2, in_3, in_4, in_5, in_6,
           input signed [15:0] b,
           output [31:0] out);

reg signed [31:0] b_r, b_w;
reg signed [32:0] s1_adder [0:2];
reg signed [35:0] s1_mul6;
reg signed [36:0] s1_mul13;

reg signed [32:0] s1_reg0_r, s1_reg0_w;
reg signed [35:0] s1_reg1_r, s1_reg1_w;
reg signed [36:0] s1_reg2_r, s1_reg2_w;

reg signed [37:0] s2_adder;
reg signed [37:0] s2_reg0_r, s2_reg0_w;

wire signed [34:0] div_out;
always @(posedge clk or posedge reset) begin
    if (reset) begin
        s1_reg0_r <= 0;
        s1_reg1_r <= 0;
        s1_reg2_r <= 0;
        s2_reg0_r <= 0;
        b_r <= 0;
    end else begin
        s1_reg0_r <= s1_reg0_w;
        s1_reg1_r <= s1_reg1_w;
        s1_reg2_r <= s1_reg2_w;
        s2_reg0_r <= s2_reg0_w;
        b_r <= b_w;
    end
end

always @(*) begin:stage1
    b_w = {b, 16'b0};
    s1_adder[0] = in_1 + in_2;
    s1_adder[1] = in_3 + in_4;
    s1_adder[2] = in_5 + in_6;
    s1_mul6 = $signed({s1_adder[1][32:0], 1'b0}) + $signed({s1_adder[1][32:0], 2'b00});
    s1_mul13 = $signed({s1_adder[2][32:0], 3'b000}) + $signed({s1_adder[2][32:0], 2'b00}) + $signed(s1_adder[2]);
    s1_reg0_w = s1_adder[0];
    s1_reg1_w = s1_mul6;
    s1_reg2_w = s1_mul13;
end

always @(*) begin:stage2
    s2_adder = b_r + s1_reg0_r - s1_reg1_r + s1_reg2_r;
    s2_reg0_w = s2_adder;
end

assign out = div_out;


Divider #(38, 8) div (
    .clk(clk),
    .reset(reset),
    .in(s2_reg0_r),
    .out(div_out)
);
endmodule

/* 
 * This module is used to divide the input by 20
 * The number of stages affect the accuracy of the division
 */
module Divider #(parameter WIDTH = 38, parameter FRAC = 16)(
                 input clk, 
                 input reset,
                 input signed [WIDTH-1:0] in,
                 output signed [WIDTH-4:0] out);
           
wire signed [WIDTH-1+1+FRAC:0] tmp_in;
wire signed [WIDTH-1-4+FRAC:0] add_s0;
wire signed [WIDTH-1-3+FRAC:0] add_s1;
wire signed [WIDTH-1-2+FRAC:0] add_s2;
wire signed [WIDTH-1-1+FRAC:0] add_s3;


assign tmp_in = {in[WIDTH-1:0],1'b0, {(FRAC){1'b0}}}; // padding 0s
assign add_s0 = ($signed({in[WIDTH-1:0],{(FRAC){1'b0}}}) + tmp_in) >>> 6;
assign add_s1 = add_s0 + (add_s0 >>> 4);
assign add_s2 = add_s1 + (add_s1 >>> 8);
assign add_s3 = add_s2 + (add_s2 >>> 16);
assign out = add_s3[WIDTH-1-1+FRAC: FRAC];
endmodule
