# ==============================================================================
# Authors:              Doğu Erkan Arkadaş
#
# Cocotb Testbench:     For Single Cycle ARM Laboratory
#
# Description:
# ------------------------------------
# Test bench for the single cycle laboratory, used by the students to check their designs
#
# License:
# ==============================================================================

import logging
import cocotb
from Helper_lib import read_file_to_list,Instruction,rotate_right, shift_helper, ByteAddressableMemory,reverse_hex_string_endiannes,Result, Constants,Instruction_types
from Helper_Student import Log_Datapath,Log_Controller, Log_Hazard_Unit, ToHex
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, RisingEdge, Timer



class TB:
    def __init__(self, Instruction_list,dut,dut_PC,dut_regfile, dp2pc_stall_cycles=4):
        self.dut = dut
        self.dut_PC = dut_PC
        self.dut_regfile = dut_regfile
        self.Instruction_list = Instruction_list
        self.result_list = []
        #Configure the logger
        self.logger = logging.getLogger("Performance Model")
        self.logger.setLevel(logging.DEBUG)
        #Initial values are all 0 as in a FPGA
        self.PC = 0
        self.Z_flag = 0
        self.Register_File =[]
        for i in range(16):
            self.Register_File.append(0)
        #Memory is a special class helper lib to simulate HDL counterpart    
        self.memory = ByteAddressableMemory(1024)

        self.clock_cycle_count = 0

        self.dp2pc_stall_cycles = dp2pc_stall_cycles  # Number of cycles a data processing operation to R15 will stall.
          
    #Calls user populated log functions    
    def log_dut(self):
        Log_Datapath(self.dut,self.logger)
        Log_Controller(self.dut,self.logger)
        Log_Hazard_Unit(self.dut,self.logger)

    #Compares and logs the PC and register file of Python module and HDL design
    def compare_result(self,result):
        self.logger.debug("************* Performance Model / DUT Data  **************")
        self.logger.debug("PC:0x%x \t PC:0x%x",result.PC,self.dut_PC.value.integer)
        for i in range(15):
            self.logger.debug("Register:%d: 0x%x \t 0x%x",i,result.Register_File[i], self.dut_regfile.Reg_Out[i].value.integer)
        self.logger.debug("Register:%d: Not checked \t 0x%x",15, self.dut_regfile.Reg_15.value.integer)
        if (result.PC>=0):
            assert result.PC == self.dut_PC.value
        for i in range(15):
           assert result.Register_File[i] == self.dut_regfile.Reg_Out[i].value
        
    #Function to write into the register file, handles writing into R15(PC)
    def write_to_register_file(self,register_no, data):
        if(data <0):
            data = data +(1 << 32)
        if(register_no == 15):
            self.PC = data
        else:
            self.Register_File[register_no] = data
    def check_for_hazard(self):
        for instruction in self.result_list[:]:
            #Check for Branches which means 2 stages flushed
            if(instruction.instruction_type == Instruction_types.BRANCH):
                current_index = self.result_list.index(instruction)
                previous_instruction = self.result_list[current_index-1]
                self.result_list.insert(current_index,Result(instruction.Register_File,previous_instruction.PC+4,-1,Instruction_types.STALLFLUSH))
                self.result_list.insert(current_index+1,Result(instruction.Register_File,previous_instruction.PC+8,-1,Instruction_types.STALLFLUSH))
            
            if(instruction.instruction_type == Instruction_types.DATA and instruction.inst_fields.Rd == 15):   # Data Processing with write to PC
                current_index = self.result_list.index(instruction)
                previous_instruction = self.result_list[current_index-1]

                for i in range(self.dp2pc_stall_cycles):
                    self.result_list.insert(current_index+i,Result(instruction.Register_File,-1,-1,Instruction_types.STALLFLUSH))
            
            #If we have Load next instruction might cause 1 cycle stall
            if(instruction.instruction_type == Instruction_types.LDR):
                current_index = self.result_list.index(instruction)
                next_instruction = self.result_list[current_index+1]
                #Check Data instructions
                if(next_instruction.inst_fields.Op==0):
                    #If no immediate we check Rm
                    if((next_instruction.inst_fields.I==0) and (next_instruction.inst_fields.Rm == instruction.inst_fields.Rd)):
                        self.result_list.insert(current_index+1,Result(instruction.Register_File,next_instruction.PC,-1,Instruction_types.STALLFLUSH))
                    #If immediate we check only Rn (except for MOV)    
                    elif(next_instruction.inst_fields.cmd!=Constants.MOV and (next_instruction.inst_fields.Rn == instruction.inst_fields.Rd)):
                        self.result_list.insert(current_index+1,Result(instruction.Register_File,next_instruction.PC,-1,Instruction_types.STALLFLUSH))
                #For LOAD/STORE
                elif(next_instruction.inst_fields.Op==1):
                    #Rn is always used so first check that
                    if(next_instruction.inst_fields.Rn == instruction.inst_fields.Rd):
                        self.result_list.insert(current_index+1,Result(instruction.Register_File,next_instruction.PC,-1,Instruction_types.STALLFLUSH))
                    #Rd is used for store check that
                    elif(next_instruction.inst_fields.L==0 and next_instruction.inst_fields.cmd!=Constants.MOV and (next_instruction.inst_fields.Rd == instruction.inst_fields.Rd)):
                        self.result_list.insert(current_index+1,Result(instruction.Register_File,next_instruction.PC,-1,Instruction_types.STALLFLUSH))
        #Add padding to the start to accomodate the pipeline
        empty_list = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
        for i in range(4):
            self.result_list.append(Result(empty_list,-1,-1,Instruction_types.STALLFLUSH))
            for k in range(1,len(self.result_list)):
                self.result_list[-k].Register_File = self.result_list[-(k+1)].Register_File
        self.result_list[0].Register_File = empty_list
        self.result_list[1].Register_File = empty_list
        self.result_list[2].Register_File = empty_list
        self.result_list[3].Register_File = empty_list




    #A model of the verilog code to confirm operation, data is In_data
    def performance_model (self):
        #Read current instructions, extract and log the fields
        current_instruction = self.Instruction_list[int((self.PC)/4)]
        current_instruction = current_instruction.replace(" ", "")
        #We need to reverse the order of bytes since little endian makes the string reversed in Python
        current_instruction = reverse_hex_string_endiannes(current_instruction)
        #Initial R15 value for operations
        self.Register_File[15] = self.PC + 8  
        self.PC = self.PC + 4
        #Flag to check if the current instruction will be executed.
        execute_flag = False
        #Call Instruction calls to get each field from the instruction
        inst_fields = Instruction(current_instruction)
        match inst_fields.Cond:
            case Constants.AL:
                execute_flag=True
            case Constants.EQ:
                if(self.Z_flag == 1):
                    execute_flag = True
            case Constants.NE:
                if(self.Z_flag == 0):
                    execute_flag = True
        if(execute_flag):
            #binary_instr is just for BX check             
            binary_instr = format(int(current_instruction, 16), '032b')
            #Weird BX condition
            if(binary_instr[4:28]=="000100101111111111110001"):
                self.PC = self.Register_File[inst_fields.Rm]
                self.result_list.append(Result(self.Register_File.copy(),self.PC,inst_fields,Instruction_types.BRANCH))
            elif(inst_fields.Op==0):
                #Data Processing Case
                if(inst_fields.I==1):
                    datap_second_operand = rotate_right(inst_fields.imm8,inst_fields.rot*2)
                else:
                    datap_second_operand = shift_helper(self.Register_File[inst_fields.Rm],inst_fields.shamt5,inst_fields.sh) 
                match inst_fields.cmd:
                    case Constants.AND:
                        datap_result = self.Register_File[inst_fields.Rn] & datap_second_operand
                        self.write_to_register_file(inst_fields.Rd,datap_result)
                    case Constants.ORR:
                        datap_result = self.Register_File[inst_fields.Rn]  | datap_second_operand
                        self.write_to_register_file(inst_fields.Rd,datap_result)
                    case Constants.ADD:
                        datap_result = self.Register_File[inst_fields.Rn] + datap_second_operand
                        self.write_to_register_file(inst_fields.Rd,datap_result)
                    case Constants.SUB:
                        datap_result = self.Register_File[inst_fields.Rn]  - datap_second_operand
                        self.write_to_register_file(inst_fields.Rd,datap_result)
                    case Constants.MOV:
                        datap_result = datap_second_operand
                        self.write_to_register_file(inst_fields.Rd,datap_result)
                    case Constants.CMP:
                        datap_result = self.Register_File[inst_fields.Rn]  - datap_second_operand
                    case _:
                        self.logger.error("Not supported data processing instruction!!")
                        assert False 
                #Check S bit to set Z-flag, only CMP should have this
                if(inst_fields.S==1):
                    if(datap_result == 0):
                        self.Z_flag = 1
                    else:
                        self.Z_flag = 0
                self.result_list.append(Result(self.Register_File.copy(),self.PC,inst_fields,Instruction_types.DATA))
            #Memory Operations case        
            elif(inst_fields.Op == 1):
                if(inst_fields.L==1):
                    self.write_to_register_file(inst_fields.Rd,int.from_bytes(self.memory.read(self.Register_File[inst_fields.Rn] +inst_fields.imm12)))
                    self.result_list.append(Result(self.Register_File.copy(),self.PC,inst_fields ,Instruction_types.LDR))
                else:
                    self.memory.write(self.Register_File[inst_fields.Rn] + inst_fields.imm12,self.Register_File[inst_fields.Rd])
                    self.result_list.append(Result(self.Register_File.copy(),self.PC,inst_fields,Instruction_types.STR))
            #Branch case
            elif(inst_fields.Op == 2):
                if (inst_fields.L_branch):
                    self.Register_File[14]=self.PC
                #Only +4 since we already increment 4 at the start
                self.PC = self.PC + 4 + (inst_fields.imm24*4)
                self.result_list.append(Result(self.Register_File.copy(),self.PC,inst_fields,Instruction_types.BRANCH))
            else:
                self.logger.error("Invalid operation type of 3!!")
                assert False
        else:
            self.result_list.append(Result(self.Register_File.copy(),self.PC,inst_fields,Instruction_types.NOTEXECUTED))
            self.logger.debug("Current Instruction is not executed")

        #We change register file 15 (PC + 8) after increment and branches because we compare after the clock cycle
        self.Register_File[15] = self.PC + 8
    async def run_test(self):
        while(int(self.Instruction_list[int((self.PC)/4)].replace(" ", ""),16)!=0):
            #Call the performance model and save the results
            self.performance_model()
        print("Before Hazard")
        for item in self.result_list:
            item.print()
        print("After Hazard")    
        self.check_for_hazard()
        for item in self.result_list:
            item.print()
        for instruction_no in range(len(self.result_list)):
            current_result = self.result_list[instruction_no]
            self.logger.debug("**************** Clock cycle: %d **********************",self.clock_cycle_count)
            self.clock_cycle_count = self.clock_cycle_count+1
            if(self.result_list[instruction_no].instruction_type!=Instruction_types.STALLFLUSH):
                self.result_list[instruction_no].inst_fields.log(self.logger)
            else:
                self.logger.debug("Computer is stalled/flushed for this cycle")
            await RisingEdge(self.dut.clk)
            self.log_dut()
            await Timer(1, units='us')
            self.compare_result(current_result)
     
@cocotb.test()
async def Pipeline_test(dut):
    #Generate the clock
    await cocotb.start(Clock(dut.clk, 10, 'us').start(start_high=False))
    #Reset onces before continuing with the tests
    dut.reset.value=1
    await RisingEdge(dut.clk)
    dut.reset.value=0
    await FallingEdge(dut.clk)
    instruction_lines = read_file_to_list('Instructions.hex')
    #Give PC signal handle and Register File MODULE handle
    tb = TB(instruction_lines,dut, dut.fetchPC, dut.my_datapath.reg_file_dp, 4)
    await tb.run_test()
