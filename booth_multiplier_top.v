/*Refference 1. NPTEL LECTURES  */

module booth_multiplier_top(data_in,clk,start,output_data);
	
  wire ldA,clrA,sftA,ldQ,clrQ,sftQ,done;
  wire ldM,clrFF,addsub,decr,ldcount;
  input signed [15:0]data_in;
  input start,clk;
  wire qm1,eqz;
    output signed [31:0]output_data;
  wire [4:0] countdata;
  wire signed [15:0] A,M,Q,Z;   //A->Acc , M->Multiplicand , Q->Multiplier, Z->(A-M,A+M) 
  assign eqz = ~| (countdata);
    assign output_data = {A,Q};

 shiftreg Acc_A(.data_out(A),.ld_data(Z),.s_in(A[15]),.clk(clk),.ld(ldA),.rst(clrA),.sft(sftA));
 shiftreg Mlpr_Q(.data_out(Q),.ld_data(data_in),.s_in(A[0]),.clk(clk),.ld(ldQ),.rst(clrQ),.sft(sftQ));
 dflipflop d_ff(.data_in(Q[0]),.clk(clk),.rst(clrFF),.data_out(qm1));
 PIPO Mlcd_M(.data_out(M),.data_in(data_in),.clk(clk),.ld(ldM));
 ALU  Adsub(.out(Z),.in1(A),.in2(M),.addsub(addsub));			
 bitcounter counter(.countdata(countdata),.decr(decr),.ldcount(ldcount),.clk(clk));
 controller fsm(.ldA(ldA),.clrA(clrA),.sftA(sftA),.ldQ(ldQ),.clrQ(clrQ),.sftQ(sftQ),.ldM(ldM),
	            .clrFF(clrFF),.addsub(addsub),.start(start),.decr(decr),.ldcount(ldcount),
					.done(done),.clk(clk),.q0(Q[0]),.qm1(qm1),.eqz(eqz)); 

 endmodule

module bitcounter(countdata,decr,ldcount,clk);
    input decr,ldcount,clk;
	 output reg [4:0] countdata;
	 
	 always@(posedge clk)
	   begin
	       if(ldcount)
		      countdata <= 16; //since datain is of 16 bits width
		   else if(decr)
              countdata <= countdata - 1;			
	   end
	   
endmodule

module PIPO(data_out,data_in,clk,ld);

input signed [15:0] data_in;
input clk,ld;
output reg signed [15:0] data_out;

always@(posedge clk)
  begin
      if(ld)
        data_out <= data_in;
   end
endmodule   

module ALU (out,in1,in2,addsub);

  input addsub ;  // addsub = 1 then addition else subtraction
  input signed[15:0] in1,in2;
  output reg signed[15:0] out;
  
  always@(*)
    begin
      if(addsub)
	      out  = in1 + in2;
      else if(!addsub)
	      out  = in1 - in2;
	end
	
endmodule

module shiftreg(data_out,ld_data,s_in,clk,ld,rst,sft);   //SIPO

input [15:0] ld_data;
input clk,rst,ld,s_in,sft;
output reg [15:0]data_out;

always@(posedge clk)
 begin
    if(rst)
	    data_out <= 0;
	else if(ld)
        data_out <= ld_data;
    else if(sft)
        data_out <= {s_in,data_out[15:1]};	
 end
 
 endmodule

 module dflipflop(data_in,clk,rst,data_out);

input data_in,clk,rst;
output reg data_out;

always@(posedge clk)
   begin
        if(rst)
		   data_out <= 0;
		else 
		   data_out <= data_in;
   end
   
endmodule 

module controller(ldA,clrA,sftA,ldQ,clrQ,sftQ,ldM,clrFF,addsub,start,decr,
                     ldcount,done,clk,q0,qm1,eqz);
					 
    input clk,q0,qm1,start,eqz;
	output  ldA,clrA,sftA,ldQ,clrQ,sftQ,ldM,clrFF,addsub,decr,
                     ldcount,done;

	reg [2:0] state;
    parameter [2:0] S0 = 3'b000,
                    S1 = 3'b001,
					S2 = 3'b010,
					S3 = 3'b011,
					S4 = 3'b100,
					S5 = 3'b101,
					S6 = 3'b110;
					
	always@(posedge clk)
       begin
	        case(state)
			   S0 :  state <= start?S1:S0;
			   S1 :  state <= S2;
			   S2 :  begin
                     #1
			         if({q0,qm1}==2'b01)
					    state <=  S3;
				     else if({q0,qm1}==2'b10)
					    state <=  S4;
				     else if(({q0,qm1}==2'b00)||({q0,qm1}==2'b11))	
                        state <=  S5;					 
                     end
					 
				S3 :  state <=  S5;
				S4 :  state <=  S5;
				S5 :  begin
                         #1 
				          if(({q0,qm1}==2'b01) && !eqz)
					         state <=  S3;
				          else if(({q0,qm1}==2'b10) && !eqz)
							 state <=  S4;
						  else if(eqz)
						     state <= S6;    
				      end
				S6 :  state <= S6;
				default : state <= S0;
			endcase	
		end	   
				
 
  
    assign ldA     = ((state == S3)||(state == S4))?1:0;
    assign clrA    =  (state == S0)?1:0;
	assign sftA    =  (state == S5)?1:0;
    assign ldQ     =  (state == S2)?1:0;
    assign clrQ    =  (state == S0)?1:0;
	assign sftQ    =  (state == S5)?1:0;
    assign ldM     =  (state == S1)?1:0;
    assign clrFF   =  (state == S0)?1:0;
	assign addsub     =  (state == S3)?1:0;
    
	assign decr    =  (state == S5)?1:0;
	assign ldcount =  (state == S1)?1:0; 
	assign done    =  (state == S6)?1:0;	
    
 
  endmodule