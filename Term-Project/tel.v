`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    15:57:04 01/05/2021 
// Design Name: 
// Module Name:    design 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module tel(clk, rst, startCall, answerCall, endCallCaller, endCallCallee, sendCharCaller, sendCharCallee, charSent, statusMsg, sentMsg);
	 input clk;
	 input rst;
	 input startCall, answerCall;
	 input endCallCaller, endCallCallee;
	 input sendCharCaller, sendCharCallee;
	 input [7:0] charSent;
	 output reg [63:0] statusMsg;
	 output reg [63:0] sentMsg;
	 
	 reg [31:0] cost;
	 reg [3:0] count;
	 reg [2:0] current_state;
	 reg [2:0] next_state;
	 
	 parameter [2:0] S0 = 3'b000;
	 parameter [2:0] S1 = 3'b001;
	 parameter [2:0] S2 = 3'b010;
	 parameter [2:0] S3 = 3'b011;
	 parameter [2:0] S4 = 3'b100;
	 parameter [2:0] S5 = 3'b101;
	 
	 
	 always @ (posedge clk or posedge rst) begin
		if(rst) begin
			current_state <= S0;
		end
		
		else
			current_state <= next_state;
	 end
	 
	 always @(*)
	 begin
		case(current_state)
			S0: // IDLE
			begin
				if(startCall == 1'b0) next_state = S0;
				else begin
					next_state = S1;
				end
			end
			S1: // RINGING
			begin
				if(count >= 4'd9) begin
					next_state = S0;
				end
				else if(endCallCaller == 1'b1) next_state = S0;
				else if(endCallCallee  == 1'b1) begin
					next_state = S2;
				end
				else if(answerCall == 1'b1) begin
					next_state = S3;
				end
				else begin
					next_state = S1;
				end
			end
			S2: // REJECTED
			begin
				if(count >= 4'd9) begin
					next_state = S0;
				end
				else begin
					next_state = S2;
				end
			end
			S3: // CALLER
			begin
				if(endCallCaller == 1'b1 | endCallCallee == 1'b1)
				begin
					next_state = S5;
				end
				else if(charSent == 127 & sendCharCaller) next_state = S4;
				else next_state = S3;
			end
			S4: // CALLEE
			begin
				if(endCallCaller == 1'b1 | endCallCallee == 1'b1) next_state = S5;
				else if(charSent == 127 & sendCharCallee) next_state = S3;
				else next_state = S4;
			end
			S5: // COST
			begin
				if(count >= 4) 
				begin
					next_state = S0;
				end
				else 
				begin
					next_state = S5;
				end
			end
			default : next_state = S0;
		endcase
	 end
	 
	 always @(posedge clk or posedge rst)
        begin
        if (rst) count <= 0;
        else if (startCall) count <= 0;
        else if (count == 10) count <= 0;
        else if (!endCallCaller & !endCallCallee & !answerCall)    count <= count + 1;
        else count <= 0;
		  end
	
	 always @ (posedge clk or posedge rst) begin
		if(rst) cost <= 0;
		else if(current_state == S0) cost <= 0;
		else 
		begin
			if((sendCharCaller | sendCharCallee) & (charSent >= 32 & charSent <= 127)) 
			begin
				if(charSent >= 48 & charSent <= 57) cost <= cost + 1;
				else cost <= cost + 2;
			end
		end
	end

	 always @ (posedge clk or posedge rst) begin
		if(rst)
		begin
			sentMsg[7:0] <= 32;
			sentMsg[15:8] <= 32;
			sentMsg[23:16] <= 32;
			sentMsg[31:24] <= 32;
			sentMsg[39:32] <= 32;
			sentMsg[47:40] <= 32;
			sentMsg[55:48] <= 32;
			sentMsg[63:56] <= 32;
		end
		
		else if(current_state == S5)
		begin
			sentMsg[7:0] <= cost[3:0] + 48;
			sentMsg[15:8] <= cost[7:4] + 48;
			sentMsg[23:16] <= cost[11:8] + 48;
			sentMsg[31:24] <= cost[15:12] + 48;
			sentMsg[39:32] <= cost[19:16] + 48;
			sentMsg[47:40] <= cost[23:20] + 48;
			sentMsg[55:48] <= cost[27:24] + 48;
			sentMsg[63:56] <= cost[31:28] + 48;
		end
		
		else if(endCallCaller | endCallCallee | charSent == 127 | current_state == S0) begin			
			sentMsg[7:0] <= 32;
			sentMsg[15:8] <= 32;
			sentMsg[23:16] <= 32;
			sentMsg[31:24] <= 32;
			sentMsg[39:32] <= 32;
			sentMsg[47:40] <= 32;
			sentMsg[55:48] <= 32;
			sentMsg[63:56] <= 32;
		end
		else begin
			if((sendCharCaller | sendCharCallee) & (charSent >= 32 & charSent <= 126)) begin
				sentMsg[7:0] <= charSent;
				sentMsg[15:8] <= sentMsg[7:0];
				sentMsg[23:16] <= sentMsg[15:8];
				sentMsg[31:24] <= sentMsg[23:16];
				sentMsg[39:32] <= sentMsg[31:24];
				sentMsg[47:40] <= sentMsg[39:32];
				sentMsg[55:48] <= sentMsg[47:40];
				sentMsg[63:56] <= sentMsg[55:48];
			end
			else begin
				sentMsg <= sentMsg;
			end
		end
	end
	
	
	always @ (posedge clk or posedge rst) begin
		if(rst) statusMsg = "IDLE    ";
		
		else
		begin
			case(current_state)
				S0:
				begin
					statusMsg = "IDLE    ";
				end
				S1:
				begin
					statusMsg = "RINGING ";
				end
				S2:
				begin
					statusMsg = "REJECTED";
				end
				S3:
				begin
					statusMsg = "CALLER  ";
				end
				S4:
				begin
					statusMsg = "CALLEE  ";
				end
				S5:
				begin
					statusMsg = "COST    ";
				end
				endcase
		end
	end
	 
	 
	 


endmodule