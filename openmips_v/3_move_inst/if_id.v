`include "defines.v"
module if_id(
	input wire 					clk,
	input wire 					rst,

	//来自取指阶段的信号，其中宏定义InstBus表示指令宽度，为32
	input wire[`InstAddrBus]	if_pc,					//取指阶段取得的指令地址
	input wire[`InstBus]		if_inst,				//取指阶段取得的指令

	//对应译码阶段的信?
	output reg[`InstAddrBus]	id_pc,					//译码阶段的指令地址
	output reg[`InstBus]		id_inst 				//译码阶段的指令
	);

	always @(posedge clk ) begin
		if (rst == `RstEnable) begin
			id_pc <= `ZeroWord;							//复位的时候pc的值为0
			id_inst <= `ZeroWord;						//复位的时候指令也为0，即空指令
		end
		else begin
			id_pc <= if_pc;								//其余时间向下传递取指阶段的值
			id_inst <= if_inst;
		end
	end
endmodule