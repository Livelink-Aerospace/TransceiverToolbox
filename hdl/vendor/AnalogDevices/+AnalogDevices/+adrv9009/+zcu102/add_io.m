function add_io(hRD,type)

% add AXI4 and AXI4-Lite slave interfaces
% hRD.addAXI4SlaveInterface( ...
%     'InterfaceConnection', 'axi_cpu_interconnect/M13_AXI', ... % ADC DMA BUS
%     'BaseAddress',         '0x43C00000', ...
%     'MasterAddressSpace',  'sys_ps8/Data');
hRD.addAXI4SlaveInterface( ...
    'InterfaceConnection', 'axi_cpu_interconnect/M16_AXI', ... % ADC DMA BUS
    'BaseAddress',         '0x9D000000', ...
    'MasterAddressSpace',  'sys_ps8/Data');


% Reference design interfaces
if contains(lower(type),'rx')
    
    hRD.addInternalIOInterface( ...
        'InterfaceID',    'IP Data Valid OUT', ...
        'InterfaceType',  'OUT', ...
        'PortName',       'dut_data_valid', ...
        'PortWidth',      1, ...
        'InterfaceConnection', 'util_adrv9009_rx_cpack/fifo_wr_en', ...
        'IsRequired',     false);
    
    hRD.addInternalIOInterface( ...
        'InterfaceID',    'IP Valid Rx Data IN', ...
        'InterfaceType',  'IN', ...
        'PortName',       'rx_adrv9009_tpl_core_adc_valid_0', ...
        'PortWidth',      1, ...
        'InterfaceConnection', 'rx_adrv9009_tpl_core/adc_valid_0', ...
        'IsRequired',     false);
    
    hRD.addInternalIOInterface( ...
        'InterfaceID',    'IP Data 0 OUT', ...
        'InterfaceType',  'OUT', ...
        'PortName',       'dut_data_0', ...
        'PortWidth',      16, ...
        'InterfaceConnection', 'util_adrv9009_rx_cpack/fifo_wr_data_0', ...
        'IsRequired',     false);
    
    hRD.addInternalIOInterface( ...
        'InterfaceID',    'IP Data 1 OUT', ...
        'InterfaceType',  'OUT', ...
        'PortName',       'dut_data_1', ...
        'PortWidth',      16, ...
        'InterfaceConnection', 'util_adrv9009_rx_cpack/fifo_wr_data_1', ...
        'IsRequired',     false);
    
    hRD.addInternalIOInterface( ...
        'InterfaceID',    'IP Data 2 OUT', ...
        'InterfaceType',  'OUT', ...
        'PortName',       'dut_data_2', ...
        'PortWidth',      16, ...
        'InterfaceConnection', 'util_adrv9009_rx_cpack/fifo_wr_data_2', ...
        'IsRequired',     false);
    
    hRD.addInternalIOInterface( ...
        'InterfaceID',    'IP Data 3 OUT', ...
        'InterfaceType',  'OUT', ...
        'PortName',       'dut_data_3', ...
        'PortWidth',      16, ...
        'InterfaceConnection', 'util_adrv9009_rx_cpack/fifo_wr_data_3', ...
        'IsRequired',     false);
    %% INPUTS axi_adrv9009_v1_0
    hRD.addInternalIOInterface( ...
        'InterfaceID',    'ADRV9009 ADC Data I0', ...
        'InterfaceType',  'IN', ...
        'PortName',       'sys_wfifo_0_dma_wdata', ...
        'PortWidth',      16, ...
        'InterfaceConnection', 'rx_adrv9009_tpl_core/adc_data_0', ...
        'IsRequired',     false);
    
    hRD.addInternalIOInterface( ...
        'InterfaceID',    'ADRV9009 ADC Data Q0', ...
        'InterfaceType',  'IN', ...
        'PortName',       'sys_wfifo_1_dma_wdata', ...
        'PortWidth',      16, ...
        'InterfaceConnection', 'rx_adrv9009_tpl_core/adc_data_1', ...
        'IsRequired',     false);
    
    hRD.addInternalIOInterface( ...
        'InterfaceID',    'ADRV9009 ADC Data I1', ...
        'InterfaceType',  'IN', ...
        'PortName',       'sys_wfifo_2_dma_wdata', ...
        'PortWidth',      16, ...
        'InterfaceConnection', 'rx_adrv9009_tpl_core/adc_data_2', ...
        'IsRequired',     false);
    
    hRD.addInternalIOInterface( ...
        'InterfaceID',    'ADRV9009 ADC Data Q1', ...
        'InterfaceType',  'IN', ...
        'PortName',       'sys_wfifo_3_dma_wdata', ...
        'PortWidth',      16, ...
        'InterfaceConnection', 'rx_adrv9009_tpl_core/adc_data_3', ...
        'IsRequired',     false);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% TX IO
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if contains(lower(type),'tx')
    % Reference design interfaces
    % Outputs from generated IP to ADRV9009
    
    hRD.addInternalIOInterface( ...
        'InterfaceID',    'IP Valid Tx Data IN', ...
        'InterfaceType',  'IN', ...
        'PortName',       'dut_tx_data_valid_in', ...
        'PortWidth',      1, ...
        'InterfaceConnection', 'util_adrv9009_tx_upack/fifo_rd_valid', ...
        'IsRequired',     false);
    
    hRD.addInternalIOInterface( ...
        'InterfaceID',    'IP Load Tx Data OUT', ...
        'InterfaceType',  'OUT', ...
        'PortName',       'dut_tx_data_valid_out', ...
        'PortWidth',      1, ...
        'InterfaceConnection', 'util_adrv9009_tx_upack/fifo_rd_en', ...
        'IsRequired',     false);
    
    hRD.addInternalIOInterface( ...
        'InterfaceID',    'ADRV9009 DAC Data I0', ...
        'InterfaceType',  'OUT', ...
        'PortName',       'axi_adrv9009_dac_data_i0', ...
        'PortWidth',      32, ...
        'InterfaceConnection', 'tx_adrv9009_tpl_core/dac_data_0', ...
        'IsRequired',     false);
    
    hRD.addInternalIOInterface( ...
        'InterfaceID',    'ADRV9009 DAC Data Q0', ...
        'InterfaceType',  'OUT', ...
        'PortName',       'axi_adrv9009_dac_data_q0', ...
        'PortWidth',      32, ...
        'InterfaceConnection', 'tx_adrv9009_tpl_core/dac_data_1', ...
        'IsRequired',     false);
    
    hRD.addInternalIOInterface( ...
        'InterfaceID',    'ADRV9009 DAC Data I1', ...
        'InterfaceType',  'OUT', ...
        'PortName',       'axi_adrv9009_dac_data_i1', ...
        'PortWidth',      32, ...
        'InterfaceConnection', 'tx_adrv9009_tpl_core/dac_data_2', ...
        'IsRequired',     false);
    
    hRD.addInternalIOInterface( ...
        'InterfaceID',    'ADRV9009 DAC Data Q1', ...
        'InterfaceType',  'OUT', ...
        'PortName',       'axi_adrv9009_dac_data_q1', ...
        'PortWidth',      32, ...
        'InterfaceConnection', 'tx_adrv9009_tpl_core/dac_data_3', ...
        'IsRequired',     false);
    
    % Inputs to generated IP from upack core
    hRD.addInternalIOInterface( ...
        'InterfaceID',    'IP Data 0 IN', ...
        'InterfaceType',  'IN', ...
        'PortName',       'util_dac_unpack_dac_data_00', ...
        'PortWidth',      32, ...
        'InterfaceConnection', 'util_adrv9009_tx_upack/fifo_rd_data_0', ...
        'IsRequired',     false);
    
    hRD.addInternalIOInterface( ...
        'InterfaceID',    'IP Data 1 IN', ...
        'InterfaceType',  'IN', ...
        'PortName',       'util_dac_unpack_dac_data_01', ...
        'PortWidth',      32, ...
        'InterfaceConnection', 'util_adrv9009_tx_upack/fifo_rd_data_1', ...
        'IsRequired',     false);
    
    hRD.addInternalIOInterface( ...
        'InterfaceID',    'IP Data 2 IN', ...
        'InterfaceType',  'IN', ...
        'PortName',       'util_dac_unpack_dac_data_02', ...
        'PortWidth',      32, ...
        'InterfaceConnection', 'util_adrv9009_tx_upack/fifo_rd_data_2', ...
        'IsRequired',     false);
    
    hRD.addInternalIOInterface( ...
        'InterfaceID',    'IP Data 3 IN', ...
        'InterfaceType',  'IN', ...
        'PortName',       'util_dac_unpack_dac_data_03', ...
        'PortWidth',      32, ...
        'InterfaceConnection', 'util_adrv9009_tx_upack/fifo_rd_data_3', ...
        'IsRequired',     false);
end
