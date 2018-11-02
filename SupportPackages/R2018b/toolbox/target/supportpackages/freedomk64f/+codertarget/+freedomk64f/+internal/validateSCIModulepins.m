function validateSCIModulepins(current_block, varargin)
%validateUARTpins Check if the Digital Pins used by SCI Read/Write, I2C Read/Write and PWM blocks have been used with External Mode.

% Copyright 2016 The MathWorks, Inc.

current_model = codertarget.utils.getModelForBlock(current_block);
targetdata = get_param(current_model, 'CoderTargetData');
simmode = get_param(current_model,'SimulationMode');
ExtMode_UART = targetdata.ExtMode.UART;
BlockType = get_param(current_block,'MaskType');
scimodules = {'0','1','2','3'};

switch BlockType
    %For the Serial Rx/Tx blocks, the UART module conflict with Ext
    %Mode/PIL is also checked.
    case {'freedomk64f.SCIRead','freedomk64f.SCIWrite'}
        
        scimodulenum = get_param(current_block, 'SCIModule');
        [~,index] = ismember(scimodulenum,scimodules);
        
        % Check conflict of UART module used in Serial Rx/Tx block with External Mode
        if strcmp(simmode,'external') && strcmp(scimodules{index},scimodules{ExtMode_UART+1})
            error(message('freedomk64f:blocks:ExternalModeUARTConflict',ExtMode_UART,current_block));
        end
        
        
    case {'I2C Master Write','I2C Master Read'}
        %This case is used for I2C blocks because, the number
        %of GPIO pins used is more than 1
        [r,~]=size(varargin{1});
        
        % Check conflict of the block with External Mode
        if strcmp(simmode,'external')
            for j=1:r
                if any(strcmp(varargin{1}{j},{targetdata.(['UART' scimodules{ExtMode_UART+1}]).Rx_PinSelection,targetdata.(scimodules{ExtMode_UART+1}).Tx_PinSelection}))
                    error(message('freedomk64f:blocks:GPIOUartConflict',varargin{1}{j},current_block,scimodules{ExtMode_UART+1},'External Mode'));
                end
            end
        end
        
    otherwise
        
        % Check conflict of the block with External Mode
        if strcmp(simmode,'external')
            
            %This is used to extract PTA1 from PTA1(USBRX)
            RX_pin = targetdata.(['UART' scimodules{ExtMode_UART+1}]).Rx_PinSelection;
            %RX_pin = strsplit(RX_pin);
            %RX_pin=RX_pin{1};
            
            %This is used to extract PTA2 from PTA2(USBTX)
            TX_pin = targetdata.(['UART' scimodules{ExtMode_UART+1}]).Tx_PinSelection;
            %TX_pin = strsplit(TX_pin);
            %TX_pin=TX_pin{1};
            
            if any(strcmp(varargin{1},{RX_pin,TX_pin}))
                error(message('freedomk64f:blocks:GPIOUartConflict',varargin{1},current_block,['UART' scimodules{ExtMode_UART+1}],'External Mode'));
            end
        end
        
end
end