`timescale 1ns / 1ps

module SSD(
        input wire [3:0] value,
        output reg [6:0] display
    );
    
    always@(*) begin
        case(value)
            0: display = ~7'b0111111;
            1: display = ~7'b0000110;
            2: display = ~7'b1011011;
            3: display = ~7'b1001111;
            4: display = ~7'b1100110;
            5: display = ~7'b1101101;
            6: display = ~7'b1111101;
            7: display = ~7'b0000111;
            8: display = ~7'b1111111;
            9: display = ~7'b1101111;
            10: display = ~7'b1110111;
            11: display = ~7'b1111100;
            12: display = ~7'b0111001;
            13: display = ~7'b1011110;
            14: display = ~7'b1111001;
            15: display = ~7'b1110001;
        endcase
    end
    
endmodule
