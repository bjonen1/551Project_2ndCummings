module A2D__tb();

	reg [11:0] analogData [0:2879];
	
	reg clk, rst_n, strt_cnv;
	reg [3:0] chnnl;
	reg [2:0] conv;
	reg [5:0] error;
	
	reg errorSignal;
	
	wire ss_n, sclk, mosi, miso, cnv_cmplt;
	wire [11:0] res;
	
	A2D_intf inter(.clk(clk), .rst_n(rst_n), .strt_cnv(strt_cnv), .chnnl(chnnl), .MISO(miso), .a2d_SS_n(ss_n), .SCLK(sclk), .MOSI(mosi), .cnv_cmplt(cnv_cmplt), .res(res));
	ADC128S slave(.clk(clk), .rst_n(rst_n), .SS_n(ss_n), .SCLK(sclk), .MOSI(mosi), .MISO(miso));
	
	initial begin
		$readmemh("analog.dat", analogData);
		
		clk = 1'b0;
		errorSignal = 1'b0;
		
		rst_n = 1'b0;
		@(negedge clk)
		rst_n = 1'b1;
		
		//error = 6'h00;
		//for(error = 0; error < 60; error = error + 1) begin
			conv = 2'h0;
			for(conv = 0; conv < 6; conv = conv + 1) begin
				//rst_n = 1'b0;
				strt_cnv = 1'b0;
				chnnl = 3'h0;
				for(chnnl = 0; chnnl < 8; chnnl = chnnl + 1) begin
				  errorSignal = 1'b0;
					@(negedge clk);
					//rst_n = 1'b1;
					strt_cnv = 1'b1;
					
					
					repeat(2)@(negedge clk);
					strt_cnv = 1'b0;
					
					@(posedge cnv_cmplt);
					if(~res != slave.shft_reg[11:0]) begin
					  errorSignal = 1'b1;
						$display("Error %d Conversion of %d channel %h failed\n",error, conv, chnnl);
						$display("Expected %h\n\n", slave.shft_reg[11:0]);
					end
					repeat(10)@(posedge clk);
					//rst_n = 1'b0;
				end
			end
		//end
		$stop;
	end
	
	always
		#2 clk = ~clk;

endmodule
