module booth_multiplier_top_tb();
  reg [15:0] data_in;
  reg clk,start;
  wire [31:0] output_data;
  
  booth_multiplier_top dut(data_in,clk,start,output_data);
  
  initial
     begin
       clk = 0;
       forever #5 clk = ~clk;
     end
  
   
    
  initial
      begin
        
       
        @(negedge clk) start = 1;
        @(negedge clk) data_in = -10;
        @(negedge clk) data_in = 11;
   
        #500 $finish;
     end
  
endmodule
