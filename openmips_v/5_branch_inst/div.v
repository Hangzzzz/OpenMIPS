`include "defines.v"
module div(
	input wire 			clk,
	input wire 			rst,
	
	input wire 			signed_div_i,
	input wire[31:0]	opdata1_i,
	input wire[31:0] 	opdata2_i,
	input wire 			start_i,
	input wire 			annul_i,
	
	output reg[63:0]	result_o,
	output reg			ready_o
	);
	
	wire [32:0]			div_temp;
	reg	 [5:0]			cnt;
	reg  [63:0]			dividend;						//高33位是被除数,低32位是剩余的被除数
	reg  [1:0]			state;
	reg  [31:0]			divisor;						//除数
	//reg  [31:0]			temp_op1;
	//reg  [31:0] 			temp_op2;
	reg  [31:0] 		quotient;						//商
	reg  [31:0]			div_temp1;						//余数
	
	assign div_temp = dividend[63:31] - {1'b0,divisor};				//相减过后的余数
	
	always @(posedge clk) begin
		if(rst == `RstEnable) begin
			state		<= `DivFree;
			ready_o		<= `DivResultNotReady;
			result_o	<= {`ZeroWord,`ZeroWord};
		
			divisor 	<= `ZeroWord;
			dividend	<= 64'd0;
			quotient	<= `ZeroWord;
			div_temp1	<= `ZeroWord;
		end
		else begin
			case(state)
				`DivFree:	begin 							//DivFree的状态
					if(start_i == `DivStart && annul_i == 1'b0) begin
						if(opdata2_i == `ZeroWord) begin
							state <= `DivByZero;			//除数为0
						end
						else begin
							state	<= `DivOn;				//除数不为0
							cnt		<= 6'b000000;
							if(signed_div_i == 1'b1 && opdata1_i[31] == 1'b1) begin
								dividend[31:0]	<= ~opdata1_i +1;		//被除数取补码
							end
							else begin
								dividend[31:0]	<= opdata1_i;
							end
							
							if(signed_div_i == 1'b1 && opdata2_i[31] == 1'b1) begin
								divisor			<= ~opdata2_i +1;		//除数取补码
							end
							else begin
								divisor			<= opdata2_i;
							end
						

						end
					end
					else begin
						ready_o		<= `DivResultNotReady;
						result_o	<= {`ZeroWord,`ZeroWord};
					end
				end
				`DivByZero:	begin
					dividend 	<= 64'd0;
					state		<= `DivEnd;
				end
				`DivOn:		begin
					if(annul_i == 1'b0) begin
						if(cnt != 6'b100000) begin
							if(div_temp[32] == 1'b1) begin 										//被除数-除数小于0
								quotient[31-cnt] 	<= 1'b0;									//这一位的商为0
								dividend  			<= {dividend[62:0],1'b0};					//被除数向前移一位
								div_temp1			<= dividend[62:31];
							end
							else begin 															//被除数-除数大于0
								quotient[31-cnt]	<= 1'b1;
								dividend			<= {div_temp[31:0],dividend[30:0],1'b0};
								div_temp1			<= div_temp[31:0];
							end
							cnt	<= cnt+1;
						end
						else begin
							if((signed_div_i == 1'b1)&&((opdata1_i[31] ^ opdata2_i[31]) == 1'b1)) begin
								quotient	<= (~quotient + 1);  					//商,求补码
							end
							if((signed_div_i == 1'b1)&&((opdata1_i[31] ^ div_temp1[31]) == 1'b1)) begin
								div_temp1	<= (~div_temp1 + 1);  					//余数,求补码
							end
							state	<= `DivEnd;
							cnt		<= 6'b000000;
						end
					end
					else begin
					state	<= `DivFree;
					end
				end
				`DivEnd:	begin
					dividend	<= 64'd0;
					div_temp1	<= `ZeroWord;
					quotient	<= `ZeroWord;
					divisor		<= `ZeroWord;
					
					if(start_i == `DivStop) begin
						state	<= `DivFree;
						ready_o	<= `DivResultNotReady;
						result_o	<= {`ZeroWord,`ZeroWord};
					end
					else begin
						result_o	<= {div_temp1,quotient};							//高32位是余数,低32位是商
						ready_o		<= `DivResultReady;
					end
				end
			endcase
		end	

	end
	
endmodule	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	