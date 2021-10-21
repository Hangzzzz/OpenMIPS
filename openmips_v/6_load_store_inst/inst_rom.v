//=================================ROM模块：指令存储器=========================================================================================================================
`include "defines.v"
module inst_rom(
	input wire 					ce,
	input wire[`InstAddrBus]	addr,
	output reg[`InstBus]		inst
	);
	//定义一个数组，大小是InstMemNum,元素宽度是InstBus
	reg[`InstBus] inst_mem[0:`InstMemNum-1];
	//使用文件inst_rom.data初始化指令存储器
	initial $readmemh ("G:/OpenMIPS/ori_inst/inst_rom.txt", inst_mem );
	//当复位信号无效时，依据输入的地址，给出指令存储器ROM中对应的元素
	always @(*) begin
		if (ce == `ChipDisable) begin
			inst = `ZeroWord;
		end
		else begin
			inst = inst_mem[addr[`InstMemNumLog2+1:2]];				//因为pc_reg中每个时钟周期，指令地址+4，所以这里要在除以4
		end
	end
endmodule