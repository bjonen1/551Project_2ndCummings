module motor_PWM_tb();
reg clk, rst_n;
reg [10:0] lft, rht;
wire fwd_lft, rev_lft, fwd_rht, rev_rht;
wire [7:0] fwd_lft_duty, rev_lft_duty, fwd_rht_duty, rev_rht_duty;

wire fl_duty_rdy, rl_duty_rdy, fr_duty_rdy, rr_duty_rdy, duty_rdy;

assign duty_rdy = fl_duty_rdy | rl_duty_rdy | fr_duty_rdy | rr_duty_rdy;

motor_cntrl iMTR(.clk(clk), .rst_n(rst_n), .lft(lft), .rht(rht), .fwd_lft(fwd_lft),
                 .rev_lft(rev_lft), .fwd_rht(fwd_rht), .rev_rht(rev_rht));
				 
duty_finder dutyFL(.clk(clk), .rst_n(rst_n), .pwm(fwd_lft), .duty(fwd_lft_duty), .rdy(fl_duty_rdy));
duty_finder dutyRL(.clk(clk), .rst_n(rst_n), .pwm(rev_lft), .duty(rev_lft_duty), .rdy(rl_duty_rdy));
duty_finder dutyFR(.clk(clk), .rst_n(rst_n), .pwm(fwd_rht), .duty(fwd_rht_duty), .rdy(fr_duty_rdy));
duty_finder dutyRR(.clk(clk), .rst_n(rst_n), .pwm(rev_rht), .duty(rev_rht_duty), .rdy(rr_duty_rdy));

initial begin
  clk = 0;
  lft = 11'h3f;
  rht = 11'h7f;
  rst_n =0;
  @(negedge clk);
  rst_n = 1; 
  // @(posedge duty_rdy);
  // if(fl_duty_rdy)
	// if(fwd_lft_duty != lft)
		// $display("Error wrong duty");
  // else if(fr_duty_rdy)
	// if(fwd_rht_duty != rht)
		// $display("Error wrong duty");
  // else if(rl_duty_rdy)
	// if(rev_lft_duty != lft)
		// $display("Error wrong duty");
  // else if(rr_duty_rdy)
	// if(rev_rht_duty != rht)
		// $display("Error wrong duty");
  repeat(1000)@(posedge clk);
  lft = 11'hFF2;
  rht = 11'hC4F;
  repeat(1000)@(posedge clk);
  // @(posedge duty_rdy);
  // if(fl_duty_rdy)
	// if(fwd_lft_duty != lft)
		// $display("Error wrong duty");
  // else if(fr_duty_rdy)
	// if(fwd_rht_duty != rht)
		// $display("Error wrong duty");
  // else if(rl_duty_rdy)
	// if(rev_lft_duty != lft)
		// $display("Error wrong duty");
  // else if(rr_duty_rdy)
	// if(rev_rht_duty != rht)
		// $display("Error wrong duty");
  $stop;
end
  
always
 #1 clk =~clk;


endmodule
