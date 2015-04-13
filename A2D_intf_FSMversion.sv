module A2D_intf(clk,rst_n,strt_cnv,cnv_cmplt,chnnl,res,a2d_SS_n,SCLK,MOSI,MISO);

	input clk,rst_n,strt_cnv,MISO;
	input [2:0] chnnl;
	output cnv_cmplt,a2d_SS_n,SCLK,MOSI;
	output [11:0] res;


	reg [1:0] state;
	reg [1:0] nxt_state;
	
	localparam IDLE = 2'b00;
	localparam SEND_MOSI = 2'b01;
	localparam REC_MISO = 2'b10;
	localparam ERROR = 2'b11;

	localparam sixteen = 6'b01_0000;

	//strt_cnv signal conditioning - Flops//
	always @ (posedge clk, negedge rst_n)
	  if(!rst_n)begin
	    q1 <= 1'b0;
	    q2 <= 1'b0;
		end
	  else begin
	    q1 <= strt_cnv;
	    q2 <= q1;
		end
		
	assign strt_cnv_FLTRD = q1 & q2;


	//FSM

	always @ (posedge clk, negedge rst_n)begin
		if(!rst_n)
		state <= IDLE;
		else
		state <= nxt_state;
	end

	always @ (strt_cnv_FLTRD, posedge clk) begin
		nxt_state = IDLE;
		cnv_cmplt = 1'b1;
		a2d_SS_n = 1'b1;  //active low slave select
		//res = ?
		//MOSI = ?
		//SCLK = ?

		case (state)
			IDLE:////////////////IDLE//////////////////
			if(strt_cnv_FLTRD)begin
			     nxt_state = SEND_MOSI;
			     cnv_cmplt = 1'b0;
				end
			 else 
			     nxt_state = IDLE;
			///////////////////////////////////////

			SEND_MOSI://////////////SEND_MOSI/////
			   if(shft_cntr < sixteen)begin
				nxt_state = SEND_MOSI;
				//shift control signal w/counter
				//SCLK control signal
				 	       end   
			    else 
			        nxt_state = REC_MISO;
			///////////////////////////////////////              
			
			REC_MISO://///////////REC_MISO/////////
			   if(shift_cntr
			end
