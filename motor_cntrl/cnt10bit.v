module cnt10bit(clk, rst_n, cnt);
	input clk, rst_n;
	output reg [9:0] cnt;
	
	always @(posedge clk, negedge rst_n)
		if(!rst_n)
			cnt <= 10'h000;
		else
			cnt <= cnt + 1;
endmodule