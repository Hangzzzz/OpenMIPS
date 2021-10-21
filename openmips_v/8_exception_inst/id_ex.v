`include "defines.v"
module id_ex(
	input wire 				clk,							
	input wire 				rst,							
	
	input wire[5:0] 		stall,
	//从译码阶段传递过来的信息						
	input wire[`AluOpBus]	id_aluop,						//译码阶段的指令 运算子类型
	input wire[`AluSelBus] 	id_alusel,						//译码阶段的指令 运算类型
	input wire[`RegBus] 	id_reg1,						//译码阶段的指令 源操作数1
	input wire[`RegBus]		id_reg2,						//译码阶段的指令 源操作数2
	input wire[`RegAddrBus]	id_wd,							//译码阶段的指令 要写入的目的寄存器的地址
	input wire 				id_wreg,						//译码阶段的指令 是否有要写入的目的寄存器
	
	input wire[`RegBus]		id_link_address,
	input wire 				id_is_in_delayslot,
	input wire 				next_inst_in_delayslot_i,
	
	input wire[`RegBus]		id_inst,
	output reg[`RegBus]		ex_inst,
	
	input wire 				flush,
	input wire[`RegBus] 	id_current_inst_address,
	input wire[31:0] 		id_excepttype,
	output reg[`RegBus] 	ex_current_inst_address,
	output reg[31:0] 		ex_excepttype,
	
	output reg[`RegBus]		ex_link_address,
	output reg 				ex_is_in_delayslot,
	output reg 				is_in_delayslot_o,
	//传递到执行阶段的信息
	output reg[`AluOpBus] 	ex_aluop,						//执行阶段的指令 运算子类型
	output reg[`AluSelBus]	ex_alusel,						//执行阶段的指令 运算类型
	output reg[`RegBus] 	ex_reg1,						//执行阶段的指令 源操作数1
	output reg[`RegBus]		ex_reg2,						//执行阶段的指令 源操作数2
	output reg[`RegAddrBus] ex_wd,							//执行阶段的指令 要写入的目的寄存器的地址
	output reg 				ex_wreg							//执行阶段的指令 是否有要写入的目的寄存器
	);
	always @(posedge clk) begin
		if (rst == `RstEnable) begin
			ex_aluop 	<= `EXE_NOP_OP;
			ex_alusel 	<= `EXE_RES_NOP;
			ex_reg1		<= `ZeroWord;
			ex_reg2		<= `ZeroWord;
			ex_wd 		<= `NOPRegAddr;
			ex_wreg 	<= `WriteDisable;
			ex_inst		<= `ZeroWord;
			
			ex_link_address		<= `ZeroWord;
			ex_is_in_delayslot	<= `NotInDelaySlot;
			is_in_delayslot_o	<= `NotInDelaySlot;
			
			ex_excepttype		<= `ZeroWord;
			ex_current_inst_address	<= `ZeroWord;
		end
		else if(flush == 1'b1) begin
			ex_aluop 	<= `EXE_NOP_OP;
			ex_alusel 	<= `EXE_RES_NOP;
			ex_reg1		<= `ZeroWord;
			ex_reg2		<= `ZeroWord;
			ex_wd 		<= `NOPRegAddr;
			ex_wreg 	<= `WriteDisable;
			ex_inst		<= `ZeroWord;
			
			ex_link_address		<= `ZeroWord;
			ex_is_in_delayslot	<= `NotInDelaySlot;
			is_in_delayslot_o	<= `NotInDelaySlot;
			
			ex_excepttype		<= `ZeroWord;
			ex_current_inst_address	<= `ZeroWord;
		end
		else if(stall[2] == `Stop && stall[3] == `NoStop) begin
			ex_aluop 	<= `EXE_NOP_OP;
			ex_alusel 	<= `EXE_RES_NOP;
			ex_reg1		<= `ZeroWord;
			ex_reg2		<= `ZeroWord;
			ex_wd 		<= `NOPRegAddr;
			ex_wreg 	<= `WriteDisable;
			ex_inst		<= `ZeroWord;
			
			ex_link_address		<= `ZeroWord;
			ex_is_in_delayslot	<= `NotInDelaySlot;
			is_in_delayslot_o	<= `NotInDelaySlot;
			
			ex_excepttype		<= `ZeroWord;
			ex_current_inst_address	<= `ZeroWord;
		end
		else if(stall[2] == `NoStop) begin
			ex_aluop 	<= id_aluop;
			ex_alusel 	<= id_alusel;
			ex_reg1		<= id_reg1;
			ex_reg2		<= id_reg2;
			ex_wd 		<= id_wd;
			ex_wreg 	<= id_wreg;
			
			ex_link_address		<= id_link_address;
			ex_is_in_delayslot	<= id_is_in_delayslot;
			is_in_delayslot_o	<= next_inst_in_delayslot_i;
			ex_inst		<= id_inst;
			
			ex_excepttype		<= id_excepttype;
			ex_current_inst_address	<= id_current_inst_address;
		end
	end
endmodule


