module Register_reset#(
     parameter WIDTH=8)
    (
	  input  clk, reset,
	  input	[WIDTH-1:0] DATA,
	  output reg [WIDTH-1:0] OUT
    );
initial begin
	OUT<=0;
end
	 
always@(posedge clk) begin
	if (reset == 1'b1)
		OUT<={WIDTH{1'b0}};		
	else	
		OUT<=DATA;
end
	 
endmodule	 