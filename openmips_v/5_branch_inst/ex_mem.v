`include "defines.v"
module ex_mem(
	input wire 				clk,
	input wire 				rst,
	
	input wire[5:0]			stall,
	input wire[`DoubleRegBus]	hilo_i,
	input wire[1:0]				cnt_i,
	//来自执行阶段的信息
	input wire[`RegAddrBus]	ex_wd,						//执行阶段之后 要写入的目的寄存器地址
	input wire 				ex_wreg,					//执行阶段之后 是否有要写入的目的寄存器
	input wire[`RegBus]		ex_wdata,					//执行阶段之后 要写入的目的寄存器的值
	
	input wire[`RegBus]		ex_hi,
	input wire[`RegBus]		ex_lo,
	input wire				ex_whilo,
	
	output reg[`DoubleRegBus]	hilo_o,
	output reg[1:0]				cnt_o,
	//送到访存阶段的信息					
	output reg[`RegAddrBus]	mem_wd,						//访存阶段的指令 要写入的目的寄存器地址
	output reg 				mem_wreg,					//访存阶段的指令 是否有要写入的目的寄存器
	output reg[`RegBus]		mem_wdata,					//访存阶段的指令 要写入的目的寄存器的值
	
	output reg[`RegBus]		mem_hi,
	output reg[`RegBus]		mem_lo,
	output reg 				mem_whilo
	);
	always @(posedge clk ) begin
		if (rst == `RstEnable) begin
			mem_wd 		<= `NOPRegAddr;
			mem_wreg	<= `WriteDisable;
			mem_wdata	<= `ZeroWord; 
			mem_hi		<= `ZeroWord;
			mem_lo		<= `ZeroWord;
			mem_whilo	<= `WriteDisable;
			hilo_o		<= {`ZeroWord,`ZeroWord};
			cnt_o		<= 2'b00;
		end
		else if(stall[3] == `Stop && stall[4] == `NoStop) begin
			mem_wd 		<= `NOPRegAddr;
			mem_wreg	<= `WriteDisable;
			mem_wdata	<= `ZeroWord; 
			mem_hi		<= `ZeroWord;
			mem_lo		<= `ZeroWord;
			mem_whilo	<= `WriteDisable;
			hilo_o 		<= hilo_i;
			cnt_o 		<= cnt_i;
		end
		else if(stall[3] == `NoStop) begin
			mem_wd 		<= ex_wd;
			mem_wreg	<= ex_wreg;
			mem_wdata 	<= ex_wdata;
			mem_hi		<= ex_hi;
			mem_lo		<= ex_lo;
			mem_whilo	<= ex_whilo;
			hilo_o		<= {`ZeroWord,`ZeroWord};
			cnt_o		<= 2'b00;
		end
		else begin
			hilo_o		<= hilo_i;
			cnt_o		<= cnt_i;
		end
	end
endmodule






