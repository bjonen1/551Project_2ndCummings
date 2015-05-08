`timescale 1ns/1ps
module Follower_tb();

reg clk,rst_n;			// 50MHz clock and active low aysnch reset
reg OK2Move;
reg send_cmd,send_BC;
reg [7:0] cmd,Barcode;
reg clr_buzz_cnt;
reg error;

wire a2d_SS_n, SCLK, MISO, MOSI;
wire rev_rht, rev_lft, fwd_rht, fwd_lft;
wire IR_in_en, IR_mid_en, IR_out_en;
wire buzz, buzz_n, in_transit, BC, TX_dbg;
wire [7:0] led;
wire [3:0] buzz_cnt,buzz_cnt_n;
wire [9:0] duty_fwd_rht,duty_fwd_lft,duty_rev_rht,duty_rev_lft;
wire fl_duty_rdy, rl_duty_rdy, fr_duty_rdy, rr_duty_rdy;

////////////////////////////////////////////
// Declare any localparams that might    //
// improve code readability below here. //
/////////////////////////////////////////
localparam [7:0] STOP = {2'b00,6'h00};
localparam [7:0] GO = {2'b01, 6'h00};

//////////////////////
// Instantiate DUT //
////////////////////
Follower iDUT(.clk(clk),.RST_n(rst_n),.led(led),.a2d_SS_n(a2d_SS_n),
              .SCLK(SCLK),.MISO(MISO),.MOSI(MOSI),.rev_rht(rev_rht),.rev_lft(rev_lft),.fwd_rht(fwd_rht),
			  .fwd_lft(fwd_lft),.IR_in_en(IR_in_en),.IR_mid_en(IR_mid_en),.IR_out_en(IR_out_en),
			  .in_transit(in_transit),.OK2Move(OK2Move),.buzz(buzz),.buzz_n(buzz_n),.RX(RX),.BC(BC));		
			  
//////////////////////////////////////////////////////
// Instantiate Model of A2D converter & IR sensors //
////////////////////////////////////////////////////
ADC128S iA2D(.clk(clk),.rst_n(rst_n),.SS_n(a2d_SS_n),.SCLK(SCLK),.MISO(MISO),.MOSI(MOSI));

/////////////////////////////////////////////////////////////////////////////////////
// Instantiate 8-bit UART transmitter (acts as Bluetooth module sending commands) //
///////////////////////////////////////////////////////////////////////////////////
uart_tx iTX(.clk(clk),.rst_n(rst_n),.tx(RX),.strt_tx(send_cmd),.tx_data(cmd),.tx_done(cmd_sent));

//////////////////////////////////////////////
// Instantiate barcode mimic (transmitter) //
////////////////////////////////////////////
barcode_mimic iMSTR(.clk(clk),.rst_n(rst_n),.period(22'h1000),.send(send_BC),.station_ID(Barcode),.BC_done(BC_done),.BC(BC));

/////////////////////////////////////////////////
// Instantiate any other units you might find //
// useful for monitoring/testing design.     //
//////////////////////////////////////////////
duty_finder dutyFL(.clk(clk), .rst_n(rst_n), .pwm(fwd_lft), .duty(duty_fwd_lft), .rdy(fl_duty_rdy));
duty_finder dutyRL(.clk(clk), .rst_n(rst_n), .pwm(rev_lft), .duty(duty_rev_lft), .rdy(rl_duty_rdy));
duty_finder dutyFR(.clk(clk), .rst_n(rst_n), .pwm(fwd_rht), .duty(duty_fwd_rht), .rdy(fr_duty_rdy));
duty_finder dutyRR(.clk(clk), .rst_n(rst_n), .pwm(rev_rht), .duty(duty_rev_rht), .rdy(rr_duty_rdy));


//current problem
// rht, lft, fwd are almost always 0
// Can't really test fwd/rev_lft/rht
// Seems to be correct, A2D result is usually 0
				
initial begin
  ///////////////////////////////////////////////////
  // This is main body of your test.              //
  // Keep in mind you don't have to do this as   //
  // one big super test.  It would be better to //
  // have a suite of smaller top level tests.  //
  //////////////////////////////////////////////
  clk = 0;
  rst_n = 0;
  error = 0;
  OK2Move = 0;
  send_cmd = 0;
  send_BC = 0;
  cmd = STOP;
  Barcode = 8'h00;
  
  repeat(4)@(negedge clk);
  rst_n = 1;
  OK2Move = 1;
  
  send_id(8'h01);
  
  send_go_command(6'h02);
	
  send_id(8'h02);
  if(in_transit)
	$display("Error: Should have stopped");
  //$stop;
  
  send_go_command(6'h01);
  repeat(100)@(posedge clk);
  
  send_stop_command();
  //$stop;
  repeat(100)@(posedge clk);
  
  test_proximity();
  
  //test forward incrementing
  send_go_command(6'h01);
  
  $stop;

end

always
  #1 clk = ~ clk;
  
  task send_go_command;
	input [5:0] dest;
	
	begin
		cmd = GO | dest;
		send_cmd = 1;
		@(posedge clk);
		send_cmd = 0;
		$display("Sent go command");
		@(posedge cmd_sent);
		if(!in_transit) begin
			$display("Error: Should be moving");
			error = 1;
			@(posedge clk);
			error = 0;
		end
	end
  endtask
  
  task send_stop_command;

	begin
		cmd = STOP;
		send_cmd = 1;
		@(posedge clk);
		send_cmd = 0;
		$display("Sent stop command");
		@(posedge cmd_sent);
		if(in_transit) begin
			$display("Error: Should have stopped");
			error = 1;
			@(posedge clk);
			error = 0;
		end
	end
  endtask
  
  task send_id;
	input [7:0] id;
	
	begin
	  Barcode = id;
	  send_BC = 1;
	  @(posedge clk);
	  send_BC = 0;
	  @(posedge BC_done);
	  $display("Sent ID 0x%x", id);
	end
  endtask
  
  task test_proximity;
	begin
	  send_go_command(6'h01);
	  OK2Move = 0;
	  $display("OK2Move deasserted");
	  repeat(5)@(posedge clk);
	  if(!fwd_lft | !fwd_rht | !rev_lft | !rev_rht) begin
		$display("Error: Should have stopped");
		error = 1;
		@(posedge clk);
		error = 0;
	  end
	  //needs to be on long enough to see the buzzer duty cycle
	  repeat(1000000)@(posedge clk);
	  OK2Move = 1;
	  $display("OK2Move asserted");
	end
  endtask
endmodule