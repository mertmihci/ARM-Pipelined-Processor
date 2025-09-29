module Instruction_memory#(parameter BYTE_SIZE=4, ADDR_WIDTH=32)(
input [ADDR_WIDTH-1:0] ADDR,
output [(BYTE_SIZE*8)-1:0] RD 
);

reg [7:0] mem [0:255];

initial begin
$readmemh("Instructions.hex", mem, 0); // You will need this for real tests
end
genvar i;
generate
	for (i = 0; i < BYTE_SIZE; i = i + 1) begin: read_generate
		assign RD[8*i+:8] = mem[ADDR+i];
	end
endgenerate
endmodule
