module ALU(accum, pcomp, pterm, fwd, a2d_res, error, intgrl, icomp, iterm, src0sel, src1sel, multiply, sub, mult2, mult4, saturate, dst);

	input [15:0] accum, pcomp;
	input [13:0] pterm;
	input [11:0] fwd, a2d_res;
	input [2:0] src0sel, src1sel;
	input signed [11:0] error, intgrl, icomp, iterm;
	input multiply, sub, mult2, mult4, saturate;
	
	output [15:0] dst;
	
	wire [15:0] src1, presrc0, scaled_src0, src0, add_result,satur_add;
	wire signed [15:0] src1mult, src0mult;
	wire signed [30:0] mult_result;
	wire signed [14:0] satur_mult;
	
	localparam ACCUM = 3'b000;
	localparam ITERM = 3'b001;
	localparam ERROR_EXT = 3'b010;
	localparam ERROR_TOP = 3'b011;
	localparam FWD = 3'b100;

	localparam A2D_RES = 3'b000;
	localparam INTGRL_EXT = 3'b001;
	localparam ICOMP_EXT = 3'b010;
	localparam PCOMP = 3'b011;
	localparam PTERM = 3'b100;

	assign src1 = (src1sel == ACCUM) ? accum:
				  (src1sel == ITERM) ? {4'b0000, iterm}:
				  (src1sel == ERROR_EXT) ? {{4{error[11]}}, error}:
				  (src1sel == ERROR_TOP) ? {{8{error[11]}}, error[11:4]}:
				  (src1sel == FWD) ? {4'b0000, fwd}: 16'h0000;
				  
	assign presrc0 = (src0sel == A2D_RES) ? {4'b0000,a2d_res}:
					 (src0sel == INTGRL_EXT) ? {{4{intgrl[11]}}, intgrl}:
					 (src0sel == ICOMP_EXT) ? {{4{icomp[11]}}, icomp}:
					 (src0sel == PCOMP) ? pcomp:
					 (src0sel == PTERM) ? {2'b00, pterm}: 16'h0000;
					 
	assign scaled_src0 = mult2 ? presrc0 << 1:
						 mult4 ? presrc0 << 2: presrc0;
						 
	assign src0 = sub ? ~scaled_src0 : scaled_src0;

	//add16bit adder(.a(src0), .b(src1), .cin(sub), .cout(), .sum(add_result));
	assign add_result = src0 + src1 + sub;
	
	assign satur_add = saturate ? ((add_result[15]) ? (&add_result[14:11]) ? add_result: 16'hF800:
								  (|add_result[14:11]) ?  16'h07FF: add_result):add_result;
	
	//(add_result[15] == 0 && add_result > 16'h07FF) ? 16'h07ff:
	//							  (add_result[15] == 1 && add_result < 16'hF800) ? 16'hF800: add_result: add_result;
					   
	assign src1mult = src1[14:0];
	assign src0mult = src0[14:0];
	
	assign mult_result = src1mult * src0mult;
	
	assign satur_mult = (mult_result[29]) ? (&mult_result[28:26]) ? mult_result[27:12]: 15'hC000:
						(|mult_result[28:26]) ? 15'h3FFF: mult_result[27:12];
	
	//(mult_result[29] == 0 && mult_result > 16'h3FFF) ? 16'h3FFF:
	//					(mult_result[29] == 1 && mult_result < 16'hC000) ? 16'hC000 : mult_result[27:12];

	assign dst = multiply ? {satur_mult[14], satur_mult} : satur_add;
	
endmodule