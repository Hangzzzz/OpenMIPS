`include "defines.v"

`timescale 1ns/1ps

module tb_ori();
	reg 			clk;
	reg 			rst;

	//每隔10ns，clk信号翻转一次，每个周期是20ns，对应50Mhz
	initial begin
		clk = 1'b0;
		forever #10 	clk = ~clk; 
	end
	//最初时刻，复位信号有效，在第195ns，复位信号无效，最小SOPC开始运行
	//运行1000ns后，停止仿真
	initial begin
		rst = `RstEnable;
		#195 rst = `RstDisable;
		#1000 $stop;
	end

	openmips_min_sopc openmips_min_sopc_0(
		.clk(clk),			.rst(rst)
		);
endmodule
