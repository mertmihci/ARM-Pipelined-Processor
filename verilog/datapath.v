module datapath(
    input wire clk, RESET, StallF, PCSrcW, BranchTakenE, FlushD, StallD, linkW, RegWriteW, FlushE, ALUSrcE, MemWriteM, MemToRegW,
    input wire [1:0] RegSrcD, ImmSrcD, ForwardAE, ForwardBE, shctrl,
    input wire [3:0] Debug_Source_select, ALUCtrlE,
    input wire [4:0] shamt,
    output wire [3:0] RA1D, RA2D, RA1E, RA2E, WA3E, WA3M, WA3W, Flags,
    output wire [31:0] PC, InstrD, Debug_out
);


wire [3:0]  RA3D;
wire [31:0] PC_pre_in, PC_in, PCPlus8D, ResultW, InstrF, WD3, RD1D, RD2D, ExtImmD, PCBranchD, BX_Result, RD1E, RD2E, ExtImmE, SrcAE, SrcBE;
wire [31:0] SrcBE_preshift, ALUResultE, ALUResultM, DecidedR2, WriteDataM, ReadDataM, ReadDataW, ALUResultW;

//------------FETCH---------------------
Register_rsten #(32) PCReg(.clk(clk), .reset(RESET) , .we(StallF), .DATA(PC_in), .OUT(PC));

Adder pcadder(PC, 32'h4, PCPlus8D);
Mux_2to1 #(32) R15_OP_MUX(.select(PCSrcW), .input_0(PCPlus8D), .input_1(ResultW), .output_value(PC_pre_in));
Mux_2to1 #(32) Branch_OP_MUX(.select(BranchTakenE), .input_0(PC_pre_in), .input_1(ALUResultE), .output_value(PC_in));

Instruction_memory IDmem(.ADDR(PC), .RD(InstrF));

//------------DECODE--------------------
Register_rsten #(32) IR(.clk(clk), .reset(FlushD) , .we(StallD), .DATA(InstrF), .OUT(InstrD));

Mux_2to1 RA1_Mux(.select(RegSrcD[0]), .input_0(InstrD[19:16]), .input_1(4'hF), .output_value(RA1D));
Mux_2to1 RA2_Mux(.select(RegSrcD[1]), .input_0(InstrD[3:0]), .input_1(InstrD[15:12]), .output_value(RA2D));
Mux_2to1 RA3_Mux(.select(linkW), .input_0(WA3W), .input_1(4'hE), .output_value(RA3D));
Mux_2to1 #(32) WD_Mux(.select(linkW), .input_0(ResultW), .input_1(PCW), .output_value(WD3));

Register_file reg_file_dp(.clk(clk), .write_enable(RegWriteW), .reset(RESET), .Source_select_0(RA1D), .Source_select_1(RA2D),
    .Debug_Source_select(Debug_Source_select), .Destination_select(RA3D), .DATA(WD3), .Reg_15(PCPlus8D), .out_0(RD1D), .out_1(RD2D),
    .Debug_out(Debug_out));

Extender extD(.Extended_data(ExtImmD), .DATA(InstrD[23:0]), .select(ImmSrcD));

//------------EXECUTE-------------------
Register_reset #(32) RD1(.clk(clk), .reset(FlushE), .DATA(RD1D), .OUT(RD1E));
Register_reset #(32) RD2(.clk(clk), .reset(FlushE), .DATA(RD2D), .OUT(RD2E));
Register_reset #(32) extE(.clk(clk), .reset(FlushE), .DATA(ExtImmD), .OUT(ExtImmE));
Register_reset #(4)  WA3EReg(.clk(clk), .reset(FlushE), .DATA(InstrD[15:12]), .OUT(WA3E));
Register_reset #(4)  RA1EReg(.clk(clk), .reset(FlushE), .DATA(RA1D), .OUT(RA1E));
Register_reset #(4)  RA2EReg(.clk(clk), .reset(FlushE), .DATA(RA2D), .OUT(RA2E));

Mux_4to1 #(32) ForwardMuxA(.select(ForwardAE), .input_0(RD1E), .input_1(ResultW), .input_2(ALUResultM), .input_3(32'h0), .output_value(SrcAE));
Mux_4to1 #(32) ForwardMuxB(.select(ForwardBE), .input_0(RD2E), .input_1(ResultW), .input_2(ALUResultM), .input_3(32'h0), .output_value(DecidedR2));
Mux_2to1 #(32) SrcBMUX(.select(ALUSrcE), .input_0(DecidedR2), .input_1(ExtImmE), .output_value(SrcBE_preshift));

shifter #(32) Shifter(.control(shctrl), .shamt(shamt), .DATA(SrcBE_preshift), .OUT(SrcBE));

ALU #(32) alu(.control(ALUCtrlE), .CI(Flags[1]), .DATA_A(SrcAE), .DATA_B(SrcBE), .OUT(ALUResultE), .CO(Flags[1]), .OVF(Flags[0]), .N(Flags[3]), .Z(Flags[2]));

//------------MEMORY--------------------
wire [31:0] PCM;
wire [31:0] PCE;

Adder pccalc(RD1E, 32'hFFFFFFFC, PCE);
Register_reset #(32) ALUM(.clk(clk), .reset(RESET), .DATA(ALUResultE), .OUT(ALUResultM));
Register_reset #(32) WriteData(.clk(clk), .reset(RESET), .DATA(DecidedR2), .OUT(WriteDataM));
Register_reset #(32) PCRegM(.clk(clk), .reset(RESET), .DATA(PCE), .OUT(PCM));
Register_reset #(4) WA3MReg(.clk(clk), .reset(RESET), .DATA(WA3E), .OUT(WA3M));

Memory datamem(.clk(clk), .WE(MemWriteM), .ADDR(ALUResultM), .WD(WriteDataM), .RD(ReadDataM));

//------------WRITE---------------------
wire [31:0] PCW;

Register_reset #(32) ReadData(.clk(clk), .reset(RESET), .DATA(ReadDataM), .OUT(ReadDataW));
Register_reset #(32) ALUW(.clk(clk), .reset(RESET), .DATA(ALUResultM), .OUT(ALUResultW));
Register_reset #(4) WA3WReg(.clk(clk), .reset(RESET), .DATA(WA3M), .OUT(WA3W));
Register_reset #(32) PCRegW(.clk(clk), .reset(RESET), .DATA(PCM), .OUT(PCW));

Mux_2to1 #(32) ResultMUX(.select(MemToRegW), .input_0(ALUResultW), .input_1(ReadDataW), .output_value(ResultW));
endmodule

//iverilog -o datapath.out datapath.v Register_reset.v Mux_2to1.v Mux_4to1.v Memory.v Instruction_memory.v ALU.v shifter.v Adder.v Extender.v Register_file.v Register_rsten.v Register_rsten_neg.v Decoder_4to16.v Mux_16to1.v 