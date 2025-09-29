module Register_simple #(
     parameter WIDTH=8)
    (
	  input  clk,
	  input	[WIDTH-1:0] DATA,
	  output reg [WIDTH-1:0] OUT
    );

initial begin
	OUT<=0;
end	 

always@(posedge clk) begin
	OUT<=DATA;
end
	 
endmodule	 