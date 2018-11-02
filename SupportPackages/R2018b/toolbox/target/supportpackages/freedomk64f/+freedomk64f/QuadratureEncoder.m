classdef (StrictDefaults)QuadratureEncoder <  matlab.System & ...
        coder.ExternalDependency ...
        & matlabshared.svd.BlockSampleTime & ...
        matlab.system.mixin.internal.CustomIcon & ...
        matlab.system.mixin.Propagates
    
    % quadratureEncoder
    % This class will be used to decode a quadrature encoder pulse
    %
    % Copyright 2016 The MathWorks, Inc.
    
    %#codegen
    %#ok<*EMCA>
    
    properties (Nontunable)
        % Encoding mode
        encodingMode =  'Quadrature';
        %Reset mode
        resetOption = 'No reset';
    end
    
    properties (Constant, Hidden)
        %Quadrature mode options
        encodingModeSet = matlab.system.StringSet({'Quadrature',...
            'Count and Direction'});
        %Encoder reset options
        resetOptionSet=matlab.system.StringSet({'No reset','Reset at each sample time',...
            'Reset by external signal'});
    end
    
    properties(Logical,Nontunable)
        % Invert Phase A polarity
        phaseAPol = false;
        % Invert Phase B polarity
        phaseBPol = false;
        % Output encoder direction
        outputDirection = true;
    end
    
    
    methods
        function obj = QuadratureEncoder(varargin)
            coder.allowpcode('plain');
            % Support name-value pair arguments
            setProperties(obj,nargin,varargin{:});
        end
    end
    
    
    methods (Static, Access = protected)
        
        function header = getHeaderImpl()
            header = matlab.system.display.Header(mfilename('class'),...
                'ShowSourceLink', false, ...
                'Title','NXP FRDM-K64F Board Quadrature Encoder', ...
                'Text', DAStudio.message('freedomk64f:blocks:QuadratureEncoderBlockDescription'));
        end
        
        function [groups,PropertyList] = getPropertyGroupsImpl
            
            % Sample time
            SampleTimeProp = matlab.system.display.internal.Property('SampleTime', 'Description', 'Sample time');
            
            % Property list
            PropertyListOut = {SampleTimeProp};
            
            % Create mask display
            generalGroup = matlab.system.display.Section(...
                'Title', 'Parameters', ...
                'PropertyList',{'encodingMode','outputDirection','resetOption',...
                'phaseAPol','phaseBPol',SampleTimeProp});
            
            groups = generalGroup;
            if nargout > 1
                PropertyList = PropertyListOut;
            end
        end
    end
    
    methods (Access=protected)
        function  setupImpl(obj,~)
            if coder.target('Rtw')% done only for code gen
                %'getQepMode' function converts the 'encodingMode' to a type of
                %'MW_QEP_MODE' enum
                mode_val = coder.const(@obj.getQepMode,obj.encodingMode);
                mode_val = coder.opaque('MW_QEP_MODE', mode_val);
                
                %'getPolarity' function converts the 'phaseAPol' and 'phaseBPol'
                % to a type of 'MW_POLARITY' enum
                
                pol_a_val = coder.const(@obj.getPolarity,obj.phaseAPol);
                pol_a_val = coder.opaque('MW_POLARITY', pol_a_val);
                
                pol_b_val = coder.const(@obj.getPolarity,obj.phaseBPol);
                pol_b_val = coder.opaque('MW_POLARITY', pol_b_val);
                
                coder.cinclude('MW_QEP.h');
                coder.ceval('MW_QEP_Init', mode_val, pol_a_val, pol_b_val);
                
            elseif ( coder.target('Sfun') )
                % do nothing in simulation
            end
        end
        
        function varargout = stepImpl(obj,varargin)
            count = int16(0);
            dir = uint8(0);
            ext_sig = int16(0);
            if coder.target('Rtw')% done only for code gen
                
                %'getResetMode' function converts the 'resetOption'
                % to a type of 'MW_RESET_MODE' enum
                reset_val = coder.const(@obj.getResetMode,obj.resetOption);
                reset_val = coder.opaque('MW_RESET_MODE', reset_val);
                
                % read counter value and direction
                coder.cinclude('MW_QEP.h');
                if (obj.getNumInputs ==1)
                    %No of Inputs is 1 when reset mode is Reset by external signal
                    ext_sig = int16(varargin{1});
                end
                count = coder.ceval('MW_QEP_CounterRead',reset_val,ext_sig);
                dir = coder.ceval('MW_QEP_DirectionRead');
                varargout{1} = count;
                if obj.outputDirection
                    varargout{2} = dir;
                end
            elseif  ( coder.target('Sfun') || coder.target('MATLAB') )
                % do nothing in simulation
                varargout{1} = count;
                if obj.outputDirection
                    varargout{2} = dir;
                end
            end
        end
        
        function releaseImpl(~)
            if coder.target('Rtw')% done only for code gen
                coder.cinclude('MW_QEP.h');
                % free dynamically allocated memory
                coder.ceval('MW_QEP_Terminate');
            elseif ( coder.target('Sfun') )
                % do nothing in simulation
            end
        end
        
    end
    
    %% Define input/output dimensions
    methods (Access=protected)
        
        function validateInputsImpl(~,varargin)
            if(~isempty(varargin))
                validateattributes(varargin{1}, {'numeric'}, ...
                    {'nonnan', 'finite', 'scalar', 'real'}, '', '');
            end
        end
        
        function num = getNumOutputsImpl(obj)
            if obj.outputDirection
                num = 2;
            else
                num = 1;
            end
        end
        
        function flag = isInactivePropertyImpl(obj,prop)
            % Return false if property is visible based on object
            % configuration, for the command line and System block dialog
            
            if isequal(prop,'SampleTime') && isequal(obj.resetOption,'Reset by external signal')
                %Hide the SampleTime parameter when 'Reset by external
                %signal' mode is chosen
                flag = true;
            else
                flag = false;
            end
        end
        
        function num = getNumInputsImpl(obj)
            if (isequal(obj.resetOption,'Reset by external signal'))
                %Grow an input port when 'Reset by external signal' mode is
                %chosen
                num = 1;
            else
                num = 0;
            end
        end
        
        function varargout = getInputNamesImpl(obj)
            if (obj.getNumInputs==1)
                varargout{1}='Rst';
            end
        end
        
        function varargout = getOutputDataTypeImpl(obj)
            varargout{1} = 'int16';
            if obj.outputDirection
                varargout{2} = 'uint8';
            end
        end
        
        function varargout = getOutputSizeImpl(obj)
            varargout{1} = [1 1];
            if obj.outputDirection
                varargout{2} = [1 1];
            end
        end
        
        % Names of System block output ports
        function varargout = getOutputNamesImpl(obj)
            varargout{1} = 'Tick';
            if obj.outputDirection
                varargout{2} = 'Dir';
            end
        end
        
        function flag = isOutputComplexityLockedImpl(~,~)
            flag = true;
        end
        
        function flag = isOutputSizeLockedImpl(~,~)
            flag = true;
        end
        
        function varargout = isOutputFixedSizeImpl(obj)
            for i = 1:getNumOutputsImpl(obj)
                varargout{i} = true;
            end
        end
        
        function varargout = isOutputComplexImpl(obj)
            for i = 1:getNumOutputsImpl(obj)
                varargout{i} = false;
            end
        end
        
        function maskDisplayCmds = getMaskDisplayImpl(obj)
            
            outport_label = [];
            num=getNumOutputs(obj);
            if(num >0)
                outputs = getOutputNames(obj);
                for i = 1:num
                    outport_label = [outport_label 'port_label(''output'',' num2str(i) ',''' outputs{i} ''');' newline]; %#ok<AGROW>
                end
            end
            
            maskDisplayCmds = [ ...
                ['color(''white'');',newline]...
                ['plot([100,100,100,100]*1,[100,100,100,100]*1);',newline]...
                ['plot([100,100,100,100]*0,[100,100,100,100]*0);',newline]...
                ['color(''blue'');',newline] ...
                ['text(99, 92, '' FRDM-K64F '', ''horizontalAlignment'', ''right'');',newline]  ...
                ['color(''black'');',newline]...
                ['sppkgroot = strrep(codertarget.freedomk64f.internal.getSpPkgRootDir(),''\'',''/'');',newline]...
                ['image(fullfile(sppkgroot,''resources'',''encoder.jpg''),''center'')',newline]...
                outport_label];
        end
    end
    %%
    methods (Static, Access=protected)
        function simMode = getSimulateUsingImpl(~)
            simMode = 'Interpreted execution';
        end
        
        function isVisible = showSimulateUsingImpl
            isVisible = false;
        end
    end
    
    %% Methods of coder.ExternalDependency
    methods (Static)
        
        function name = getDescriptiveName(~)
            name = 'Quadrature Encoder';
        end
        
        function b = isSupportedContext(context)
            b = context.isCodeGenTarget('rtw');
        end
        
        % Update the build-time buildInfo
        function updateBuildInfo(buildInfo, context)
            if context.isCodeGenTarget('rtw')
                sppkgroot = strrep(codertarget.freedomk64f.internal.getSpPkgRootDir(),'\','/');
                addIncludePaths(buildInfo,fullfile(sppkgroot,'include'));
                buildInfo.addIncludeFiles({'MW_QEP.h'});
                isRaccelBuild = strcmp(context.getConfigProp('SystemTargetFile'), 'raccel.tlc');
                if ~isRaccelBuild
                    buildInfo.addSourceFiles( {'MW_QEP.c','mw_sdk_interface.c'},fullfile(sppkgroot,'src'));
                end
            end
        end
    end
    
    %% Helper Functions
    methods (Static, Access=protected)
        function QepModeValue = getQepMode(QepMode)
            coder.inline('always');
            switch QepMode
                case 'Quadrature'
                    QepModeValue = 'QUADRATURE_ENCODING_MODE';
                case 'Count and Direction'
                    QepModeValue = 'COUNT_AND_DIRECTION_MODE';
                otherwise
                    QepModeValue = 'QUADRATURE_ENCODING_MODE';
            end
        end
        
        function PolarityValue = getPolarity(Polarity)
            coder.inline('always');
            switch Polarity
                case 0
                    PolarityValue = 'NORMAL_POLARITY';
                case 1
                    PolarityValue = 'INVERTED_POLARITY';
                otherwise
                    PolarityValue = 'NORMAL_POLARITY';
            end
        end
        
        function ResetModeValue = getResetMode(ResetMode)
            coder.inline('always');
            switch ResetMode
                case 'No reset'
                    ResetModeValue = 'NO_RESET';
                case 'Reset at each sample time'
                    ResetModeValue = 'SAMPLE_TIME_RESET';
                case 'Reset by external signal'
                    ResetModeValue = 'EXT_SIGNAL_RESET';
                otherwise
                    ResetModeValue = 'NO_RESET';
            end
        end
        
    end
    
    methods (Access=protected)
        function st = getSampleTimeImpl(obj)
            if (obj.getNumInputs ==1)
                %When the block has an input port, the sample time is
                %defined by the block connected to the input port.
                st = -1;
            else
                st =  obj.SampleTime;
            end
        end
      end
    
end
