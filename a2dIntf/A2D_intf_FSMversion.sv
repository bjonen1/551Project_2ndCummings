module A2D_intf(clk,rst_n,strt_cnv,cnv_cmplt,chnnl,res,a2d_SS_n,SCLK,MOSI,MISO);

	input clk,rst_n,strt_cnv,MISO;
	input [2:0] chnnl;
	output reg cnv_cmplt,a2d_SS_n,SCLK,MOSI;
	output reg [11:0] res;
  
  reg toggle_sclk;
  reg clk_cnt_en;     //clk count enable
  reg [4:0] clk_cntr; //counts SCLK period
	reg [1:0] state;
	reg [1:0] nxt_state;
	reg [15:0] shift_reg;
	reg load_shift_reg;
	reg shift_now;
	reg [4:0] shift_cnt;
	reg shift_cnt_rst;
	reg SCLK_en;
	reg clr_cnv_cmplt;
	reg set_cnv_cmplt;
	reg set_SS_n;
	reg clr_SS_n;
	reg first_time;
	reg set_first_time;
	reg clr_first_time;
	
	localparam IDLE = 2'b00;
	localparam SEND_MOSI = 2'b01;
	localparam REC_MISO = 2'b10;
	localparam BACK_PORCH = 2'b11;

	localparam sixteen = 4'b1111;  //SCLK toggles at 1/2 of 32

	//strt_cnv signal conditioning - Flops//
	
		
	assign strt_cnv_FLTRD = strt_cnv;
	
	//clk_cntr
	always @ (posedge clk, negedge rst_n)
		if(!rst_n)
		  clk_cntr <= 5'h0;
		else if (clk_cnt_en == 1'b0)
		   clk_cntr <= 5'h0;
		else 
		   clk_cntr <= clk_cntr + 1;
					
	//SCLK Generation//
 /* always @ (posedge clk, negedge rst_n)
     if (!rst_n)
       SCLK <= 1'b1;
     else if (!SCLK_en)
       SCLK <= 1'b1;
     else if(clk_cntr == sixteen || clk_cntr == 5'b1_1111 )
      SCLK <= ~SCLK;
     else
       SCLK <= SCLK;*/
	assign SCLK = ~clk_cntr[4];
       
  //a2d_SS_n
  always @(posedge clk, negedge rst_n)
    if(!rst_n)
      a2d_SS_n <= 1'b1;
    else if(set_SS_n)
      a2d_SS_n <= 1'b0;
    else if(clr_SS_n)
      a2d_SS_n <= 1'b1;
      
  //first_time encountered falling edge or not
  always @(posedge clk, negedge rst_n)
    if(!rst_n)
      first_time <= 1'b1;
    else if(set_first_time)
      first_time <= 1'b1;
    else if(clr_first_time)
      first_time <= 1'b0;
       
  //cnv_cmplt
  always @ (posedge clk, negedge rst_n)
    if(!rst_n)
      cnv_cmplt <= 1'b0;
    else if (set_cnv_cmplt)
      cnv_cmplt  <= 1'b1;
    else if (clr_cnv_cmplt)
      cnv_cmplt <= 1'b0;
       
  //Shift counter//
  always @ (posedge clk, negedge rst_n)
    if(!rst_n)
      shift_cnt <= 5'd0;
    else if(shift_cnt_rst)
      shift_cnt <= 5'd0;
    else if(shift_now)
      shift_cnt <= shift_cnt + 1;
    else 
    shift_cnt <= shift_cnt;
    
  //Shift Register
  always @ (posedge clk, negedge rst_n)
    if(!rst_n)
      shift_reg <= 16'd0;
    else if (load_shift_reg)
      shift_reg <= {2'b00,chnnl,11'b000};
    else if (shift_now)
      shift_reg <= {shift_reg[14:0],MISO};
      
  assign MOSI = shift_reg[15];
    
  //res//
  assign res = ~shift_reg[11:0];  
	//FSM

	always @ (posedge clk, negedge rst_n)begin
		if(!rst_n)
		state <= IDLE;
		else
		state <= nxt_state;
	end
	
	always @ (*) begin
		nxt_state = IDLE;
		clr_cnv_cmplt = 1'b0;
		set_cnv_cmplt = 1'b0;
		set_SS_n = 1'b0;
		clr_SS_n = 1'b0;
		set_first_time = 1'b0;
		clr_first_time = 1'b0;
		clk_cnt_en = 1'b0;
		shift_now = 1'b0;
		shift_cnt_rst = 1'b1;
		load_shift_reg = 1'b0;
		//res = ?
		//MOSI = ?
		SCLK_en = 1'b1;

		case (state)
			IDLE:////////////////IDLE//////////////////
			if(strt_cnv_FLTRD)begin
			     nxt_state = SEND_MOSI;
			     clr_cnv_cmplt = 1'b1;
			     clk_cnt_en = 1'b1;
			     load_shift_reg =1'b1;
			     set_SS_n = 1'b1;
				end
			 else begin
			     nxt_state = IDLE;
			     clk_cnt_en = 1'b1;
			     shift_cnt_rst = 1'b0;
			     SCLK_en = 1'b0;
			     set_first_time = 1'b1;
			     end
			///////////////////////////////////////

			SEND_MOSI://////////////SEND_MOSI/////
			   if(shift_cnt  == 5'd16)begin
			        nxt_state = REC_MISO;
			        clk_cnt_en = 1'b1;
			        shift_cnt_rst = 1'b1;
			         end
			   else begin
				      nxt_state = SEND_MOSI;
				      clk_cnt_en = 1'b1;
				      shift_cnt_rst = 1'b0;
				      if(clk_cntr == 5'd14)//*changed 
				        if(!first_time)
				          shift_now = 1'b1;
				        else
				          clr_first_time = 1'b1;
				      
				 	       end   
			///////////////////////////////////////              
			
			REC_MISO://///////////REC_MISO/////////
			   if(shift_cnt < 5'd16)begin
				  nxt_state = REC_MISO;
				  clk_cnt_en = 1'b1;
				  shift_cnt_rst = 1'b0;
				  if(clk_cntr == 5'd14)//*changed 
				    shift_now = 1'b1;
				 end
				  else begin
				    nxt_state = BACK_PORCH;
				    end
				    
			BACK_PORCH:///////////Back Porch /////
			   begin
			   if(clk_cntr < 5'd32)begin
			     nxt_state = BACK_PORCH;
			     clk_cnt_en = 1'b1;
			     end
			   else begin
			     nxt_state = IDLE;
			     set_cnv_cmplt = 1'b1;
			     clr_SS_n = 1'b1;
			     end
			   end
			   
			
			
			endcase
			end
			endmodule
				


		










