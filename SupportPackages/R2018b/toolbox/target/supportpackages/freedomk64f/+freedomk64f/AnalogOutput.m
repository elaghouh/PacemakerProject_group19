classdef (StrictDefaults)AnalogOutput <  matlab.System & ...
        matlab.system.mixin.Propagates & ...
        matlabshared.svd.BlockSampleTime & ...
        matlab.system.mixin.internal.CustomIcon & ...
        coder.ExternalDependency
    % analogOut
    % This class will be used to send an analog value to an analog pin on
    % the FRDM-K64F board.
    %
    % Copyright 2016 The MathWorks, Inc.

    %#codegen
    %#ok<*EMCA>

    methods
        function obj = AnalogOutput(varargin)
            coder.allowpcode('plain');
            % Support name-value pair arguments
            setProperties(obj,nargin,varargin{:}, 'Length');
         end
    end

    methods (Access=protected)
        
        function validateInputsImpl(~,dataInput) %#ok<*INUSD>
            validateattributes(dataInput, {'numeric'}, ...
                {'real', 'nonnegative', 'integer', 'scalar', ...
                'finite','nonnan'}, '', '');
        end
        
        function setupImpl(~,~)
            if coder.target('Rtw')% done only for code gen
                coder.cinclude('MW_AnalogOut.h');
                % initialize the pin
                coder.ceval('MW_AnalogOutput_Init',0);
            elseif ( coder.target('Sfun') )
                % do nothing in simulation
            end
        end

        function stepImpl(~, pinValue)
            if coder.target('Rtw')% done only for code gen
                coder.cinclude('MW_AnalogOut.h');
                % write analog value (0 - 1) to pin
                coder.ceval('MW_AnalogOutput_Write', 0, uint16(pinValue*4095));
            elseif ( coder.target('Sfun') )
                % do nothing in simulation
            end
        end

        function releaseImpl(~)
            if coder.target('Rtw')% done only for code gen
                coder.cinclude('MW_AnalogOut.h');
                % free dynamically allocated memory
                coder.ceval('MW_AnalogOutput_Terminate');
            elseif ( coder.target('Sfun') )
                % do nothing in simulation
            end
        end
    end
    
    methods (Static)
        function name = getDescriptiveName()
            name = 'NXP FRDM-K64F Board Analog Output';
        end
        
        function b = isSupportedContext(context)
            b = context.isCodeGenTarget('rtw');
        end
        
        % Update the build-time buildInfo
        function updateBuildInfo(buildInfo, context)
            if context.isCodeGenTarget('rtw')
                sppkgroot = strrep(codertarget.freedomk64f.internal.getSpPkgRootDir(),'\','/');
                isRaccelBuild = strcmp(context.getConfigProp('SystemTargetFile'), 'raccel.tlc');
                if ~isRaccelBuild
                buildInfo.addSourceFiles( {'MW_AnalogOutput.c','mw_sdk_interface.c'},fullfile(sppkgroot,'src'));
                end
                addIncludePaths(buildInfo,fullfile(sppkgroot,'include'));
                addIncludeFiles(buildInfo,'MW_AnalogOut.h');
            end
        end
    end
    
    methods(Access = protected, Static)
        function simMode = getSimulateUsingImpl
            % Return only allowed simulation mode in System block dialog
            simMode = 'Interpreted execution';
        end
        
        function flag = showSimulateUsingImpl
            % Return false if simulation mode hidden in System block dialog
            flag = false;
        end
        
        function header = getHeaderImpl()
            header = matlab.system.display.Header(mfilename('class'),...
                'ShowSourceLink', false, ...
                'Title','NXP FRDM-K64F Board Analog Output', ...
                'Text', ['Send an analog output signal to DAC0_OUT pin.' newline newline ...
                'The block input accepts decimal values between 0 to 1.' newline newline ...
                'The block output emits an analog signal of voltage Vout, where Vout=Vref*(1+input*4095)/4096']);
        end
    end
    
    methods (Access = protected)
        
        function maskDisplayCmds = getMaskDisplayImpl(obj) %#ok<MANU>
            maskDisplayCmds = { ...
                'color(''white'');',...                                     % Fix min and max x,y co-ordinates for autoscale mask units
                'plot([100,100,100,100]*1,[100,100,100,100]*1);',...
                'plot([100,100,100,100]*0,[100,100,100,100]*0);',...
                'color(''blue'');', ...                                     % Drawing mask layout of the block
                ['text(99, 92, ''' 'FRDM-K64F' ''', ''horizontalAlignment'', ''right'');'],   ...
                'color(''black'');',...
                'plot([30:70],(sin(2*pi*[0.25:0.01:0.65]*(-5))+1)*15+35)', ...
                ['text(50, 15,' ['''Pin: '  'DAC0_OUT' ''',''horizontalAlignment'', ''center'');' newline] ...
                ]};
        end           
    end    
end
