

//***********************************全局宏定义**********************************************
`define RstEnable                1'b1					//复位信号有效
`define RstDisable               1'b0					//复位信号无效
`define ZeroWord                 32'h00000000			//32位的数值为0
`define WriteEnable              1'b1					//使能写
`define WriteDisable         	 1'b0                   //禁止写
`define ReadEnable				 1'b1                   //使能读
`define ReadDisable  			 1'b0                   //禁止读
`define AluOpBus				 7:0                    //译码阶段的输出aluop_o的宽度
`define AluSelBus				 2:0                    //译码阶段的输出alusel_o的宽度
`define InstValid				 1'b0                   //指令有效
`define InstInvalid              1'b1                   //指令无效
`define True					 1'b1                   //逻辑“真”
`define False					 1'b0                   //逻辑“假”
`define ChipEnable				 1'b1                   //芯片使能
`define ChipDisable				 1'b0                   //芯片禁止

//***********************************与具体指令有关的宏定义************************************
`define EXE_ORI					 6'b001101 				//指令ori的指令码
`define EXE_NOP					 6'b000000

//AluOp
`define EXE_OR_OP				 8'b00100101
`define EXE_NOP_OP				 8'b00000000

//AluSel
`define EXE_RES_LOGIC			 3'b001
`define EXE_RES_NOP				 3'b000

//***********************************与指令存储器ROM有关的宏定义********************************
`define InstAddrBus				 31:0					//ROM的地址总线宽度
`define InstBus					 31:0					//ROM的数据总线线宽度
`define InstMemNum				 131071					//ROM的实际大小为128KB
`define InstMemNumLog2			 17						//ROM的实际使用的地址线宽度

//***********************************与通用寄存器Regfile有关的宏定义****************************
`define RegAddrBus				 4:0					//Regfile模块的地址线宽度
`define RegBus					 31:0                   //Regfile模块的数据线宽度
`define RegWidth				 32                     //通用寄存器的宽度
`define DoubleRegWidth			 64                     //两倍的通用寄存器的宽度
`define DoubleRegBus			 63:0                   //两倍的通用寄存器的数据线宽度
`define RegNum					 32                     //通用寄存器的数量
`define RegNumLog2				 5                      //寻址通用寄存器使用的地址位数
`define NOPRegAddr				 5'b00000

//=================================取指阶段================================================================================================================================
module pc_reg(
	input wire				 clk,
	input wire				 rst,
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
			pc <=pc + 4'h4;								//指令存储器使能时，pc的值每时钟周期+4
		end
	end
endmodule

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

//=================================译码阶段================================================================================================================================
module regfile(
	input wire 					clk,
	input wire 					rst,

	//写端口
	input wire 					we,						//写使能信号
	input wire[`RegAddrBus]		waddr,					//要写入的寄存器地址
	input wire[`RegBus]			wdata,					//要写入的数据
	//读端口1
	input wire 					re1,					//第一个读寄存器端口读使能信号
	input wire[`RegAddrBus]		raddr1,					//第一个读寄存器端口读取的寄存器地址
	output reg[`RegBus]			rdata1,					//第一个读寄存器端口输出的寄存器值
	//读端口2
	input wire 					re2,
	input wire[`RegAddrBus]		raddr2,
	output reg[`RegBus]			rdata2
	);
	/*******************************第一段：定义32个32位寄存器******************************************/
	reg[`RegBus] regs[0:`RegNum-1];

	/*******************************第二段：写操作*****************************************************/
	always @(posedge clk ) begin
		if (rst == `RstDisable) begin
			if((we == `WriteEnable)&&(waddr != `RegNumLog2'h0))
				regs[waddr] <= wdata;
		end
	end
	/*******************************第三段：读端口1的读操作*********************************************/
	always @(*) begin
		if (rst == `RstEnable) begin
			rdata1 = `ZeroWord;
		end
		else if (raddr1 == `RegNumLog2'h0) begin
			rdata1 = `ZeroWord;
		end
		else if((raddr1 == waddr)&&(we == `WriteEnable)&&(re1 == `ReadEnable)) begin
			rdata1 = wdata;
		end
		else if(re1 == `ReadEnable) begin
			rdata1 = regs[raddr1];
		end
		else begin
			rdata1 = `ZeroWord;
		end
	end
	/*******************************第四段：读端口2的读操作*********************************************/
	always @(*) begin
		if (rst == `RstEnable) begin
			rdata2 = `ZeroWord;
		end
		else if (raddr1 == `RegNumLog2'h0) begin
			rdata2 = `ZeroWord;
		end
		else if((raddr2 == waddr)&&(we == `WriteEnable)&&(re2 == `ReadEnable)) begin
			rdata2 = wdata;
		end
		else if(re2 == `ReadEnable) begin
			rdata2 = regs[raddr2];
		end
		else begin
			rdata1 = `ZeroWord;
		end
	end
endmodule

module  id(
	input wire 					rst,
	input wire[`InstAddrBus]	pc_i, 							//译码阶段的指令对应的地址
	input wire[`InstBus]		inst_i,							//译码阶段的指令

	//读取的Regfile的??
	input wire[`RegBus]			reg1_data_i, 					//从Regfile输入的第一个读寄存器端口的输入
	input wire[`RegBus]			reg2_data_i,					//从Regfile输入的第二个读寄存器端口的输入

	//输出到Regfile的信?
	output reg 					reg1_read_o,					//Regfile模块的第一个读寄存器端口的读使能信号
	output reg 					reg2_read_o,					//Regfile模块的第二个读寄存器端口的读使能信号
	output reg[`RegAddrBus]		reg1_addr_o,					//Regfile模块的第一个读寄存器端口的读地址信号
	output reg[`RegAddrBus]		reg2_addr_o,					//Regfile模块的第二个读寄存器端口的读地址信号

	//送到执行阶段的信?
	output reg[`AluOpBus]		aluop_o,						//译码阶段的指令要进行的运算的子类型 	
	output reg[`AluSelBus]		alusel_o,						//译码阶段的指令要进行的运算的类型
	output reg[`RegBus]			reg1_o,							//译码阶段的指令要进行的运算的源操作数1
	output reg[`RegBus]			reg2_o,							//译码阶段的指令要进行的运算的源操作数2
	output reg[`RegAddrBus]		wd_o,							//译码阶段的指令要写入的目的寄存器地址
	output reg 					wreg_o							//译码阶段的指令是否有要写入的目的寄存器
	);
	//取得指令的指令码，功能码
	//对于ori指令只需要通过判断第26-31bit的值，即可判断是否是ori指令
	wire[5:0] op = inst_i[31:26];
	wire[4:0] op2 = inst_i[10:6];
	wire[5:0] op3 = inst_i[5:0];
	wire[4:0] op4 = inst_i[20:16];
	//保存指令执行?要的立即?
	reg[`RegBus]	imm;
	//指示指令是否有效
	reg 			instvalid;
	/*********************************第一段：对指令进行译码**************************************/
	always @(*) begin
		if (rst == `RstEnable) begin
			aluop_o		= `EXE_NOP_OP;
			alusel_o 	= `EXE_RES_NOP;
			wd_o 		= `NOPRegAddr;
			wreg_o 		= `WriteDisable;
			instvalid 	= `InstValid;
			reg1_read_o	= 1'b0;
			reg2_read_o	= 1'b0;
			reg1_addr_o	= `NOPRegAddr;
			reg2_addr_o	= `NOPRegAddr;
			imm 		= 32'h0;
		end
		else begin
			aluop_o		= `EXE_NOP_OP;
			alusel_o 	= `EXE_RES_NOP;
			wd_o 		=  inst_i[15:11];
			wreg_o 		= `WriteDisable;
			instvalid 	= `InstInvalid;
			reg1_read_o	= 1'b0;
			reg2_read_o	= 1'b0;
			reg1_addr_o	=  inst_i[25:21];					//默认通过Regfile读端口1读取的寄存器地址
			reg2_addr_o	=  inst_i[20:16];					//默认通过Regfile读端口2读取的寄存器地址
			imm 		= `ZeroWord;

			case (op)
				`EXE_ORI:		begin
					//ori指令将要将结果写入目的寄存器，所以wreg_o为WriteEnable
					wreg_o 		= `WriteEnable;
					//运算的子类型是逻辑“或”运算
					aluop_o		= `EXE_OR_OP;
					//运算类型是逻辑运算
					alusel_o	= `EXE_RES_LOGIC;
					//需要通过Regfile的读端口1读取寄存器
					reg1_read_o	= 1'b1;
					//不需要通过Regfile的读端口2读取寄存器
					reg2_read_o	= 1'b0;
					//指令执行需要的立即数
					imm 		= {16'h0,inst_i[15:0]};
					//指令执行要写的目的寄存器地址
					wd_o 		= inst_i[20:16];
					//ori指令是有效指令
					instvalid 	= `InstValid;
				end
				default: 		begin
				end
			endcase
		end
	end

	/************************************第二段：确定进行运算的源操作数1*********************************/
	always @(*) begin
		if (rst == `RstEnable) begin
			reg1_o 	= `ZeroWord;
		end
		else if(reg1_read_o == 1'b1) begin
			reg1_o 	= reg1_data_i; 						//Regfile读端口1的输出值
		end
		else if(reg1_read_o == 1'b0) begin
			reg1_o 	= imm; 								//立即数
		end
		else begin
			reg1_o 	= `ZeroWord;
		end
	end
	/************************************第三段：确定进行运算的源操作数2*********************************/
	always @(*) begin
		if (rst == `RstEnable) begin
			reg1_o 	= `ZeroWord;
		end
		else if(reg2_read_o == 1'b1) begin
			reg2_o 	= reg2_data_i; 						//Regfile读端口2的输出值
		end
		else if(reg2_read_o == 1'b0) begin
			reg2_o 	= imm; 								//立即数
		end
		else begin
			reg2_o 	= `ZeroWord;
		end
	end
endmodule
	
module id_ex(
	input wire 				clk,							
	input wire 				rst,							
	//从译码阶段传递过来的信息						
	input wire[`AluOpBus]	id_aluop,						//译码阶段的指令 运算子类型
	input wire[`AluSelBus] 	id_alusel,						//译码阶段的指令 运算类型
	input wire[`RegBus] 	id_reg1,						//译码阶段的指令 源操作数1
	input wire[`RegBus]		id_reg2,						//译码阶段的指令 源操作数2
	input wire[`RegAddrBus]	id_wd,							//译码阶段的指令 要写入的目的寄存器的地址
	input wire 				id_wreg,						//译码阶段的指令 是否有要写入的目的寄存器
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
		end
		else  begin
			ex_aluop 	<= id_aluop;
			ex_alusel 	<= id_alusel;
			ex_reg1		<= id_reg1;
			ex_reg2		<= id_reg2;
			ex_wd 		<= id_wd;
			ex_wreg 	<= id_wreg;
		end
	end
endmodule

//=================================执行阶段=================================================================================================================================
module ex(
	input wire 				rst,
	//译码阶段送到执行阶段的信息
	input wire[`AluOpBus]	aluop_i,
	input wire[`AluSelBus]	alusel_i,
	input wire[`RegBus]		reg1_i,
	input wire[`RegBus]		reg2_i,
	input wire[`RegAddrBus]	wd_i,
	input wire 				wreg_i,
	//执行的结果
	output reg[`RegAddrBus] wd_o,
	output reg 				wreg_o,
	output reg[`RegBus] 	wdata_o
	);
	//保存逻辑运算结果
	reg[`RegBus] 			logicout;

	/*********************第一段：依据aluop_i指示的运算子类型进行运算，此处只有逻辑“或”运算**********************/
	always @(*) begin
		if (rst == `RstEnable) begin
			logicout = `ZeroWord;
		end
		else begin
			case (aluop_i)
				`EXE_OR_OP: begin
					logicout = reg1_i|reg2_i;
				end
				default: begin
					logicout = `ZeroWord;
				end
			endcase
		end
	end
	/*********************第二段：依据alusel_i指示的运算类型，选择这个运算结果作为最终结果，此处只有逻辑运算结果*****/
	always @(*) begin
		wd_o = wd_i;									//要写入的目的寄存器的地址
		wreg_o = wreg_i;								//表示是否要写目的寄存器
		case (alusel_i)
			`EXE_RES_LOGIC: begin
				wdata_o = logicout; 					//wdata_o中存放运算结果			
			end
			default: begin
				wdata_o = `ZeroWord;
			end
		endcase
	end
endmodule

module ex_mem(
	input wire 				clk,
	input wire 				rst,
	//来自执行阶段的信?
	input wire[`RegAddrBus]	ex_wd,						//执行阶段之后 要写入的目的寄存器地址
	input wire 				ex_wreg,					//执行阶段之后 是否有要写入的目的寄存器
	input wire[`RegBus]		ex_wdata,					//执行阶段之后 要写入的目的寄存器的值
	//送到访存阶段的信?					
	output reg[`RegAddrBus]	mem_wd,						//访存阶段的指令 要写入的目的寄存器地址
	output reg 				mem_wreg,					//访存阶段的指令 是否有要写入的目的寄存器
	output reg[`RegBus]		mem_wdata					//访存阶段的指令 要写入的目的寄存器的值
	);
	always @(posedge clk ) begin
		if (rst == `RstEnable) begin
			mem_wd 		<= `NOPRegAddr;
			mem_wreg	<= `WriteDisable;
			mem_wdata	<= `ZeroWord; 
		end
		else begin
			mem_wd 		<= ex_wd;
			mem_wreg	<= ex_wreg;
			mem_wdata 	<= ex_wdata;
		end
	end
endmodule

//=================================访存阶段==================================================================================================================================
module mem(
	input wire 				rst,
	//来自执行阶段的信息
	input wire[`RegAddrBus]	wd_i,						//访存阶段的指令 要写入的目的寄存器地址
	input wire 				wreg_i,						//访存阶段的指令 是否有要写入的目的寄存器
	input wire[`RegBus]		wdata_i,					//访存阶段的指令 要写入的目的寄存器的值
	//访存阶段的结果
	output reg[`RegAddrBus]	wd_o,						//访存阶段的指令 最终 要写入的目的寄存器地址
	output reg 				wreg_o,						//访存阶段的指令 最终 是否有要写入的目的寄存器
	output reg[`RegBus]		wdata_o						//访存阶段的指令 最终 要写入的目的寄存器的值
	;
	always @(*) begin
		if (rst == `RstEnable) begin
			wd_o = `NOPRegAddr;
			wreg_o = `WriteDisable;
			wdata_o = `ZeroWord;
		end
		else begin
			wd_o = wd_i;
			wreg_o = wreg_i;
			wdata_o = wdata_i;
		end
	end
endmodule

module mem_wb(
	input wire 				clk,
	input wire 				rst,
	//访存阶段的结果
	input wire[`RegAddrBus]	mem_wd,						//访存阶段的指令 最终 要写入的目的寄存器地址
	input wire 				mem_wreg,					//访存阶段的指令 最终 是否有要写入的目的寄存器
	input wire[`RegBus] 	mem_wdata,					//访存阶段的指令 最终 要写入的目的寄存器的值
	//送到回写阶段的信息
	output reg[`RegAddrBus]	wb_wd,						//回写阶段的指令  要写入的目的寄存器地址
	output reg 				wb_wreg,					//回写阶段的指令  是否有要写入的目的寄存器
	output reg[`RegBus]		wb_wdata					//回写阶段的指令  要写入的目的寄存器的值
	);

	always @(posedge clk) begin
		if (rst == `RstEnable) begin
			wb_wd 		<= `NOPRegAddr;
			wb_wreg 	<= `WriteDisable;
			wb_wdata	<= `ZeroWord;
		end
		else begin
			wb_wd 		<= mem_wd;
			wb_wreg 	<= mem_wreg;
			wb_wdata	<= mem_wdata;
		end
	end
endmodule

//=================================回写阶段===================================================================================================================================
/**********将mem_wb模块的输出wb_wd、wb_wreg、wb_wdata连接到Regfile模块的we、waddr、wdata端口，将运算结果写入目的寄存器*****************/



//=================================顶层模块：OpenMIPS的实现====================================================================================================================
module openmips(
	input wire 					clk,
	input wire 					rst,

	input wire[`RegBus] 		rom_data_i,  			//从指令存储器取得的指令
	output wire[`RegBus] 		rom_addr_o, 			//输出到指令存储器的地址
	output wire 				rom_ce_o 				//指令存储器使能信号
	);
	
	//连接IF/ID模块与译码阶段ID模块的变量
	wire[`InstAddrBus] 			pc;
	wire[`InstAddrBus] 			id_pc_i;
	wire[`InstBus] 				id_inst_i;

	//连接译码阶段ID模块输出与ID/EX模块的输入的变量
	wire[`AluOpBus] 			id_aluop_o;
	wire[`AluSelBus]			id_alusel_o;
	wire[`RegBus]				id_reg1_o;
	wire[`RegBus]				id_reg2_o;
	wire 						id_wreg_o;
	wire[`RegAddrBus] 			id_wd_o;

	//连接ID/EX模块输出与执行阶段EX模块的输入的变量
	wire[`AluOpBus] 			ex_aluop_i;
	wire[`AluSelBus]			ex_alusel_i;
	wire[`RegBus]				ex_reg1_i;
	wire[`RegBus]				ex_reg2_i;
	wire 						ex_wreg_i;
	wire[`RegAddrBus]			ex_wd_i;

	//连接执行阶段EX模块的输出与EX/MEM模块的输入的变量
	wire 						ex_wreg_o;
	wire[`RegAddrBus] 			ex_wd_o;
	wire[`RegBus] 				ex_wdata_o;

	//连接EX/MEM模块的输出与访存阶段MEM模块的输入的变量
	wire 						mem_wreg_i;
	wire[`RegAddrBus] 			mem_wd_i;
	wire[`RegBus] 				mem_wdata_i;

	//连接访存阶段MEM模块的输出与MEM/WB模块的输入的变量
	wire 						mem_wreg_o;
	wire[`RegAddrBus] 			mem_wd_o;
	wire[`RegBus] 				mem_wdata_o;

	//连接MEM/WB模块的输出与回写阶段的输入的变量
	wire 						wb_wreg_i;
	wire[`RegAddrBus] 			wb_wd_i;
	wire[`RegBus] 				wb_wdata_i;

	//连接译码阶段ID模块与??用寄存器Regfile模块的变量
	wire 						reg1_read;
	wire 						reg2_read;
	wire[`RegBus] 				reg1_data;
	wire[`RegBus] 				reg2_data;
	wire[`RegAddrBus] 			reg1_addr;
	wire[`RegAddrBus] 			reg2_addr;

	//pc_reg例化
	pc_reg pc_reg_0(
		.clk(clk),	.rst(rst),	.pc(pc),	
		.ce(rom_ce_o)
	);

	assign rom_addr_o = pc; 			//指令存储器的输入地址就是pc的值

	//IF/ID模块例化
	if_id if_id_0(
		.clk(clk),	.rst(rst),	.if_pc(pc),	
		.if_inst(rom_data_i),	.id_pc(id_pc_i),
		.id_inst(id_inst_i)
		);
	//译码阶段ID模块的例化
	id id_0(
		.rst(rst),	.pc_i(id_pc_i),	.inst_i(id_inst_i),
		//来自Regfile模块的输出
		.reg1_data_i(reg1_data),	.reg2_data_i(reg2_data),
		//送到Regfile模块的信号
		.reg1_read_o(reg1_read),	.reg2_read_o(reg2_read),
		.reg1_addr_o(reg1_addr),	.reg2_addr_o(reg2_addr),
		//送到ID/EX模块的信号
		.aluop_o(id_aluop_o),		.alusel_o(id_alusel_o),
		.reg1_o(id_reg1_o),			.reg2_o(id_reg2_o),
		.wd_o(id_wd_o),				.wreg_o(id_wreg_o)
		);
	//通用寄存器Regfile模块例化
	regfile regfile_0(
		.clk(clk),				.rst(rst),
		.we(wb_wreg_i),			.waddr(wb_wd_i),
		.wdata(wb_wdata_i),		.re1(reg1_read),
		.raddr1(reg1_addr),		.rdata1(reg1_data),	.re2(reg2_read),	
		.raddr2(reg2_addr),		.rdata2(reg2_data)
		);
	//ID/EX模块例化
	id_ex id_ex_0(
		.clk(clk),				.rst(rst),
		//从译码阶段ID模块传来的信号
		.id_aluop(id_aluop_o),	.id_alusel(id_alusel_o),
		.id_reg1(id_reg1_o),	.id_reg2(id_reg2_o),
		.id_wd(id_wd_o),		.id_wreg(id_wreg_o),
		//传??到执行阶段EX模块的信号
		.ex_aluop(ex_aluop_i),	.ex_alusel(ex_alusel_i),
		.ex_reg1(ex_reg1_i),	.ex_reg2(ex_reg2_i),
		.ex_wd(ex_wd_i),		.ex_wreg(ex_wreg_i)
		);
	//EX模块例化
	ex ex_0(
		.rst(rst),
		//从ID/EX模块传递过来的信息
		.aluop_i(ex_aluop_i),	.alusel_i(ex_alusel_i),
		.reg1_i(ex_reg1_i),		.reg2_i(ex_reg2_i),
		.wd_i(ex_wd_i),			.wreg_i(ex_wreg_i),
		//输出到EX/MEM模块的信息
		.wd_o(ex_wd_o),			.wreg_o(ex_wreg_o),
		.wdata_o(ex_wdata_o)
		);
	//EX/MEM模块例化
	ex_mem ex_mem_0(
		.clk(clk),				.rst(rst),
		//来自执行阶段EX模块的信息
		.ex_wd(ex_wd_o),		.ex_wreg(ex_wreg_o),
		.ex_wdata(ex_wdata_o),
		//送到访存阶段MEM模块的信息
		.mem_wd(mem_wd_i),		.mem_wreg(mem_wreg_i),
		.mem_wdata(mem_wdata_i)
		);
	//MEM模块的例化
	mem mem_0(
		.rst(rst),
		//来自EX/MEM模块的信息
		.wd_i(mem_wd_i),		.wreg_i(mem_wreg_i),
		.wdata_i(mem_wdata_i),
		//送到MEM/WB模块的信息
		.wd_o(mem_wd_o),		.wreg_o(mem_wreg_o),
		.wdata_o(mem_wdata_o)
		);
	//MEM/WB模块例化
	mem_wb mem_wb_0(
		.clk(clk),				.rst(rst),
		//来自访存阶段MEM模块的信息
		.mem_wd(mem_wd_o),		.mem_wreg(mem_wreg_o),
		.mem_wdata(mem_wdata_o),
		//送到回写阶段的信息
		.wb_wd(wb_wd_i),		.wb_wreg(wb_wreg_i),
		.wb_wdata(wb_wdata_i)
		);
endmodule


//=================================ROM模块：指令存储器=========================================================================================================================
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


//=================================顶层模块：最小SOPC的实现====================================================================================================================
module openmips_min_sopc(
	input wire 				clk,
	input wire 				rst
	);
	//连接指令存储?
	wire[`InstAddrBus]		inst_addr;
	wire[`InstBus]			inst;
	wire 					rom_ce;
	//例化处理器OpenMIPS
	openmips openmips_0(
		.clk(clk),				.rst(rst),
		.rom_addr_o(inst_addr),	.rom_data_i(inst),
		.rom_ce_o(rom_ce)
		);
	//例化指令存储器ROM
	inst_rom inst_rom_0(
		.ce(rom_ce),			.addr(inst_addr),		.inst(inst)
		);
endmodule