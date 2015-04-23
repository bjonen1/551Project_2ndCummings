module motor_cntrl(clk, rst_n, rht, lft, fwd_rht, fwd_lft, rev_rht, rev_lft);
	input clk, rst_n;
	input [10:0] rht, lft;
	
	output fwd_rht, fwd_lft, rev_rht, rev_lft;
	
	wire pwmOutL,pwmOutR;
	
	//left motor
	pwm10bit pwmL(.clk(clk), .rst_n(rst_n), .duty(lft[9:0]), .PWM_sig(pwmOutL));
	
	assign fwd_lft = ~rst_n ? 0 : (lft[9:0] == 0) ? 1 :
					 (lft[10]) ? 0 : pwmOutL;
	assign rev_lft = ~rst_n ? 0 : (lft[9:0] == 0) ? 1 :
					 (lft[10]) ? pwmOutL : 0;
	
	//right motor
	pwm10bit pwmR(.clk(clk), .rst_n(rst_n), .duty(rht[9:0]), .PWM_sig(pwmOutR));
	
	assign fwd_rht = ~rst_n ? 0 : (rht[9:0] == 0) ? 1 :
					 (rht[10]) ? 0 : pwmOutR;
	assign rev_rht = ~rst_n ? 0 : (rht[9:0] == 0) ? 1 :
					 (rht[10]) ? pwmOutR : 0;
	
	
endmodule