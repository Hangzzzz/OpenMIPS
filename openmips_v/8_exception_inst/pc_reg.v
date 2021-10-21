//=================================取指阶段================================================================================================================================
`include "defines.v"
module pc_reg(
	input wire				 clk,
	input wire				 rst,
	input wire[5:0]			 stall,						//来自控制模块CTRL
	input wire 				 branch_flag_i,				//是否发生转移
	input wire[`RegBus]		 branch_target_address_i,	//转移到的目标地址
	
	input wire 				 flush,
	input wire[`RegBus] 	 new_pc,
	
	output reg[`InstAddrBus] pc,						//要读取的指令地址
	output reg 				 ce 						//指令存储器使能信号
	);
	
	always @(posedge clk) begin
		if(rst == `RstEnable) 
			ce <= `ChipDisable;							//复位时指令存储器禁用
		else    										//复位结束后指令存储器使能
			ce <= `ChipEnable;
	end

	always @(posedge clk ) begin
		if (ce == `ChipDisable) begin
			pc <= 32'h00000000;							//指令存储器禁用时，pc的值为0
		end  										
		else begin
			if(flush == 1'b1) begin 					//输入信号flush为1表示异常发生,将从control模块给出的异常处理例程入口地址new_pc处取指执行
				pc 	<= new_pc; 
			end
			else if(stall[0] == `NoStop) begin
				if(branch_flag_i == `Branch) begin
					pc	<= 	branch_target_address_i;
				end
				else begin
					pc	<=	pc + 4'h4;								//指令存储器使能时，pc的值每时钟周期+4
				end
			end
		end
	end
endmodule