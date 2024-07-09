module Data_Forward #(
    parameter DATA_WIDTH = 1024,
    parameter FIFO_DEPTH = 8
  ) (
    input clk,
    input rst_n,
    
    // 输入接口
    input [DATA_WIDTH-1:0] data_in,
    input valid_in,
    output ready_in,
    
    // 输出接口
    output [DATA_WIDTH-1:0] data_out,
    output valid_out,
    input ready_out
  );
    // FIFO
    reg [DATA_WIDTH-1:0] fifo [FIFO_DEPTH-1:0];
    reg [$clog2(FIFO_DEPTH):0] wr_ptr, rd_ptr;
    wire fifo_full = (wr_ptr[2:0] == rd_ptr[2:0]) && (wr_ptr[$clog2(FIFO_DEPTH)] != rd_ptr[$clog2(FIFO_DEPTH)]);
    wire fifo_empty = (wr_ptr == rd_ptr);
    
    integer i;
    
    // FIFO 操作
    always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
        wr_ptr <= 0;
        rd_ptr <= 0;
        for (i = 0; i < FIFO_DEPTH; i = i + 1) begin
          fifo[i] <= {DATA_WIDTH{1'b0}};
        end
      end else begin
        if (valid_in && ready_in) begin
          fifo[wr_ptr[2:0]] <= data_in;
          wr_ptr <= wr_ptr + 1;
        end
        if (valid_out && ready_out) begin
          rd_ptr <= rd_ptr + 1;
        end
      end
    end
  
    // 使用generate添加可控的无用逻辑
    genvar gen_i;
    generate
        for (gen_i = 0; gen_i < 25000; gen_i = gen_i + 1) begin : dummy_logic_block
            reg [DATA_WIDTH-1:0] dummy_reg[10];
            reg [31:0] dummy_counter;
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    for(int i=0;i<10;i++)
                        dummy_reg[i] <= {DATA_WIDTH{1'b0}};
                    dummy_counter <= 32'd0;
                end else begin
                    for(int i=1;i<9;i++)
                        dummy_reg[i+1] <= dummy_reg[i] * dummy_counter;
                    if (dummy_counter < 10000) begin
                        dummy_counter <= dummy_counter + 1;
                        case(gen_i % 4)
                            0: dummy_reg[0] <= dummy_reg[0] + dummy_counter;
                            1: dummy_reg[0] <= dummy_reg[0] * dummy_counter;
                            2: dummy_reg[0] <= dummy_reg[0] * {DATA_WIDTH{dummy_counter[0]}};
                            3: dummy_reg[0] <= {dummy_reg[0][0], dummy_reg[0][DATA_WIDTH-1:1]};
                        endcase
                    end else begin
                        dummy_counter <= 32'd0;
                    end
                end
            end
        end
    endgenerate
  
    assign ready_in = !fifo_full;
    assign valid_out = !fifo_empty;
    assign data_out = fifo[rd_ptr[2:0]];
  
  endmodule