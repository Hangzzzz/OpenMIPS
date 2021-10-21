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

`define EXE_AND					 6'b100100				//指令and的功能码		
`define EXE_OR 					 6'b100101				//指令or的功能码
`define EXE_XOR 				 6'b100110				//指令xor的功能码
`define EXE_NOR 				 6'b100111				//指令nor的功能码
`define EXE_ANDI 				 6'b001100				//指令andi的指令码
`define EXE_XORI 				 6'b001110				//指令xori的指令码
`define EXE_LUI 				 6'b001111				//指令lui的指令码

`define EXE_SLL					 6'b000000				//sll指令的功能码
`define EXE_SLLV				 6'b000100				//sllv指令的功能码
`define EXE_SRL					 6'b000010				//sra指令的功能码
`define EXE_SRLV				 6'b000110				//srlv指令的功能码
`define EXE_SRA					 6'b000011				//sra指令的功能码
`define EXE_SRAV				 6'b000111				//srav指令的功能码

`define EXE_SYNC				 6'b001111 				//sync指令的功能码
`define EXE_PREF				 6'b110011 				//pref指令的功能码
`define EXE_SPECIAL_INST		 6'b000000 				//SPECIAL类指令的功能码

//AluOp
`define EXE_AND_OP  			 8'b00100100
`define EXE_OR_OP   			 8'b00100101
`define EXE_XOR_OP  			 8'b00100110
`define EXE_NOR_OP 				 8'b00100111
`define EXE_ANDI_OP  			 8'b01011001
`define EXE_ORI_OP  			 8'b01011010
`define EXE_XORI_OP  			 8'b01011011
`define EXE_LUI_OP  			 8'b01011100   

`define EXE_SLL_OP  		 	 8'b01111100
`define EXE_SLLV_OP  			 8'b00000100
`define EXE_SRL_OP  			 8'b00000010
`define EXE_SRLV_OP 			 8'b00000110
`define EXE_SRA_OP  			 8'b00000011
`define EXE_SRAV_OP  			 8'b00000111

`define EXE_NOP_OP    			 8'b00000000

//AluSel
`define EXE_RES_LOGIC			 3'b001
`define EXE_RES_NOP				 3'b000
`define EXE_RES_SHIFT 			 3'b010

//***********************************与指令存储器ROM有关的宏定义********************************
`define InstAddrBus				 31:0					//ROM的地址总线宽度
`define InstBus					 31:0					//ROM的数据总线宽度
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

