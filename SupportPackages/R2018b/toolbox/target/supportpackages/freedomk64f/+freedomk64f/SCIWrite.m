classdef (StrictDefaults)SCIWrite < matlabshared.svd.SCIWrite ...
        & coder.ExternalDependency
    %SCIWrite Set the logical value of a digital output pin.
    %
    
    %#codegen
    
    properties (Nontunable)
        %SCIModule SCI module
        SCIModule = '0';
    end
    
    properties (Nontunable,Logical)
        % BlockingMode - Wait until data is sent
        BlockingMode = true;
    end
    
    properties (Constant, Hidden)
        SCIModuleSet = matlab.system.StringSet({'0','1','2','3'})
    end
    
    methods
        function set.SCIModule(obj,value)
            if ~coder.target('Rtw') && ~coder.target('Sfun')
                if ~isempty(obj.Hw)
                    if ~isValidSCIModule(obj.Hw,value)
                        error(message('svd:svd:ModuleNotFound','SCI',value));
                    end
                end
            end
            obj.SCIModule = value;
        end
    end
    
    methods
        function obj = SCIWrite(varargin)
            coder.allowpcode('plain');
            %coder.cinclude('MW_target_hardware_resources.h');
            obj.Hw = freedomk64f.Hardware;
            obj.Logo = 'FRDM-K64F';
            setProperties(obj,nargin,varargin{:});
        end
    end
    methods (Static, Access = protected)
        function header = getHeaderImpl()
            header = matlab.system.display.Header(mfilename('class'),...
                'ShowSourceLink', false, ...
                'Title','NXP FRDM-K64F Serial Transmit', ...
                'Text', ['Send serial data to the Universal Asynchronous Receiver Transmitter(UART) port.' newline ...
                'The block expects the values as an [Nx1] or [1xN] array.']);
        end
    end
    
    methods (Access = protected)
        
        function maskDisplayCmds = getMaskDisplayImpl(obj)
            inport_label = [];
            num = getNumInputsImpl(obj);
            if num > 0
                inputs = cell(1,num);
                [inputs{1:num}] = getInputNamesImpl(obj);
                for i = 1:num
                    inport_label = [inport_label 'port_label(''input'',' num2str(i) ',''' inputs{i} ''');' newline]; %#ok<AGROW>
                end
            end
            
            outport_label = [];
            num = getNumOutputsImpl(obj);
            if num > 0
                outputs = cell(1,num);
                [outputs{1:num}] = getOutputNamesImpl(obj);
                for i = 1:num
                    outport_label = [outport_label 'port_label(''output'',' num2str(i) ',''' outputs{i} ''');' newline]; %#ok<AGROW>
                end
            end
            
            if isnumeric(obj.SCIModule)
                sciname = ['sprintf(''UART: 0x%X'',' num2str(obj.SCIModule) ')'];
            else
                sciname = ['sprintf(''UART%s'',''' obj.SCIModule ''')'];
            end
            
            maskDisplayCmds = [ ...
                ['color(''white'');', newline]...                                     % Fix min and max x,y co-ordinates for autoscale mask units
                ['plot([100,100,100,100],[100,100,100,100]);', newline]...
                ['plot([0,0,0,0],[0,0,0,0]);', newline]...
                ['color(''blue'');', newline] ...                                     % Drawing mask layout of the block
                ['text(99, 92, ''' obj.Logo ''', ''horizontalAlignment'', ''right'');', newline] ...
                ['color(''black'');', newline] ...
                ['text(50,15,' sciname ' ,''horizontalAlignment'', ''center'');', newline], ...
                ['sppkgroot = strrep(codertarget.freedomk64f.internal.getSpPkgRootDir(),''\'',''/'');',newline]...
                ['image(fullfile(sppkgroot,''resources'',''serial_txrx.jpg''),''center'')',newline]...
                inport_label, ...
                outport_label, ...
                ];
        end
        
        function setupImpl(obj,in)
            % Define outport size
            coder.extrinsic('num2str');
            %coder.extrinsic('propagatedInputDataType');
            size_out = propagatedInputSize(obj,1);
            size_t = size_out(1)*size_out(2);
            %             a = propagatedInputDataType(obj,1);
            switch(class(in))
                case 'double'
                    size_t =coder.const(size_t*8);
                case {'single','int32','uint32'}
                    size_t =coder.const(size_t*4);
                case  {'int8','uint8','logical'}
                    size_t =coder.const(size_t*1);
                case {'int16','uint16'}
                    size_t =coder.const(size_t*2);
                otherwise
                    size_t =coder.const(size_t*1);
            end
            
            if isequal(obj.SCIModule,'0')
                coder.updateBuildInfo('addDefines',['MW_SERIAL0_TXBUF_SIZE=' coder.const(num2str(size_t))]);
            elseif isequal(obj.SCIModule,'1')
                coder.updateBuildInfo('addDefines',['MW_SERIAL1_TXBUF_SIZE=' coder.const(num2str(size_t))]);
            elseif isequal(obj.SCIModule,'2')
                coder.updateBuildInfo('addDefines',['MW_SERIAL2_TXBUF_SIZE=' coder.const(num2str(size_t))]);
            elseif isequal(obj.SCIModule,'3')
                coder.updateBuildInfo('addDefines',['MW_SERIAL3_TXBUF_SIZE=' coder.const(num2str(size_t))]);
            elseif isequal(obj.SCIModule,'4')
                coder.updateBuildInfo('addDefines',['MW_SERIAL4_TXBUF_SIZE=' coder.const(num2str(size_t))]);
            end
            % Initialise SCI Module
            setupImpl@matlabshared.svd.SCIWrite(obj);
        end
        
        function num = getNumOutputsImpl(obj)
            % Define total number of outputs for system with optional
            % outputs
            if obj.OutputStatus
                if obj.BlockingMode == false
                    num = 1;
                else
                    num = 0;
                end
            else
                num = 0;
            end
        end
        
        
        function varargout = stepImpl(obj,varargin)
            nargoutchk(0,1);
            status = uint8(1);
            
            if isequal(obj.BlockingMode,false)
                status = write(obj, varargin{1}, class(varargin{1}));
            else
                %Blocking mode - wait unitl tx is available.
                while status ~= uint8(0)
                    status = write(obj, varargin{1}, class(varargin{1}));
                end
            end
            
            if nargout > 0
                varargout{1} = status;
            end
        end
        
        function flag = isInactivePropertyImpl(obj,prop)
            flag = isInactivePropertyImpl@matlabshared.svd.SCI(obj,prop);
            switch prop
                case {'OutputStatus'}
                    if obj.BlockingMode == true
                        flag = true;
                    else
                        flag = false;
                    end
            end
        end
    end
    
    methods (Static)
        function name = getDescriptiveName(~)
            name = 'NXP FRDM-K64F Serial Transmit';
        end
        
        function b = isSupportedContext(context)
            b = context.isCodeGenTarget('rtw') || context.isCodeGenTarget('sfun');
        end
        
        function updateBuildInfo(buildInfo, context)
            if context.isCodeGenTarget('rtw') || context.isCodeGenTarget('sfun')
                sppkgroot = strrep(codertarget.freedomk64f.internal.getSpPkgRootDir(),'\','/');
                addIncludePaths(buildInfo,fullfile(sppkgroot,'include'));
                addIncludeFiles(buildInfo,'MW_SCI.h');
                isRaccelBuild = strcmp(context.getConfigProp('SystemTargetFile'), 'raccel.tlc');
                if ~isRaccelBuild
                    buildInfo.addSourceFiles({'MW_SCI.c'},fullfile(sppkgroot,'src'));
                end
            end
        end
    end
    
    methods(Static, Access=protected)
        function [groups, PropertyList] = getPropertyGroupsImpl
            % SCI base property list
            [~, PropertyListOut] = matlabshared.svd.SCI.getPropertyGroupsImpl;
            PropertyListOut{1}.Description = 'UART';
            
            %BlockingMode Wait until data is sent
            BlockingModeProp = matlab.system.display.internal.Property('BlockingMode', 'Description', 'Wait until data is sent');
            
            %OutputStatus Output status
            OutputStatusProp = matlab.system.display.internal.Property('OutputStatus', 'Description', 'Output status');
            
            % Property list
            PropertyListOut{end+1} = BlockingModeProp;
            PropertyListOut{end+1} = OutputStatusProp;
            
            % Create mask display
            Group = matlab.system.display.Section(...
                'PropertyList',PropertyListOut);
            
            groups = Group;
            
            % Return property list if required
            if nargout > 1
                PropertyList = PropertyListOut;
            end
        end
    end
end
%[EOF]
