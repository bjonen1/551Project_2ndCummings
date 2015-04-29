//WORKING!
module uart_tx(clk, rst_n, strt_tx, tx, tx_data, tx_done);

input clk, rst_n, strt_tx;
input [7:0] tx_data;
output tx, tx_done;

wire load, transmitting, set_done, clr_done;
reg [9:0] tx_shft_reg;
reg [11:0] baud_cnt;
reg [3:0] bit_cnt;
reg shift;
reg tx_done_preOut;
wire set_baud0;
TX_SM SM1(clk,rst_n,strt_tx, bit_cnt, transmitting, load, clr_done, set_done);

//THIS BLOCK IS ALL OF THE BAUD CNTR
always @(posedge clk)begin
 case ({set_baud0, transmitting})
   2'b11: baud_cnt <= 12'h000;
   2'b10: baud_cnt <= 12'h000;
   2'b01: baud_cnt <= baud_cnt + 1;
   2'b00: baud_cnt <= baud_cnt;
 endcase
 case(baud_cnt)
  2603: shift <= 1;
  default: shift <= 0;
 endcase
end
assign set_baud0 = shift | load;


//THIS BLOCK IS ALL OF THE BIT CNTR
always @(posedge clk)begin
 case ({load, shift})
   2'b11: bit_cnt <= 4'h0;
   2'b10: bit_cnt <= 4'h0;
   2'b01: bit_cnt <= bit_cnt + 1;
   2'b00: bit_cnt <= bit_cnt;
 endcase
end

//THIS IS THE SHIFT REG AND OUTPUT LOGIC
always @(posedge clk)begin
 if (!rst_n)
   tx_shft_reg <= 10'h3FF;
 else begin
 case ({load, shift})
   2'b11: tx_shft_reg <= {1'b1,tx_data,1'b0};
   2'b10: tx_shft_reg <= {1'b1,tx_data,1'b0};
   2'b01: tx_shft_reg <= {1'b1,tx_shft_reg[8:1]};
   2'b00: tx_shft_reg <= tx_shft_reg;
 endcase
 end
end
assign tx = tx_shft_reg[0];

//here is all of tx_done logic
always @(posedge clk or negedge rst_n)begin
  if (rst_n == 1'b0)
    tx_done_preOut <= 1'b0;
  else if (clr_done == 1'b1)
    tx_done_preOut <= 1'b0;
  else if (set_done)
	tx_done_preOut <= 1'b1;
  else
    tx_done_preOut <= tx_done_preOut;
end
assign tx_done = tx_done_preOut;

endmodule

//working!
module TX_SM(clk,rst_n,trmt, bit_cnt, transmitting, load, clr_done, set_done);

  input clk, rst_n, trmt;
  input [3:0] bit_cnt;
  
  output transmitting, load, clr_done, set_done;

  logic transmitting, load, clr_done, set_done;

  typedef enum reg {RESET, TRANSMIT} state_t;
  state_t state, next_state;

  always_ff @(posedge clk, negedge rst_n)begin
    if (!rst_n)
      state <= RESET;
    else
      state <= next_state;
  end
  always_comb begin
//default outputs 
 transmitting = 0;
  load = 0;
 clr_done = 0;
  set_done = 0;
  next_state = RESET;

  case(state)
    TRANSMIT : begin
      if (bit_cnt[3:0]  == 4'hA)
	set_done = 1'b1;
      else begin
        next_state = TRANSMIT;
	transmitting = 1'b1;
	end
    end
    
    default:  begin//default is reset
      if (trmt)begin
        next_state = TRANSMIT;
	clr_done = 1'b1;
	load = 1'b1;
	end
      else
	next_state = RESET;
      end
  endcase
  end
endmodule
/*
module UART_TX_TB ();
reg clk, rst_n, trmt;
reg [7:0] tx_data;
wire TX, tx_done;

UART_tx UART1(clk, rst_n, trmt, TX, tx_data, tx_done);

initial begin
  clk = 0;
  trmt = 0;
  rst_n =0;
  #2;
  rst_n = 1;
  #2;
  tx_data = 8'b11001100;
  #2;
  trmt = 1;
  #2;
  trmt = 0;
end
  
always
 #1 clk =~clk;

endmodule
*/
