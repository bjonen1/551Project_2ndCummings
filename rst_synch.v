module reset_synch(RST_n, clk, rst_n);
	input RST_n,clk;
	output reg rst_n;
	
	reg q1;
	
	always @(negedge clk, negedge RST_n)
		if(!RST_n)
			rst_n <= 1'b0;
		else begin
			q1 <= 1'b1;
			rst_n <= q1;
		end
endmodule
