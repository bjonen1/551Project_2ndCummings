module motor_PWM_tb();
reg clk, rst_n;
reg [10:0] lft, rht;
wire fwd_lft, rev_lft, fwd_rht, rev_rht;

motor_cntrl iMTR(.clk(clk), .rst_n(rst_n), .lft(lft), .rht(rht), .fwd_lft(fwd_lft),
                 .rev_lft(rev_lft), .fwd_rht(fwd_rht), .rev_rht(rev_rht));

reg [10:0]i,j,k,l;
reg prev_fwd_lft, prev_rev_lft, prev_fwd_rht, prev_rev_rht;
always@(posedge clk)begin
	prev_fwd_lft <= fwd_lft;
	prev_rev_lft <= rev_lft;
	prev_fwd_rht <= fwd_rht;
	prev_rev_rht <= rev_rht;
end

//check the duty of each of four outputs
always @(posedge clk)begin
	if (((fwd_lft == 0) && (prev_fwd_lft == 0)) || !rst_n)
		i = 0;
	else if ((prev_fwd_lft == 1) && (fwd_lft == 0)) 
		$display("fwd_lft duty: %d\n",i);
	else
		i = i + 1;
end

always @(posedge clk)begin
	if (((rev_lft == 0) && (prev_rev_lft == 0)) || !rst_n)
		j = 0;
	else if ((prev_rev_lft == 1) && (fwd_rev == 0)) 
		$display("rev_lft duty: %d\n",j);
	else
		j = j + 1;
end

always @(posedge clk)begin
	if (((fwd_rht == 0) && (prev_fwd_rht == 0)) || !rst_n)
		k = 0;
	else if ((prev_fwd_rht == 1) && (fwd_rht == 0)) 
		$display("fwd_rht duty: %d\n",k);
	else
		k = k + 1;
end

always @(posedge clk)begin
	if (((rev_rht == 0) && (prev_rev_rht == 0)) || !rst_n)
		l = 0;
	else if ((prev_rev_rht == 1) && (rev_rht == 0)) 
		$display("rev_rht duty: %d\n",l);
	else
		l = l + 1;
end

initial begin
  clk = 0;
	lft = 11'b00000111111;
	rht = 11'b00001111111;
  rst_n =0;
  #2;
  rst_n = 1; 
  #2;

end
  
always
 #1 clk =~clk;


endmodule
