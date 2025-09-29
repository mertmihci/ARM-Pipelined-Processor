module Extender (
    output reg [31:0]Extended_data,
    input [23:0]DATA,
    input [1:0]select
);

always @(*) begin
    case (select)
        2'b00: Extended_data = {24'd0, DATA[7:0]};
        2'b01: Extended_data = {20'd0, DATA[11:0]};
        2'b10: Extended_data = {{6{DATA[23]}}, DATA[23:0], 2'b0};
        default: Extended_data = 32'd0;
    endcase
end
    
endmodule
