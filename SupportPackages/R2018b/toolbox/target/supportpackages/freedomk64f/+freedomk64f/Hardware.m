classdef Hardware < handle
    %Hardware Hardware base for NXP FRDM-K64F board
    %
    
    % Copyright 2015-2016 The MathWorks, Inc.
    
    %#codegen
    properties (Constant)
        AvailableDigitalPin = [0:21,27:35,37,42:46];
        AvailablePWMPin     = [3, 5, 6, 7, 8, 9, 10, 11, 12, 13, 20, 21];
        AvailableAnalogPin  = [16:26,38:41,47];
        MinimumPWMFrequency = 916;     % Minimum range of frequency - Non-list
        MaximumPWMFrequency = 15e6;   % Maximum range of frequency - Non-list
        Pinnames = {'PTC16 (D0)', 'PTC17 (D1)', 'PTB9 (D2)', 'PTA1 (D3)', 'PTB23 (D4)', 'PTA2 (D5)', 'PTC2 (D6)', 'PTC3 (D7)', 'PTA0 (D8)', 'PTC4 (D9)', 'PTD0 (D10)', ...
            'PTD2 (D11)', 'PTD3 (D12)', 'PTD1 (D13)', 'PTE25 (D14)', 'PTE24 (D15)', 'PTB2 (A0)', 'PTB3 (A1)', 'PTB10 (A2)', 'PTB11 (A3)', 'PTC11 (A4)', 'PTC10 (A5)' ...
            'ADC1_SE18', 'ADC1_DM0', 'ADC1_DP0', 'ADC0_DM0', 'ADC0_DP0', 'PTE26', 'PTC5', 'PTC7',  'PTC0', 'PTC9', 'PTC8', 'PTC1', 'PTB19','PTB18','DAC0_OUT','PTB20', 'ADC1_DM1', 'ADC1_DP1','ADC0_DM1','ADC0_DP1', ...
            'RED_LED', 'GREEN_LED', 'BLUE_LED', 'SW2', 'SW3', 'DAC0_OUT'};
        AvailableI2CModule = [0 1];
        AvailableI2CModuleNames = {'0','1'};        
        AvailableSCINumbers  = [0 1 2 3];
        AvailableSCINames  = {'0','1','2', '3'};
    end
    
    properties (Constant, Hidden)
        AvailablePinNames = {'PTC16','PTC17','PTB9','PTA1','PTB23','PTA2','PTC2', ...
            'PTC3','PTA0','PTC4','PTD0','PTD2','PTD3','PTD1','PTE25','PTE24',...
            'PTB2','PTB3','PTB10','PTB11','PTC11','PTC10','ADC1_SE18','ADC1_DM0',...
            'ADC1_DP0','ADC0_DM0','ADC0_DP0','PTE26','PTC5','PTC7','PTC0','PTC9',...
            'PTC8','PTC1','PTB19','PTB18','DAC0_OUT','PTB20','ADC1_DM1','ADC1_DP1',...
            'ADC0_DM1','ADC0_DP1','RED_LED','GREEN_LED','BLUE_LED','SW2', 'SW3','DAC0_OUT'};
        
    end
    
    %#codegen
    methods
        % Digital I/O interface
        function ret = getDigitalPinName(obj,pinNumber)
            if nargin < 2
                ret = obj.AvailablePinNames(obj.AvailableDigitalPin+1);
            else
                ret = obj.AvailablePinNames{pinNumber+1};
            end
        end
        
        function ret = isValidDigitalPin(obj, pin)
            if isnumeric(pin)
                ret = (ismember(pin,obj.AvailableDigitalPin)~=0);
            else
                pinNumber = getDigitalPinNumber(obj,pin);
                ret = (ismember(pinNumber,obj.AvailableDigitalPin)~=0);
            end
        end
        
        function ret = getDigitalPinNumber(obj,pinName)
            if nargin < 2
                ret = obj.AvailableDigitalPin;
            else
                for i = 1:numel(obj.AvailablePinNames)
                    if isequal(obj.AvailablePinNames{i},pinName)
                        ret = i-1;
                        return;
                    else
                        ret = obj.AvailableDigitalPin(1);
                    end
                end
            end
        end
        
        % Analog input interface
        function ret = getAnalogPinName(obj,pinNumber)
            if nargin < 2
                ret = obj.AvailablePinNames(obj.AvailableAnalogPin+1);
            else
                ret = obj.AvailablePinNames{pinNumber+1};
            end
        end
        
        function ret = isValidAnalogPin(obj, pin)
            if isnumeric(pin)
                ret = (ismember(pin,obj.AvailableAnalogPin)~=0);
            else
                pinNumber = getAnalogPinNumber(obj,pin);
                ret = (ismember(pinNumber,obj.AvailableAnalogPin)~=0);
            end
        end
        
        function ret = getAnalogPinNumber(obj,pinName)
            if nargin < 2
                ret = obj.AvailableAnalogPin;
            else
                for i = 1:numel(obj.AvailablePinNames)
                    if isequal(obj.AvailablePinNames{i},pinName)
                        ret = obj.AvailableAnalogPin(obj.AvailableAnalogPin == (i-1));
                        return;
                    else
                        ret = obj.AvailableAnalogPin(1);
                    end
                end
            end
        end
        
        % PWM interface
        function ret = getPWMPinName(obj,pinNumber)
            if nargin < 2
                ret = obj.AvailablePinNames(obj.AvailablePWMPin+1);
            else
                ret = obj.AvailablePinNames{pinNumber+1};
            end
        end
        
        function ret = isValidPWMPin(obj, pin)
            if isnumeric(pin)
                ret = (ismember(pin,obj.AvailablePWMPin)~=0);
            else
                pinNumber = getPWMPinNumber(obj,pin);
                ret = (ismember(pinNumber,obj.AvailablePWMPin)~=0);
            end
        end
        
        function ret = getPWMPinNumber(obj,pinName)
            if nargin < 2
                ret = obj.AvailablePWMPin;
            else
                for i = 1:numel(obj.AvailablePinNames)
                    if isequal(obj.AvailablePinNames{i},pinName)
                        ret = i-1;
                        return;
                    else
                        ret = obj.AvailablePWMPin(1);
                    end
                end
            end
        end
        
        function ret = getMinimumPWMFrequency(obj)
            ret = obj.MinimumPWMFrequency;
        end
        
        function ret = getMaximumPWMFrequency(obj)
            ret = obj.MaximumPWMFrequency;
        end
        
        % I2C interface
        function ret = getI2CModuleName(obj,i2cNumber)
            if nargin < 2
                ret = obj.AvailableI2CModuleNames;
            else
                ret = obj.AvailableI2CModuleNames{i2cNumber == obj.AvailableI2CModule};
            end
        end
        
        function ret = isValidI2CModule(obj, i2cModule)
            if isnumeric(i2cModule)
                ret = (ismember(i2cModule,obj.AvailableI2CModule)~=0);
            else
                i2cNumber = getI2CModuleNumber(obj,i2cModule);
                ret = (ismember(i2cNumber,obj.AvailableI2CModule)~=0);
            end            
        end
        
        function ret = getI2CModuleNumber(obj,I2CModuelName)
            if nargin < 2
                ret = obj.AvailableI2CModule;
            else
                for i = 1:numel(obj.AvailableI2CModuleNames)
                    if isequal(obj.AvailableI2CModuleNames{i},I2CModuelName)
                        ret = obj.AvailableI2CModule(i);
                        return;
                    end
                end
                % Not found, hence error
                error('%s not found',I2CModuelName);
            end
        end

        function ret = getI2CBusSpeedInHz(~, ~)
            ret = 100000; %100KHz.
        end
        
        function ret = getI2CMaximumBusSpeedInHz(~, ~)
            ret = 400000;%KHz
        end
        function ret = getI2CMaxAllowedAddressBits(~, ~)
            ret = 7; %
        end
        
        % SCI interface
        % Get SCI module name based on the identifier
        function ret = getSCIModuleName(obj,SCINumber)
            if nargin < 2
                ret = obj.AvailableSCINames(obj.AvailableSCINumbers+1);
            else
                ret = obj.AvailableSCINames{ismember(obj.AvailableSCINumbers, SCINumber)};
            end
        end
        % Validate is the SCI module available for the hardware
        function ret = isValidSCIModule(obj, SCIModule)
            if isnumeric(SCIModule)
                ret = (ismember(SCIModule,obj.AvailableSCINumbers)~=0);
            else
                SCINumber = getSCIModuleNumber(obj,SCIModule);
                if isempty(SCINumber)
                    ret = false;
                else
                    ret = (ismember(SCINumber,obj.AvailableSCINumbers)~=0);
                end
            end
        end
        % Get the SCI module identifier from the name
        function ret = getSCIModuleNumber(obj,SCIName)
            if nargin < 2
                ret = obj.AvailableSCINumbers;
            else
                for i = coder.unroll(1:numel(obj.AvailableSCINames))
                    if isequal(obj.AvailableSCINames{i},SCIName)
                        ret = obj.AvailableSCINumbers(i);
                        return;
                    else
                        %ret = obj.AvailableSCINumbers(1);
                        ret = [];
                    end
                end
            end
        end
        % SCI module to consider as string
        % Linux based targets like Raspi are having virtual SCI.
        % In this case, the SCI ports has to be opened with names.
        % Retruning true from this functions sends a string to
        % underlying C/C++ function to open the port
        function ret = getSCIModuleNameIsString(~)
            ret = false;
        end
        % Get the SCI recevie pin name
        function ret = getSCIReceivePin(~,~)
                ret = 10;
        end
        % Get the SCI transmit Pin name
        function ret = getSCITransmitPin(~,~)
                ret = 10;
        end
        % Get SCI bus speed
        function ret = getSCIBaudrate(~, ~)
            ret = 115200;
        end
        % Get the maximum allowed bus speed
        function ret = getSCIMaximumBaudrate(~, ~)
            ret = 115200*4;
        end
        % Get the parity
        function ret = getSCIParity(~, ~)
            ret = matlabshared.svd.SCI.PARITY_NONE;
        end
        % Get the stop bits
        function ret = getSCIStopBits(~, ~)
            ret = matlabshared.svd.SCI.STOPBITS_1;
        end
        
        function ret = getSCIDataBits(~,~)
            ret = matlabshared.svd.SCI.DATABITS_8;
        end
        function ret = getSCIByteOrder(~,~)
            ret = false;
        end
        % Frame parameters visibility
        % true - visible
        % false - invisible
        function ret = getSCIParametersVisibility(~, ~)
            ret = false;
        end
        % RTS or DTR pins for hardware flow control
        function ret = getSCIRtsDtrPin(~, ~)
            ret = 4;
        end
        % CTS or DSR pins for hardware flow control
        function ret = getSCICtsDsrPin(~, ~)
            ret = 6;
        end
        % Define Hardware flow control type
        function ret = getSCIHardwareFlowControl(~,~)
            ret = matlabshared.svd.SCI.FLOWCONTROL_NONE;
        end
    end
end

