module motion_cntrl_tb();
	reg clk, rst_n, cnv_cmplt;
	reg [11:0] res;
	reg go;
	
	wire strt_cnv, IR_out_en, IR_in_en, IR_mid_en;
	wire [10:0] lft, rht;
	wire [2:0] chnnl;
	
	reg [5:0] i;
	
	motion_cntrl iMotion(.clk(clk), .rst_n(rst_n), .cnv_cmplt(cnv_cmplt), .go(go), .res(res), .strt_cnv(strt_cnv), .IR_out_en(IR_out_en), .IR_mid_en(IR_mid_en), .IR_in_en(IR_in_en), .lft(lft), .rht(rht), .chnnl(chnnl));
	
	initial begin
		clk = 0;
		rst_n = 0;
		cnv_cmplt = 0;
		go = 0;
		
		repeat(2)@(negedge clk);
		rst_n = 1;
		go = 1;
		
		for(i=0;i<32;i=i+1) begin
			//while(chnnl < 6) begin
				res = 12'hfff;
				@(posedge strt_cnv);
				repeat(10)@(negedge clk);
				cnv_cmplt = 1;
				@(negedge clk);
				res = 12'h3ff;
				@(posedge strt_cnv);
				repeat(10)@(negedge clk);
				cnv_cmplt = 1;
				@(negedge clk);
			//end
			repeat(100)@(posedge clk);
		end
		$stop;
	end
	
	always
		#1 clk = ~ clk;
endmodule