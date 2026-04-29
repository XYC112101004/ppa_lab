module apb_slave_if(
  // APB 接口
  input  logic        PCLK,
  input  logic        PRESETn,
  input  logic        PSEL,
  input  logic        PENABLE,
  input  logic        PWRITE,
  input  logic [11:0] PADDR,
  input  logic [31:0] PWDATA,
  output logic [31:0] PRDATA,
  output logic        PREADY,
  output logic        PSLVERR,
  
  // 控制输出
  output logic        enable_o,
  output logic        start_o,
  output logic        algo_mode_o,
  output logic [3:0]  type_mask_o,
  output logic [5:0]  exp_pkt_len_o,
  output logic        done_irq_en_o,
  output logic        err_irq_en_o,
  
  // SRAM 写端口
  output logic        pkt_mem_we_o,
  output logic [2:0]  pkt_mem_addr_o,
  output logic [31:0] pkt_mem_wdata_o,
  
  // 状态输入
  input  logic        busy_i,
  input  logic        done_i,
  input  logic        format_ok_i,
  input  logic        length_error_i,
  input  logic        type_error_i,
  input  logic        chk_error_i,
  input  logic [5:0]  res_pkt_len_i,
  input  logic [7:0]  res_pkt_type_i,
  input  logic [7:0]  res_payload_sum_i,
  input  logic [7:0]  res_payload_xor_i,
  
  // 中断输出
  output logic        irq_o
);

  // 寄存器定义
  logic [0:0]  ctrl_enable;
  logic [7:0]  cfg_reg;
  logic [3:0]  status_reg;
  logic [1:0]  irq_en_reg;
  logic [1:0]  irq_sta_reg;
  logic [5:0]  pkt_len_exp_reg;
  
  // 地址译码
  logic [11:0] addr;  // 12-bit APB 地址
  assign addr = PADDR;
  
  // PREADY 固定为 1
  assign PREADY = 1'b1;
  
  // 控制输出
  assign enable_o      = ctrl_enable[0];
  assign algo_mode_o   = cfg_reg[0];
  assign type_mask_o   = cfg_reg[7:4];
  assign exp_pkt_len_o = pkt_len_exp_reg;
  assign done_irq_en_o = irq_en_reg[0];
  assign err_irq_en_o  = irq_en_reg[1];
  
  // 中断生成
  logic done_irq;  // 完成中断
  logic err_irq;   // 错误中断
  
  assign done_irq = done_i & done_irq_en_o;
  assign err_irq  = (length_error_i | type_error_i | chk_error_i) & err_irq_en_o;
  assign irq_o    = done_irq | err_irq;
  
  // 写入逻辑
  always_ff @(posedge PCLK or negedge PRESETn) begin
    if (!PRESETn) begin
      // 复位值
      ctrl_enable     <= 1'b0;
      cfg_reg         <= 8'b11110001;  // algo_mode=1, type_mask=4'b1111
      irq_en_reg      <= 2'b00;
      irq_sta_reg     <= 2'b00;
      pkt_len_exp_reg <= 6'b000000;
      start_o         <= 1'b0;
      PSLVERR         <= 1'b0;
    end else begin
      // 清除 start 脉冲
      start_o <= 1'b0;
      PSLVERR <= 1'b0;
      
      // 设置中断标志
      if (done_i) begin
        irq_sta_reg[0] <= 1'b1;
      end
      if (length_error_i || type_error_i || chk_error_i) begin
        irq_sta_reg[1] <= 1'b1;
      end
      
      // 写入寄存器
      if (PSEL && PENABLE && PWRITE) begin
        case (addr)
          12'h000: begin  // CTRL - 可写
            ctrl_enable <= PWDATA[0];
            if (PWDATA[1]) start_o <= 1'b1;  // W1P
          end
          12'h004: begin  // CFG - 可写
            cfg_reg <= PWDATA[7:0];
          end
          12'h00C: begin  // IRQ_EN - 可写
            irq_en_reg <= PWDATA[1:0];
          end
          12'h010: begin  // IRQ_STA - RW1C（写1清零）
            if (PWDATA[0]) irq_sta_reg[0] <= 1'b0;  // 写1清零
            if (PWDATA[1]) irq_sta_reg[1] <= 1'b0;  // 写1清零
          end
          12'h014: begin  // PKT_LEN_EXP - 可写
            pkt_len_exp_reg <= PWDATA[5:0];
          end
          // RO寄存器 - 尝试写入时设置PSLVERR，值不变
          12'h008: begin  // STATUS - RO，只读
            PSLVERR <= 1'b1;
          end
          12'h018: begin  // RES_PKT_LEN - RO，只读
            PSLVERR <= 1'b1;
          end
          12'h01C: begin  // RES_PKT_TYPE - RO，只读
            PSLVERR <= 1'b1;
          end
          12'h020: begin  // RES_PAYLOAD_SUM - RO，只读
            PSLVERR <= 1'b1;
          end
          12'h024: begin  // RES_PAYLOAD_XOR - RO，只读
            PSLVERR <= 1'b1;
          end
          12'h028: begin  // RES_ERROR - RO，只读
            PSLVERR <= 1'b1;
          end
          // PKT_MEM 写入
          12'h040, 12'h044, 12'h048, 12'h04C, 12'h050, 12'h054, 12'h058, 12'h05C: begin
            if (!busy_i) begin
              pkt_mem_we_o     <= 1'b1;
              pkt_mem_addr_o   <= (addr - 12'h040) >> 2;
              pkt_mem_wdata_o  <= PWDATA;
            end else begin
              PSLVERR <= 1'b1;  // busy时写入返回错误
            end
          end
          // 访问未定义地址
          default: begin
            PSLVERR <= 1'b1;
          end
        endcase
      end else begin
        pkt_mem_we_o <= 1'b0;
      end
    end
  end
  
  // 读取逻辑
  always_comb begin
    case (addr)
      12'h000: PRDATA = {31'b0, ctrl_enable};
      12'h004: PRDATA = {24'b0, cfg_reg};
      12'h008: PRDATA = {28'b0, format_ok_i, (length_error_i | type_error_i | chk_error_i), done_i, busy_i};
      12'h00C: PRDATA = {30'b0, irq_en_reg};
      12'h010: PRDATA = {30'b0, irq_sta_reg};
      12'h014: PRDATA = {26'b0, pkt_len_exp_reg};
      12'h018: PRDATA = {26'b0, res_pkt_len_i};
      12'h01C: PRDATA = {24'b0, res_pkt_type_i};
      12'h020: PRDATA = {24'b0, res_payload_sum_i};
      12'h024: PRDATA = {24'b0, res_payload_xor_i};
      12'h028: PRDATA = {29'b0, chk_error_i, type_error_i, length_error_i};
      12'h040, 12'h044, 12'h048, 12'h04C, 12'h050, 12'h054, 12'h058, 12'h05C: begin
        // PKT_MEM 读操作由 SRAM 直接返回
        // 这里仅做地址译码，实际数据由 SRAM 提供
        PRDATA = 32'b0;
      end
      default: PRDATA = 32'b0;
    endcase
  end
  
endmodule
