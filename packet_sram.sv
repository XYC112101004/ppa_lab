module packet_sram(
  input  logic        clk,
  input  logic        rst_n,
  
  // 写端口
  input  logic        wr_en,
  input  logic [2:0]  wr_addr,
  input  logic [31:0] wr_data,
  
  // 读端口
  input  logic        rd_en,
  input  logic [2:0]  rd_addr,
  output logic [31:0] rd_data
);

  // 8×32-bit SRAM 存储
  logic [31:0] mem [7:0];
  
  // 写操作
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      // 复位时清空 SRAM
      for (int i = 0; i < 8; i++) begin
        mem[i] <= 32'b0;
      end
    end else begin
      if (wr_en) begin
        mem[wr_addr] <= wr_data;
      end
    end
  end
  
  // 读操作
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rd_data <= 32'b0;
    end else begin
      if (rd_en) begin
        rd_data <= mem[rd_addr];
      end
    end
  end
  
endmodule
