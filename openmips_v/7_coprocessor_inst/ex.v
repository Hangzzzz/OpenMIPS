//=================================执行阶段=================================================================================================================================
`include "defines.v"
module ex(
	input wire 				rst,
	//译码阶段送到执行阶段的信息
	input wire[`AluOpBus]	aluop_i,
	input wire[`AluSelBus]	alusel_i,
	input wire[`RegBus]		reg1_i,
	input wire[`RegBus]		reg2_i,
	input wire[`RegAddrBus]	wd_i,
	input wire 				wreg_i,
	//HILO模块给出的HL\LO寄存器的值
	input wire[`RegBus]		hi_i,
	input wire[`RegBus]		lo_i,
	//回写阶段给出的HL\LO寄存器的值
	input wire[`RegBus]		wb_hi_i,
	input wire[`RegBus]		wb_lo_i,
	input wire 				wb_whilo_i,
	//访存阶段给出的HL\LO寄存器的值
	input wire[`RegBus]		mem_hi_i,
	input wire[`RegBus]		mem_lo_i,
	input wire 				mem_whilo_i,
	
	input wire[`DoubleRegBus]	hilo_temp_i,		//乘累加计算结果
	input wire[1:0]				cnt_i,				//周期计数器
	
	input wire[`RegBus]			link_address_i,		//处于执行阶段的转移指令要保存的返回地址
	input wire 					is_in_delayslot_i,	//当前执行阶段的指令是否位于延迟槽
	
	input wire[`RegBus]			inst_i,
	output wire[`AluOpBus]		aluop_o,
	output wire[`RegBus]		mem_addr_o,
	output wire[`RegBus]		reg2_o,
	
	//除法模块的信号线
	input wire[`DoubleRegBus]	div_result_i,
	input wire 					div_ready_i,
	output reg[`RegBus] 		div_opdata1_o,
	output reg[`RegBus]			div_opdata2_o,
	output reg 					div_start_o,
	output reg 					signed_div_o,
	
	output reg[`DoubleRegBus]	hilo_temp_o,
	output reg[1:0]				cnt_o,
	output reg 					stallreq,
	//执行阶段的指令对 HL\LO寄存器的写操作
	output reg[`RegBus]		hi_o,
	output reg[`RegBus]		lo_o,
	output reg 				whilo_o,
	//执行的结果
	output reg[`RegAddrBus] wd_o,
	output reg 				wreg_o,
	output reg[`RegBus] 	wdata_o,
	
	
	//访存阶段的指令是否要写CP0中的寄存器,用来检测数据相关
	input wire 				mem_cp0_reg_we,
	input wire[4:0]			mem_cp0_reg_write_addr,
	input wire[`RegBus]		mem_cp0_reg_data,
	//回写阶段的指令是否要写CP0中的寄存器,用来检测数据相关
	input wire 				wb_cp0_reg_we,
	input wire[4:0] 		wb_cp0_reg_write_addr,
	input wire[`RegBus]		wb_cp0_reg_data,
	//与CP0直接相连,用于读取指定寄存器的值
	input wire[`RegBus]		cp0_reg_data_i,
	output reg[4:0]			cp0_reg_read_addr_o,
	//向流水线下一级传递,用于写CP0中的指定寄存器
	output reg 				cp0_reg_we_o,
	output reg[4:0]			cp0_reg_write_addr_o,
	output reg[`RegBus] 	cp0_reg_data_o
	);

	reg[`RegBus] 			logicout;		//保存逻辑运算结果
	reg[`RegBus]			shiftres;		//保存移位运算结果
	
	reg[`RegBus]			moveres;		//移动操作的结果
	reg[`RegBus]			HI;				//HI寄存器的最新值
	reg[`RegBus]			LO;				//LO寄存器的最新值
	
	wire 					ov_sum;			//保存溢出情况
	wire 					reg1_eq_reg2;	//是否相等
	wire 					reg1_lt_reg2;	//是否小于
	reg[`RegBus]			arithmeticres;	//保存算术运算的结果
	wire[`RegBus]			reg2_i_mux;		//第二个操作数的补码
	wire[`RegBus]			reg1_i_not;		//第一个操作数的反码
	wire[`RegBus]			result_sum;		//保存加法的结果
	wire[`RegBus]			opdata1_mult;	//乘法中的被乘数
	wire[`RegBus]			opdata2_mult;	//乘法中的乘数
	wire[`DoubleRegBus]		hilo_temp;		//临时保存乘法结果,64位
	reg[`DoubleRegBus]		mulres;			//保存乘法结果,64位
	
	reg[`DoubleRegBus]  	hilo_temp1;
	reg 					stallreq_for_madd_msub;
	reg 					stallreq_for_div;
	
	assign aluop_o = aluop_i;
	//加载\存储的地址=base寄存器的值+offset有符号扩展
	assign mem_addr_o = reg1_i + {{16{inst_i[15]}},inst_i[15:0]};
	assign reg2_o = reg2_i;					//寄存器rd的值
	
	//assign stallreq = `NoStop;
	
	assign reg2_i_mux = ((aluop_i == `EXE_SUB_OP) ||
						 (aluop_i == `EXE_SUBU_OP)||
						 (aluop_i == `EXE_SLT_OP)) ?
						 (~reg2_i)+1 : reg2_i;
			
	assign result_sum = reg1_i + reg2_i_mux;
	//判断是否溢出:	reg1_i和reg2_i_mux为正数,但是和为负数
	//				reg1_i和reg2_i_mux为负数,但是和为正数				
	assign ov_sum	  = ((!reg1_i[31]&& !reg2_i_mux[31])&&result_sum[31]) 
						|| ((reg1_i[31] && reg2_i_mux[31])&&(!result_sum[31])); 
	
	assign reg1_lt_reg2 = (aluop_i == `EXE_SLT_OP)?
						  ((reg1_i[31] && !reg2_i[31]) || (!reg1_i[31] && !reg2_i[31] && result_sum[31]) || (reg1_i[31] && reg2_i[31] && result_sum[31]))
						  : (reg1_i < reg2_i);
	assign reg1_i_not = ~reg1_i;
	//进行逻辑运算
	always @(*) begin
		if (rst == `RstEnable) begin
			logicout = `ZeroWord;
		end
		else begin
			case (aluop_i)
				`EXE_OR_OP: begin
					logicout = reg1_i | reg2_i;
				end
				`EXE_AND_OP: begin
					logicout = reg1_i & reg2_i;
				end
				`EXE_NOR_OP: begin
					logicout = ~(reg1_i | reg2_i);
				end
				`EXE_XOR_OP: begin
					logicout = reg1_i ^ reg2_i;
				end
				default: begin
					logicout = `ZeroWord;
				end
			endcase
		end
	end
	//进行移位运算
	always @(*) begin
		if(rst == `RstEnable) begin
			shiftres = `ZeroWord;
		end
		else begin
			case(aluop_i)
				`EXE_SLL_OP:	begin
					shiftres = reg2_i << reg1_i[4:0];
				end
				`EXE_SRL_OP:	begin
					shiftres = reg2_i >> reg1_i[4:0];
				end
				`EXE_SRA_OP:	begin
					shiftres = ({32{reg2_i[31]}} << (6'd32-{1'b0,reg1_i[4:0]})) | reg2_i >> reg1_i[4:0];
				end
				default:	begin
					shiftres = `ZeroWord;
				end
			endcase
		end
	end
	
	//进行移动运算
	always @(*) begin
		if(rst == `RstEnable) begin
			{HI,LO} = {`ZeroWord,`ZeroWord};
		end
		else if(mem_whilo_i == `WriteEnable) begin
			{HI,LO} = {mem_hi_i,mem_lo_i};
		end
		else if(wb_whilo_i == `WriteEnable) begin
			{HI,LO} = {wb_hi_i,wb_lo_i};
		end
		else begin
			{HI,LO} = {hi_i,lo_i};
		end
	end
	
	always @(*) begin
		if(rst == `RstEnable) begin
			moveres = `ZeroWord;
		end
		else begin
			moveres = `ZeroWord;
			case(aluop_i)
				`EXE_MFHI_OP:	begin
					moveres = HI;
				end
				`EXE_MFLO_OP:	begin
					moveres = LO;
				end
				`EXE_MOVZ_OP:	begin
					moveres = reg1_i;
				end
				`EXE_MOVN_OP:	begin
					moveres = reg1_i;
				end
				`EXE_MFC0_OP:	begin
					cp0_reg_read_addr_o	= inst_i[15:11];
					moveres				= cp0_reg_data_i;
					if(mem_cp0_reg_we == `WriteEnable && mem_cp0_reg_write_addr == inst_i[15:11]) begin 			//与访存阶段存在数据相关
						moveres	= mem_cp0_reg_data;
					end
					else if(wb_cp0_reg_we == `WriteEnable && wb_cp0_reg_write_addr == inst_i[15:11]) begin 			//与回写阶段存在数据相关
						moveres = wb_cp0_reg_data;
					end
				end
				default:	begin
				end
			endcase
		end
	end
	
	//进行算术运算
	always @(*) begin
		if(rst == `RstEnable) begin
			arithmeticres = `ZeroWord;
		end
		else begin
			case(aluop_i)
				`EXE_SLT_OP, `EXE_SLTU_OP: begin
					arithmeticres = reg1_lt_reg2;		//比较运算
				end
				`EXE_ADD_OP, `EXE_ADDU_OP, `EXE_ADDI_OP, `EXE_ADDIU_OP: begin
					arithmeticres = result_sum;			//加法运算
				end
				`EXE_SUB_OP, `EXE_SUBU_OP: begin
					arithmeticres = result_sum;			//减法运算
				end
				`EXE_CLZ_OP: begin
					arithmeticres = reg1_i[31]? 0 :  reg1_i[30] ? 1:
									reg1_i[29]? 2 :  reg1_i[28] ? 3:
									reg1_i[27]? 4 :  reg1_i[26] ? 5:
									reg1_i[25]? 6 :  reg1_i[24] ? 7:
									reg1_i[23]? 8 :  reg1_i[22] ? 9:
									reg1_i[21]? 10 : reg1_i[20] ? 11:
									reg1_i[19]? 12:  reg1_i[18] ? 13:
									reg1_i[17]? 14:  reg1_i[16] ? 15:
									reg1_i[15]? 16:  reg1_i[14] ? 17:
									reg1_i[13]? 18:  reg1_i[12] ? 19:
									reg1_i[11]? 20:  reg1_i[10] ? 21:
									reg1_i[9]? 22:   reg1_i[8] ? 23:
									reg1_i[7]? 24:   reg1_i[6] ? 25:
									reg1_i[5]? 26:   reg1_i[4] ? 27:
									reg1_i[3]? 28:   reg1_i[2] ? 29:
									reg1_i[1]? 30:   reg1_i[0] ? 31:32;
				end
				`EXE_CLO_OP: begin
					arithmeticres = reg1_i_not[31]? 0 :  reg1_i_not[30] ? 1:
									reg1_i_not[29]? 2 :  reg1_i_not[28] ? 3:
									reg1_i_not[27]? 4 :  reg1_i_not[26] ? 5:
									reg1_i_not[25]? 6 :  reg1_i_not[24] ? 7:
									reg1_i_not[23]? 8 :  reg1_i_not[22] ? 9:
									reg1_i_not[21]? 10 : reg1_i_not[20] ? 11:
									reg1_i_not[19]? 12:  reg1_i_not[18] ? 13:
									reg1_i_not[17]? 14:  reg1_i_not[16] ? 15:
									reg1_i_not[15]? 16:  reg1_i_not[14] ? 17:
									reg1_i_not[13]? 18:  reg1_i_not[12] ? 19:
									reg1_i_not[11]? 20:  reg1_i_not[10] ? 21:
									reg1_i_not[9]? 22:   reg1_i_not[8] ? 23:
									reg1_i_not[7]? 24:   reg1_i_not[6] ? 25:
									reg1_i_not[5]? 26:   reg1_i_not[4] ? 27:
									reg1_i_not[3]? 28:   reg1_i_not[2] ? 29:
									reg1_i_not[1]? 30:   reg1_i_not[0] ? 31:32;
				end
				default:	begin
				end
			endcase
		end
	end
	//第一段: 进行乘法运算
	assign opdata1_mult = (((aluop_i == `EXE_MUL_OP)||(aluop_i == `EXE_MULT_OP)||(aluop_i == `EXE_MADD_OP)||(aluop_i == `EXE_MSUB_OP)) && (reg1_i[31] == 1'b1)) ? (~reg1_i+1) : (reg1_i);
	assign opdata2_mult = (((aluop_i == `EXE_MUL_OP)||(aluop_i == `EXE_MULT_OP)||(aluop_i == `EXE_MADD_OP)||(aluop_i == `EXE_MSUB_OP)) && (reg2_i[31] == 1'b1)) ? (~reg2_i+1) : (reg2_i);
	assign hilo_temp = opdata1_mult * opdata2_mult;
	always @(*) begin
		if(rst == `RstEnable) begin
			mulres = {`ZeroWord,`ZeroWord};
		end
		else if((aluop_i == `EXE_MULT_OP)||(aluop_i ==`EXE_MUL_OP)||(aluop_i == `EXE_MADD_OP)||(aluop_i == `EXE_MSUB_OP)) begin     				//有符号乘法运算
			if(reg1_i[31]^reg2_i[31] == 1'b1) begin
				mulres = ~hilo_temp+1;
			end
			else begin
				mulres = hilo_temp;
			end
		end
		else begin
			mulres = hilo_temp;
		end
	end
	//第二段: 乘累加\乘累减
	always @(*) begin
		if(rst == `RstEnable) begin
			hilo_temp_o = {`ZeroWord,`ZeroWord};
			cnt_o 		= 2'b00;
			stallreq_for_madd_msub = `NoStop;
		end
		else begin
			case(aluop_i)
				`EXE_MADD_OP,`EXE_MADDU_OP:	begin
					if(cnt_i == 2'b00)	begin
						hilo_temp_o = mulres;
						cnt_o		= 2'b01;
						hilo_temp1	= {`ZeroWord,`ZeroWord};
						stallreq_for_madd_msub = `Stop;
					end
					else if(cnt_i == 2'b01)	begin
						hilo_temp_o	= {`ZeroWord,`ZeroWord};
						cnt_o		= 2'b10;
						hilo_temp1	= hilo_temp_i + {HI,LO};
						stallreq_for_madd_msub = `NoStop;
					end
				end
				`EXE_MSUB_OP,`EXE_MSUBU_OP:	begin
					if(cnt_i == 2'b00)	begin 				//执行阶段的第一个时钟周期
						hilo_temp_o = ~mulres + 1;
						cnt_o		= 2'b01;
						stallreq_for_madd_msub = `Stop;
					end
					else if(cnt_i == 2'b01)	begin 			//执行阶段的第二个时钟周期
						hilo_temp_o	= {`ZeroWord,`ZeroWord};
						cnt_o		= 2'b10;
						hilo_temp1	= hilo_temp_i + {HI,LO};
						stallreq_for_madd_msub = `NoStop;
					end
				end
				default:	begin
					hilo_temp_o = {`ZeroWord,`ZeroWord};
					cnt_o		= 2'b00;
					stallreq_for_madd_msub = `NoStop;
				end
			endcase
		end
	end
	//第三段: 暂停流水线
	always @(*) begin
		stallreq = stallreq_for_madd_msub || stallreq_for_div; 
	end
	
	//第一段:进行除法运算
	always @(*) begin
		if(rst == `RstEnable) begin
			stallreq_for_div	= `NoStop;
			div_opdata1_o		= `ZeroWord;
			div_opdata2_o		= `ZeroWord;
			div_start_o			= `DivStop;
			signed_div_o		= 1'b0;
		end
		else begin
			stallreq_for_div	= `NoStop;
			div_opdata1_o		= `ZeroWord;
			div_opdata2_o		= `ZeroWord;
			div_start_o			= `DivStop;
			signed_div_o		= 1'b0;
			case(aluop_i)
				`EXE_DIV_OP:	begin 									//DIV指令
					if(div_ready_i == `DivResultNotReady)	begin
						div_opdata1_o	= reg1_i;						//被除数
						div_opdata2_o	= reg2_i;						//除数
						div_start_o		= `DivStart;					//开始除法运算
						signed_div_o	= 1'b1;							//有符号除法
						stallreq_for_div = `Stop;						//请求流水线暂停
					end
					else if(div_ready_i == `DivResultReady)	begin
						div_opdata1_o	= reg1_i;
						div_opdata2_o	= reg2_i;
						div_start_o		= `DivStop;						//结束除法运算
						signed_div_o	= 1'b1;
						stallreq_for_div = `NoStop;						//不在请求流水线暂停
					end
					else begin
						div_opdata1_o	= `ZeroWord;
						div_opdata2_o	= `ZeroWord;
						div_start_o		= `DivStop;
						signed_div_o	= 1'b0;
						stallreq_for_div = `NoStop;
					end
				end
				`EXE_DIVU_OP:	begin 									//DIVU指令
					if(div_ready_i == `DivResultNotReady)	begin
						div_opdata1_o	= reg1_i;						//被除数
						div_opdata2_o	= reg2_i;						//除数
						div_start_o		= `DivStart;					//开始除法运算
						signed_div_o	= 1'b0;							//有符号除法
						stallreq_for_div = `Stop;						//请求流水线暂停
					end
					else if(div_ready_i == `DivResultReady)	begin
						div_opdata1_o	= reg1_i;
						div_opdata2_o	= reg2_i;
						div_start_o		= `DivStop;						//结束除法运算
						signed_div_o	= 1'b0;
						stallreq_for_div = `NoStop;						//不在请求流水线暂停
					end
					else begin
						div_opdata1_o	= `ZeroWord;
						div_opdata2_o	= `ZeroWord;
						div_start_o		= `DivStop;
						signed_div_o	= 1'b0;
						stallreq_for_div = `NoStop;
					end
				end
				default:	begin
				end
			endcase
		end
	end
	//第二段:暂停流水线
	//第三段:修改HI\LO寄存器信息
	
	
	//依据alusel_i选择最终的运算结果
	always @(*) begin
		wd_o = wd_i;									//要写入的目的寄存器的地址
		if(((aluop_i == `EXE_ADD_OP)||(aluop_i == `EXE_ADDI_OP)||(aluop_i == `EXE_SUB_OP)) && (ov_sum == 1'b1)) begin 		//表示add\addi\sub\subi指令发生溢出,则取消写寄存器
			wreg_o = `WriteDisable;
		end
		else begin
			wreg_o = wreg_i;							//表示是否要写目的寄存器
		end
		case (alusel_i)
			`EXE_RES_LOGIC: begin
				wdata_o = logicout; 					//选择逻辑运算结果为最终运算结果			
			end
			`EXE_RES_SHIFT: begin
				wdata_o = shiftres; 					//选择移位运算结果为最终运算结果			
			end
			`EXE_RES_MOVE: begin
				wdata_o = moveres;						//选择移动运算结果为最终运算结果
			end
			`EXE_RES_ARITHMETIC: begin
				wdata_o = arithmeticres;				//乘法以外的简单算术指令
			end
			`EXE_RES_MUL: begin
				wdata_o = mulres[31:0];					//乘法指令mul
			end
			`EXE_RES_JUMP_BRANCH: begin
				wdata_o = link_address_i;
			end
			default: begin
				wdata_o = `ZeroWord;
			end
		endcase
	end
	
	//如果是MTHI\MTLO指令,那么需要给出whilo_o\hi_o\lo_o的值
	//第四段: 修改HI\LO	寄存器的写信息
	always @(*) begin
		if(rst == `RstEnable) begin
			whilo_o = `WriteDisable;
			hi_o 	= `ZeroWord;
			lo_o	= `ZeroWord;			
		end
		else if((aluop_i == `EXE_MSUB_OP)||(aluop_i == `EXE_MSUBU_OP)) begin
			whilo_o = `WriteEnable;
			hi_o	= hilo_temp1[63:32];
			lo_o	= hilo_temp1[31:0];
		end
		else if((aluop_i == `EXE_MADD_OP)||(aluop_i == `EXE_MADDU_OP)) begin
			whilo_o = `WriteEnable;
			hi_o	= hilo_temp1[63:32];
			lo_o	= hilo_temp1[31:0];
		end
		else if((aluop_i == `EXE_MULT_OP)||(aluop_i == `EXE_MULTU_OP)) begin 			//mult\multu指令, 要写入HI\LO寄存器
			whilo_o = `WriteEnable;
			hi_o	= mulres[63:32];
			lo_o	= mulres[31:0];
		end
		else if(aluop_i == `EXE_MTHI_OP) begin
			whilo_o = `WriteEnable;
			hi_o 	= reg1_i;
			lo_o	= LO;
		end
		else if(aluop_i == `EXE_MTLO_OP) begin
			whilo_o = `WriteEnable;
			hi_o	= HI;
			lo_o 	= reg1_i;
		end
		else if((aluop_i == `EXE_DIV_OP)||(aluop_i == `EXE_DIVU_OP))	begin
			whilo_o	= `WriteEnable;
			hi_o	= div_result_i[63:32];												//高32位存余数
			lo_o	= div_result_i[31:0];												//低32位存商
		end
		else begin
			whilo_o = `WriteDisable;
			hi_o 	= `ZeroWord;
			lo_o	= `ZeroWord; 
		end
	end
	
	always @(*) begin
		if(rst == `RstEnable) begin
			cp0_reg_write_addr_o	= 5'b00000;
			cp0_reg_we_o			= `WriteDisable;
			cp0_reg_data_o			= `ZeroWord;
		end
		else if(aluop_o == `EXE_MTC0_OP) begin
			cp0_reg_write_addr_o	= inst_i[15:11];
			cp0_reg_we_o			= `WriteEnable;
			cp0_reg_data_o			= reg1_i;
		end
		else begin
			cp0_reg_write_addr_o	= 5'b00000;
			cp0_reg_we_o			= `WriteDisable;
			cp0_reg_data_o			= `ZeroWord;
		end
	end
	
endmodule

















