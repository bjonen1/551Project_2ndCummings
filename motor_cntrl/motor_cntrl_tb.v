module motor_cntrl_tb();
	reg clk, rst_n;
	reg [10:0] rht, lft;
	
	wire fwd_rht, fwd_lft, rev_rht, rev_lft;
	motor_cntrl iDUT(.clk(clk), .rst_n(rst_n), .rht(rht), .lft(lft), .fwd_rht(fwd_rht), .fwd_lft(fwd_lft), .rev_rht(rev_rht), .rev_lft(rev_lft));
	initial begin
		clk = 0;
		rst_n = 0;
		rht = 11'hF00;
		lft = 11'h023;
		@(negedge clk) rst_n = 1;
		repeat(2056) @(posedge clk);
		@(negedge clk) rst_n = 0;
		rht = 11'h03f;
		@(negedge clk) rst_n = 1;
		repeat(2056) @(posedge clk);
		$stop;
	end
	
	always
		#10 clk = ~clk;
endmodule