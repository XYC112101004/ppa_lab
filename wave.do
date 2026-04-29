onerror {resume}
quietly WaveActivateNextPane {} 0

add wave -noupdate -divider {Clock and Reset}
add wave -noupdate /tb/PCLK
add wave -noupdate /tb/PRESETn

add wave -noupdate -divider {APB Interface}
add wave -noupdate /tb/PSEL
add wave -noupdate /tb/PENABLE
add wave -noupdate /tb/PWRITE
add wave -noupdate /tb/PADDR
add wave -noupdate /tb/PWDATA
add wave -noupdate /tb/PRDATA
add wave -noupdate /tb/PREADY
add wave -noupdate /tb/PSLVERR

add wave -noupdate -divider {Control Outputs}
add wave -noupdate /tb/enable_o
add wave -noupdate /tb/start_o
add wave -noupdate /tb/algo_mode_o
add wave -noupdate /tb/type_mask_o
add wave -noupdate /tb/exp_pkt_len_o
add wave -noupdate /tb/done_irq_en_o
add wave -noupdate /tb/err_irq_en_o

add wave -noupdate -divider {SRAM Write Port}
add wave -noupdate /tb/pkt_mem_we_o
add wave -noupdate /tb/pkt_mem_addr_o
add wave -noupdate /tb/pkt_mem_wdata_o

add wave -noupdate -divider {Status Inputs}
add wave -noupdate /tb/busy_i
add wave -noupdate /tb/done_i
add wave -noupdate /tb/format_ok_i
add wave -noupdate /tb/length_error_i
add wave -noupdate /tb/type_error_i
add wave -noupdate /tb/chk_error_i
add wave -noupdate /tb/res_pkt_len_i
add wave -noupdate /tb/res_pkt_type_i
add wave -noupdate /tb/res_payload_sum_i
add wave -noupdate /tb/res_payload_xor_i

add wave -noupdate -divider {Interrupt}
add wave -noupdate /tb/irq_o

add wave -noupdate -divider {SRAM Read}
add wave -noupdate /tb/sram_rd_data

add wave -noupdate -divider {APB Slave IF Instance}
add wave -noupdate /tb/u_apb_slave_if/PCLK
add wave -noupdate /tb/u_apb_slave_if/PRESETn
add wave -noupdate /tb/u_apb_slave_if/PSEL
add wave -noupdate /tb/u_apb_slave_if/PENABLE
add wave -noupdate /tb/u_apb_slave_if/PWRITE
add wave -noupdate /tb/u_apb_slave_if/PADDR
add wave -noupdate /tb/u_apb_slave_if/PWDATA
add wave -noupdate /tb/u_apb_slave_if/PRDATA
add wave -noupdate /tb/u_apb_slave_if/PREADY
add wave -noupdate /tb/u_apb_slave_if/PSLVERR
add wave -noupdate /tb/u_apb_slave_if/enable_o
add wave -noupdate /tb/u_apb_slave_if/start_o
add wave -noupdate /tb/u_apb_slave_if/algo_mode_o
add wave -noupdate /tb/u_apb_slave_if/type_mask_o
add wave -noupdate /tb/u_apb_slave_if/exp_pkt_len_o
add wave -noupdate /tb/u_apb_slave_if/done_irq_en_o
add wave -noupdate /tb/u_apb_slave_if/err_irq_en_o
add wave -noupdate /tb/u_apb_slave_if/pkt_mem_we_o
add wave -noupdate /tb/u_apb_slave_if/pkt_mem_addr_o
add wave -noupdate /tb/u_apb_slave_if/pkt_mem_wdata_o
add wave -noupdate /tb/u_apb_slave_if/busy_i
add wave -noupdate /tb/u_apb_slave_if/done_i
add wave -noupdate /tb/u_apb_slave_if/format_ok_i
add wave -noupdate /tb/u_apb_slave_if/length_error_i
add wave -noupdate /tb/u_apb_slave_if/type_error_i
add wave -noupdate /tb/u_apb_slave_if/chk_error_i
add wave -noupdate /tb/u_apb_slave_if/res_pkt_len_i
add wave -noupdate /tb/u_apb_slave_if/res_pkt_type_i
add wave -noupdate /tb/u_apb_slave_if/res_payload_sum_i
add wave -noupdate /tb/u_apb_slave_if/res_payload_xor_i
add wave -noupdate /tb/u_apb_slave_if/irq_o

add wave -noupdate -divider {Packet SRAM Instance}
add wave -noupdate /tb/u_packet_sram/clk
add wave -noupdate /tb/u_packet_sram/rst_n
add wave -noupdate /tb/u_packet_sram/wr_en
add wave -noupdate /tb/u_packet_sram/wr_addr
add wave -noupdate /tb/u_packet_sram/wr_data
add wave -noupdate /tb/u_packet_sram/rd_en
add wave -noupdate /tb/u_packet_sram/rd_addr
add wave -noupdate /tb/u_packet_sram/rd_data

TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 300
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
run -all