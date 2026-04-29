module tb;
  // 时钟和复位
  logic        PCLK;
  logic        PRESETn;
  
  // APB 接口
  logic        PSEL;
  logic        PENABLE;
  logic        PWRITE;
  logic [11:0] PADDR;
  logic [31:0] PWDATA;
  logic [31:0] PRDATA;
  logic        PREADY;
  logic        PSLVERR;
  
  // 控制输出
  logic        enable_o;
  logic        start_o;
  logic        algo_mode_o;
  logic [3:0]  type_mask_o;
  logic [5:0]  exp_pkt_len_o;
  logic        done_irq_en_o;
  logic        err_irq_en_o;
  
  // SRAM 写端口
  logic        pkt_mem_we_o;
  logic [2:0]  pkt_mem_addr_o;
  logic [31:0] pkt_mem_wdata_o;
  
  // 状态输入（stub 信号）
  logic        busy_i;
  logic        done_i;
  logic        format_ok_i;
  logic        length_error_i;
  logic        type_error_i;
  logic        chk_error_i;
  logic [5:0]  res_pkt_len_i;
  logic [7:0]  res_pkt_type_i;
  logic [7:0]  res_payload_sum_i;
  logic [7:0]  res_payload_xor_i;
  
  // 中断输出
  logic        irq_o;
  
  // SRAM 信号
  logic [31:0] sram_rd_data;
  
  // 实例化 DUT
  apb_slave_if u_apb_slave_if(
    .PCLK           (PCLK),
    .PRESETn        (PRESETn),
    .PSEL           (PSEL),
    .PENABLE        (PENABLE),
    .PWRITE         (PWRITE),
    .PADDR          (PADDR),
    .PWDATA         (PWDATA),
    .PRDATA         (PRDATA),
    .PREADY         (PREADY),
    .PSLVERR        (PSLVERR),
    .enable_o       (enable_o),
    .start_o        (start_o),
    .algo_mode_o    (algo_mode_o),
    .type_mask_o    (type_mask_o),
    .exp_pkt_len_o  (exp_pkt_len_o),
    .done_irq_en_o  (done_irq_en_o),
    .err_irq_en_o   (err_irq_en_o),
    .pkt_mem_we_o   (pkt_mem_we_o),
    .pkt_mem_addr_o (pkt_mem_addr_o),
    .pkt_mem_wdata_o(pkt_mem_wdata_o),
    .busy_i         (busy_i),
    .done_i         (done_i),
    .format_ok_i    (format_ok_i),
    .length_error_i (length_error_i),
    .type_error_i   (type_error_i),
    .chk_error_i    (chk_error_i),
    .res_pkt_len_i  (res_pkt_len_i),
    .res_pkt_type_i (res_pkt_type_i),
    .res_payload_sum_i(res_payload_sum_i),
    .res_payload_xor_i(res_payload_xor_i),
    .irq_o          (irq_o)
  );
  
  // 实例化 SRAM
  packet_sram u_packet_sram(
    .clk       (PCLK),
    .rst_n     (PRESETn),
    .wr_en     (pkt_mem_we_o),
    .wr_addr   (pkt_mem_addr_o),
    .wr_data   (pkt_mem_wdata_o),
    .rd_en     (1'b0),  // Lab1 阶段暂不使用读端口
    .rd_addr   (3'b0),
    .rd_data   (sram_rd_data)
  );
  
  // 时钟生成
  initial begin
    PCLK = 0;
    forever #5 PCLK = ~PCLK;
  end
  
  // 复位生成
  initial begin
    PRESETn = 0;
    #20 PRESETn = 1;
  end
  
  // APB 写任务
  task apb_write(input logic [11:0] addr, input logic [31:0] data);
    @(posedge PCLK);
    PSEL = 1;
    PENABLE = 0;
    PWRITE = 1;
    PADDR = addr;
    PWDATA = data;
    
    @(posedge PCLK);
    PENABLE = 1;
    
    @(posedge PCLK);
    PSEL = 0;
    PENABLE = 0;
  endtask
  
  // APB 读任务
  task apb_read(input logic [11:0] addr, output logic [31:0] data);
    @(posedge PCLK);
    PSEL = 1;
    PENABLE = 0;
    PWRITE = 0;
    PADDR = addr;
    
    @(posedge PCLK);
    PENABLE = 1;
    
    @(posedge PCLK);
    data = PRDATA;
    PSEL = 0;
    PENABLE = 0;
  endtask
  
  // 测试用例
  initial begin
    logic [31:0] read_data;
    
    // 初始化 stub 信号
    busy_i = 0;
    done_i = 0;
    format_ok_i = 0;
    length_error_i = 0;
    type_error_i = 0;
    chk_error_i = 0;
    res_pkt_len_i = 6'd0;
    res_pkt_type_i = 8'd0;
    res_payload_sum_i = 8'd0;
    res_payload_xor_i = 8'd0;
    
    // 等待复位完成
    @(posedge PRESETn);
    #10;
    
    // 测试用例 1: CSR 默认值检查
    $display("=== Test Case 1: CSR Default Values ===");
    
    // 读 CTRL 寄存器
    apb_read(12'h000, read_data);
    $display("CTRL default: %h", read_data);
    if (read_data[0] == 0) $display("✓ CTRL.enable default is 0");
    else $display("✗ CTRL.enable default is not 0");
    
    // 读 CFG 寄存器
    apb_read(12'h004, read_data);
    $display("CFG default: %h", read_data);
    if (read_data[0] == 1) $display("✓ CFG.algo_mode default is 1");
    else $display("✗ CFG.algo_mode default is not 1");
    if (read_data[7:4] == 4'b1111) $display("✓ CFG.type_mask default is 4'b1111");
    else $display("✗ CFG.type_mask default is not 4'b1111");
    
    // 读 STATUS 寄存器
    apb_read(12'h008, read_data);
    $display("STATUS default: %h", read_data);
    if (read_data[0] == 0) $display("✓ STATUS.busy default is 0");
    else $display("✗ STATUS.busy default is not 0");
    if (read_data[1] == 0) $display("✓ STATUS.done default is 0");
    else $display("✗ STATUS.done default is not 0");
    
    // 测试用例 2: PKT_MEM 写入测试
    $display("\n=== Test Case 2: PKT_MEM Write Test ===");
    
    // 写入 8 个 word 到 PKT_MEM
    for (int i = 0; i < 8; i++) begin
      apb_write(12'h040 + (i << 2), 32'hA0000000 + i);
      $display("Wrote 0x%h to address 0x%h", 32'hA0000000 + i, 12'h040 + (i << 2));
    end
    
    // 测试用例 3: RES_* 读通路测试
    $display("\n=== Test Case 3: RES_* Read Path Test ===");
    
    // 设置 stub 信号
    res_pkt_len_i = 6'd8;
    res_pkt_type_i = 8'h01;
    res_payload_sum_i = 8'hAA;
    res_payload_xor_i = 8'h55;
    
    // 读 RES_PKT_LEN
    apb_read(12'h018, read_data);
    $display("RES_PKT_LEN: %h", read_data);
    if (read_data[5:0] == 6'd8) $display("✓ RES_PKT_LEN read correct");
    else $display("✗ RES_PKT_LEN read incorrect");
    
    // 读 RES_PKT_TYPE
    apb_read(12'h01C, read_data);
    $display("RES_PKT_TYPE: %h", read_data);
    if (read_data[7:0] == 8'h01) $display("✓ RES_PKT_TYPE read correct");
    else $display("✗ RES_PKT_TYPE read incorrect");
    
    // 读 RES_PAYLOAD_SUM
    apb_read(12'h020, read_data);
    $display("RES_PAYLOAD_SUM: %h", read_data);
    if (read_data[7:0] == 8'hAA) $display("✓ RES_PAYLOAD_SUM read correct");
    else $display("✗ RES_PAYLOAD_SUM read incorrect");
    
    // 读 RES_PAYLOAD_XOR
    apb_read(12'h024, read_data);
    $display("RES_PAYLOAD_XOR: %h", read_data);
    if (read_data[7:0] == 8'h55) $display("✓ RES_PAYLOAD_XOR read correct");
    else $display("✗ RES_PAYLOAD_XOR read incorrect");
    
    // ========== 选做4: PSLVERR 测试 ==========
    $display("\n=== Test Case 4: PSLVERR Test ===");
    
    // 测试1: 写入RO寄存器应该产生PSLVERR
    $display("--- Test 4.1: Write to RO registers ---");
    
    // 读取STATUS当前值
    apb_read(12'h008, read_data);
    $display("STATUS before write: %h", read_data);
    
    // 尝试写入STATUS(RO寄存器)
    @(posedge PCLK);
    PSEL = 1; PENABLE = 0; PWRITE = 1; PADDR = 12'h008; PWDATA = 32'hFF;
    @(posedge PCLK);
    PENABLE = 1;
    @(posedge PCLK);
    #10;
    $display("PSLVERR after writing to STATUS (RO): %b", PSLVERR);
    if (PSLVERR == 1) $display("✓ PSLVERR=1 when writing to RO register");
    else $display("✗ PSLVERR should be 1 when writing to RO register");
    
    // 验证STATUS值未改变
    apb_read(12'h008, read_data);
    $display("STATUS after failed write: %h (should be unchanged)", read_data);
    
    // 测试2: 写入RES_* RO寄存器
    $display("--- Test 4.2: Write to RES_* RO registers ---");
    
    // 尝试写入RES_PKT_LEN
    @(posedge PCLK);
    PSEL = 1; PENABLE = 0; PWRITE = 1; PADDR = 12'h018; PWDATA = 32'hFF;
    @(posedge PCLK);
    PENABLE = 1;
    @(posedge PCLK);
    #10;
    $display("PSLVERR after writing to RES_PKT_LEN (RO): %b", PSLVERR);
    if (PSLVERR == 1) $display("✓ PSLVERR=1 when writing to RES_PKT_LEN");
    
    // 尝试写入RES_PKT_TYPE
    @(posedge PCLK);
    PSEL = 1; PENABLE = 0; PWRITE = 1; PADDR = 12'h01C; PWDATA = 32'hFF;
    @(posedge PCLK);
    PENABLE = 1;
    @(posedge PCLK);
    #10;
    $display("PSLVERR after writing to RES_PKT_TYPE (RO): %b", PSLVERR);
    if (PSLVERR == 1) $display("✓ PSLVERR=1 when writing to RES_PKT_TYPE");
    
    // 测试3: 访问未定义地址
    $display("--- Test 4.3: Access undefined address ---");
    @(posedge PCLK);
    PSEL = 1; PENABLE = 0; PWRITE = 1; PADDR = 12'h100; PWDATA = 32'hFF;
    @(posedge PCLK);
    PENABLE = 1;
    @(posedge PCLK);
    #10;
    $display("PSLVERR after accessing undefined addr 0x100: %b", PSLVERR);
    if (PSLVERR == 1) $display("✓ PSLVERR=1 when accessing undefined address");
    
    @(posedge PCLK);
    PSEL = 0; PENABLE = 0;
    
    // ========== 选做5: IRQ 测试 ==========
    $display("\n=== Test Case 5: IRQ Test ===");
    
    // 测试1: IRQ_EN读写测试
    $display("--- Test 5.1: IRQ_EN R/W ---");
    
    // 写入IRQ_EN
    apb_write(12'h00C, 32'h03);  // enable both interrupts
    $display("Wrote 0x03 to IRQ_EN");
    
    // 读取验证
    apb_read(12'h00C, read_data);
    $display("IRQ_EN after write: %h", read_data);
    if (read_data[1:0] == 2'b11) $display("✓ IRQ_EN write/read correct");
    else $display("✗ IRQ_EN write/read incorrect");
    
    // 测试2: IRQ_STA RW1C测试
    $display("--- Test 5.2: IRQ_STA RW1C ---");
    
    // 测试1: 写0不影响（当bit0=1时）
    $display("--- Test 5.2.1: Write 0 does not affect ---");
    
    // 设置中断标志，让bit0=1
    done_i = 1;
    @(posedge PCLK);
    #10;
    
    // 读取IRQ_STA，确认bit0=1
    apb_read(12'h010, read_data);
    $display("IRQ_STA when done_i=1: %h (bit0 should be 1)", read_data);
    
    // 清除done_i，避免继续设置中断标志
    done_i = 0;
    @(posedge PCLK);
    #10;
    
    // 写0到IRQ_STA，验证写0不影响bit0=1的状态
    apb_write(12'h010, 32'h00);  // 写0不影响
    @(posedge PCLK);
    #10;
    
    // 读取验证写0后bit0仍为1
    apb_read(12'h010, read_data);
    $display("IRQ_STA after writing 0 (bit0 should still be 1): %h", read_data);
    if (read_data[0] == 1) $display("✓ Write 0 does not affect IRQ_STA");
    else $display("✗ Write 0 incorrectly affected IRQ_STA");
    
    // 测试2: 写1清零
    $display("--- Test 5.2.2: Write 1 clears IRQ_STA ---");
    
    // 写1清零bit0
    apb_write(12'h010, 32'h01);  // 写1清零bit0
    @(posedge PCLK);
    #10;
    
    // 读取验证bit0被清零
    apb_read(12'h010, read_data);
    $display("IRQ_STA after writing 1 to bit0 (clear): %h", read_data);
    if (read_data[0] == 0) $display("✓ Write 1 cleared IRQ_STA bit0");
    else $display("✗ Write 1 failed to clear IRQ_STA bit0");
    
    // 测试3: irq_o时序测试
    $display("--- Test 5.3: irq_o timing ---");
    
    // 设置done_irq_en=1, done_i=1 -> irq_o应该为1
    done_i = 0;
    apb_write(12'h00C, 32'h01);  // enable done interrupt
    @(posedge PCLK);
    #10;
    done_i = 1;
    @(posedge PCLK);
    #10;
    $display("irq_o when done_i=1 and done_irq_en=1: %b", irq_o);
    if (irq_o == 1) $display("✓ irq_o=1 when done condition met");
    
    // 清除中断标志
    apb_write(12'h010, 32'h01);
    @(posedge PCLK);
    #10;
    
    // 设置error条件
    apb_write(12'h00C, 32'h02);  // enable error interrupt
    @(posedge PCLK);
    #10;
    length_error_i = 1;
    @(posedge PCLK);
    #10;
    $display("irq_o when length_error=1 and err_irq_en=1: %b", irq_o);
    if (irq_o == 1) $display("✓ irq_o=1 when error condition met");
    
    // 清除
    apb_write(12'h010, 32'h02);
    @(posedge PCLK);
    #10;
    length_error_i = 0;
    
    // 结束仿真
    #100;
    // 仅在命令行模式下结束仿真，图形界面模式下保持打开
    if ($test$plusargs("CMD_LINE")) begin
        $finish;
    end else begin
        $display("仿真完成，波形已生成。请在波形窗口中查看信号。");
        $display("按 Ctrl+C 或点击窗口关闭按钮退出。");
        // 无限循环，保持仿真运行
        forever begin
            #100;
        end
    end
  end
  
endmodule
