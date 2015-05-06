//it works yo
module RX_SM(clk,rst_n,clr_rdy, RX, rdy, bit_cnt, receiving, load, clrOut_rdy, set_rdy);

  input clk, rst_n, clr_rdy, RX, rdy;
  input [3:0] bit_cnt;
  
  output logic receiving, load, clrOut_rdy, set_rdy;
  //logic receiving, load, clrOut_rdy, set_rdy;

  typedef enum reg {RESET, RECEIVE} state_t;
  state_t state, next_state;

  always_ff @(posedge clk, negedge rst_n)begin
    if (!rst_n)
      state <= RESET;
    else
      state <= next_state;
  end
  always_comb begin
//default outputs 
 receiving = 0;
  load = 0;
 clrOut_rdy = 0;
  set_rdy = 0;
  next_state = RESET;

  case(state)
    RECEIVE : begin
      if (bit_cnt == 4'h9)begin
		set_rdy = 1'b1;
		next_state = RESET;
		end
     else begin
		next_state = RECEIVE;
		receiving = 1'b1;
		end
    end
    
    default:  begin//default is reset
     if (RX == 1'b0 && !rdy)begin
        next_state = RECEIVE;
		clrOut_rdy= 1'b1; //if the last byte was not cleared/read, we just lose it and read the next incoming byte
		receiving = 1'b1;
		end
      else if (clr_rdy)begin
		next_state = RESET;
		load = 1'b1;
		clrOut_rdy = 1'b1;
		end
      else begin
        next_state = RESET;
		load = 1'b1;
		end
     end
  endcase
  end
endmodule

//it works yo
module uart_rcv(clk, rst_n, RX, clr_rx_rdy, rx_rdy, rx_data);

input clk, rst_n, RX, clr_rx_rdy;
output rx_rdy;
output [7:0] rx_data;

wire load, receiving, set_rdy, clrOut_rdy;
reg [7:0] rx_shft_reg;
reg [11:0] baud_cnt;
reg [3:0] bit_cnt;
reg shift;
reg rdy_preOut;
reg half_init;
wire set_baud0;
RX_SM SM1(clk,rst_n,clr_rx_rdy, RX, rx_rdy, bit_cnt, receiving, load, clrOut_rdy, set_rdy);

//THIS BLOCK IS ALL OF THE BAUD CNTR
always @(posedge clk or negedge rst_n)begin
 if(~rst_n)begin
	baud_cnt <= 12'h000;
	half_init <= 0;
	shift <= 0;
 end
 else begin
 case ({set_baud0, receiving})
   2'b11: baud_cnt <= 12'h000;
   2'b10: baud_cnt <= 12'h000;
   2'b01: baud_cnt <= baud_cnt + 1;
   2'b00: baud_cnt <= baud_cnt;
 endcase
 case(baud_cnt)
  0: half_init <= 0; 
  2603: shift <= 1;
  1301: if (half_init == 1'b0 && bit_cnt == 4'h0)begin
            shift <= 1'b1;
	    half_init <= 1'b1; //set the flag that weve now waited that half cycle. dont do it again until the next word
	end

  default: shift <= 0;
 endcase
 end
end
assign set_baud0 = shift | load;


//THIS BLOCK IS ALL OF THE BIT CNTR
always @(posedge clk or negedge rst_n)begin
 if(~rst_n)
	bit_cnt <= 4'h0;
 else begin
 case ({load, shift})
   2'b11: begin
	bit_cnt <= 4'h0;
	//half_init <= 1'b0;
	end
   2'b10: begin
	bit_cnt <= 4'h0;
	//half_init <= 1'b0;
	end
   2'b01: bit_cnt <= bit_cnt + 1;
   2'b00: bit_cnt <= bit_cnt;
 endcase
 end
end

//THIS IS THE SHIFT REG AND OUTPUT LOGIC
always @(posedge clk or negedge rst_n)begin
 if (~rst_n)
	rx_shft_reg <= 8'h00;
 else begin
 case (shift)
   1'b1: rx_shft_reg[7:0] <= {RX,rx_shft_reg[7:1]};
   1'b0: rx_shft_reg <= rx_shft_reg;
 endcase
 end
end
assign rx_data = rx_shft_reg;

//here is all of tx_done logic
always @(posedge clk or negedge rst_n)begin
  if (rst_n == 1'b0)
    rdy_preOut <= 1'b0;
  else if (clrOut_rdy == 1'b1)
    rdy_preOut <= 1'b0;
  else if (set_rdy)
	rdy_preOut <= 1'b1;
  else
    rdy_preOut <= rdy_preOut;
end
assign rx_rdy = rdy_preOut;

endmodule

module UART_BOTH_TB ();
reg clk, rst_n, trmt, clr_rdy;
reg [7:0] tx_data;
wire TX, tx_done, rx_rdy;
wire [7:0] rx_data;

UART_tx UART1(clk, rst_n, trmt, TX, tx_data, tx_done);
UART_rx UART2(clk, rst_n, TX, clr_rdy, rdy, rx_data);


initial begin
  clk = 0;
  trmt = 0;
  rst_n =0;
  clr_rdy = 0;
  #2;
  rst_n = 1;
  #2;
  tx_data = 8'h01;
  #2;
  trmt = 1;
  #2;
  trmt = 0;

  #100000;
  clr_rdy = 1;
  #100
  clr_rdy = 0;
  #100000;
  tx_data = 8'h02;
  #100000;
  trmt = 1;
  #2;
  trmt = 0;
end
  
always
 #1 clk =~clk;

endmodule
