module A2D_test(clk,RST_n,nxt_chnnl,LEDs,a2d_SS_n,MOSI,MISO,SCLK);

input clk,RST_n;		// 50MHz clock and active low unsynchronized reset from push button
input nxt_chnnl;		// unsynchronized push button.  Advances to convert next chnnl
output [7:0] LEDs;		// upper bits of conversion displayed on LEDs
output a2d_SS_n;		// Active low slave select to A2D (part of SPI bus)
output MOSI;			// Master Out Slave In to A2D (part of SPI bus)
input MISO;				// Master In Slave Out from A2D (part of SPI bus)
output SCLK;			// Serial clock of SPI bus

///////////////////////////////////////////////////
// Declare any registers or wires you need here //
/////////////////////////////////////////////////
wire [11:0] res;		// result of A2D conversion

/////////////////////////////////////
// Instantiate Reset synchronizer //
///////////////////////////////////
reset_synch iRST(.clk(clk), .RST_n(RST_n), .rst_n(rst_n));

////////////////////////////////
// Instantiate A2D Interface //
//////////////////////////////
A2D_intf iA2D(.clk(clk), .rst_n(rst_n), .strt_cnv(strt_cnv), .cnv_cmplt(), .chnnl(chnnl),
              .res(res), .a2d_SS_n(a2d_SS_n), .SCLK(SCLK), .MOSI(MOSI), .MISO(MISO));


////////////////////////////////////////
// Synchronize nxt_chnnl push button //
//////////////////////////////////////
 

///////////////////////////////////////////////////////////////////
// Implement method to increment channel and start a conversion //
// with every release of the nxt_chnnl push button.            //
////////////////////////////////////////////////////////////////
	
	
	
assign LEDs = res[11:4];

endmodule
    
