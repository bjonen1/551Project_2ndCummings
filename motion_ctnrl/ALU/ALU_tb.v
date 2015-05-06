module ALU_tb();
	reg [128:0] stim[0:999];
	reg [15:0] resp[0:999];
	
	reg [15:0] accum, pcomp;
	reg [13:0] pterm;
	reg [11:0] fwd, a2d_res;
	reg [2:0] src0sel, src1sel;
	reg signed [11:0] error, intgrl, icomp, iterm;
	reg multiply, sub, mult2, mult4, saturate;
	
	wire [15:0] dst;
	
	reg [10:0] count;
	
	reg [9:0] passCount;
	reg [9:0] failCount;
	

	ALU iDUT(accum, pcomp, pterm, fwd, a2d_res, error, intgrl, icomp, iterm, src0sel, src1sel, multiply, sub, mult2, mult4, saturate, dst);
	
	initial begin
		$readmemh("ALU_stim.hex",stim);
		$readmemh("ALU_resp.hex",resp);
		passCount = 0;
		failCount = 0;
		
		for(count=0;count<1000;count = count + 1) begin
			accum = stim[count][128:113];
			pcomp = stim[count][112:97];
			pterm = stim[count][96:83];
			fwd = stim[count][82:71];
			a2d_res = stim[count][70:59];
			error = stim[count][58:47];
			intgrl = stim[count][46:35];
			icomp = stim[count][34:23];
			iterm = stim[count][22:11];
			src1sel = stim[count][10:8];
			src0sel = stim[count][7:5];
			multiply = stim[count][4];
			sub = stim[count][3];
			mult2 = stim[count][2];
			mult4 = stim[count][1];
			saturate = stim[count][0];
			
			#5;
			
			if(dst == resp[count]) begin
				//$display("Pass");
				passCount = passCount + 1;
			end
			else begin
				failCount = failCount + 1;
				$display("Failed with inputs");
				$display("accum: %h, pcomp: %h, pterm: %h, fwd: %h, a2d_res: %h, error: %h, intgrl: %h, icomp: %h, iterm: %h, src1sel: %h, src0sel: %h, multiply: %h, sub: %h, mult2: %h, mult4: %h, saturate: %h", accum,pcomp,pterm,fwd,a2d_res,error,intgrl,icomp,iterm,src1sel,src0sel,multiply,sub,mult2,mult4,saturate);
				$display("Expected: %h but got %h",resp[count],dst);
				$display("mult_result: %h, add_result: %h\n", iDUT.mult_result,iDUT.add_result);
			end
		end
		$display("%d passed and %d failed",passCount,failCount);
		$stop;
	end
		
	
endmodule