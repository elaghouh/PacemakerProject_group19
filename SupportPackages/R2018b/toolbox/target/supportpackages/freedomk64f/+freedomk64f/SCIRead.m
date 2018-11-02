classdef (StrictDefaults)SCIRead < matlabshared.svd.SCIRead ...
        & coder.ExternalDependency
    %SCIRead Set the logical value of a digital output pin.
    %
    
    %#codegen
    
    properties (Nontunable)
        %SCIModule SCI module
        SCIModule = '0';
    end
    
    properties (Constant, Hidden)
        SCIModuleSet = matlab.system.StringSet({'0','1','2','3'})
    end
    
    properties (Nontunable,Logical)
        % BlockingMode - Wait until data is received
        BlockingMode = false;
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
        function obj = SCIRead(varargin)
            coder.allowpcode('plain');
            %coder.cinclude('MW_target_hardware_resources.h');
            obj.Hw = freedomk64f.Hardware;
            obj.Logo = 'FRDM-K64F';
            setProperties(obj,nargin,varargin{:});
        end
    end
    
    methods(Access = protected)
        
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
        
        %         function maskDisplayCmds = getMaskDisplayImpl(obj)
        %
        %             outport_label = [];
        %             num=getNumOutputs(obj);
        %             if(num >0)
        %                 outputs = cell(1,num);
        %                 [outputs{1:num}] = getOutputNames(obj);
        %                 for i = 1:num
        %                     outport_label = [outport_label 'port_label(''output'',' num2str(i) ',''' outputs{i} ''');' char(10)]; %#ok<AGROW>
        %                 end
        %             end
        %
        %             %pic=imread('serial.png');
        %             %image(pic,[0.23 0.18 0.45 0.65]);
        %
        %
        %             maskDisplayCmds = [ ...
        %                 ['color(''white'');',char(10)]...
        %                 ['plot([100,100,100,100]*1,[100,100,100,100]*1);',char(10)]...
        %                 ['plot([100,100,100,100]*0,[100,100,100,100]*0);',char(10)]...
        %                 ['color(''blue'');',char(10)] ...
        %                 ['text(99, 92, '' FRDM-K64F '', ''horizontalAlignment'', ''right'');',char(10)]  ...
        %                 ['color(''black'');',char(10)]...
        %                 ['sppkgroot = strrep(codertarget.freedomk64f.internal.getSpPkgRootDir(),''\'',''/'');',char(10)]...
        %                 ['image(fullfile(sppkgroot,''resources'',''serial1.jpg''),''center'')',char(10)]...
        %                 outport_label];
        %         end
        
        function setupImpl(obj)
            % Initialise SCI Module
            % Define outport size
            coder.extrinsic('num2str');
            size_out = getOutputSizeImpl(obj);
            size_t = size_out(1);
            
            switch(obj.DataType)
                case 'double'
                    size_t =size_t*8;
                case {'single','int32','uint32'}
                    size_t =size_t*4;
                case  {'int8','uint8','logical'}
                    size_t =size_t*1;
                case {'int16','uint16'}
                    size_t =size_t*2;
                otherwise
                    size_t =size_t*1;
            end
            
            if isequal(obj.SCIModule,'0')
                coder.updateBuildInfo('addDefines',['MW_SERIAL0_RXBUF_SIZE=' coder.const(num2str(size_t))]);
            elseif isequal(obj.SCIModule,'1')
                coder.updateBuildInfo('addDefines',['MW_SERIAL1_RXBUF_SIZE=' coder.const(num2str(size_t))]);
            elseif isequal(obj.SCIModule,'2')
                coder.updateBuildInfo('addDefines',['MW_SERIAL2_RXBUF_SIZE=' coder.const(num2str(size_t))]);
            elseif isequal(obj.SCIModule,'3')
                coder.updateBuildInfo('addDefines',['MW_SERIAL3_RXBUF_SIZE=' coder.const(num2str(size_t))]);
            elseif isequal(obj.SCIModule,'4')
                coder.updateBuildInfo('addDefines',['MW_SERIAL4_RXBUF_SIZE=' coder.const(num2str(size_t))]);
            end
            % Initialise SCI Module
            setupImpl@matlabshared.svd.SCIRead(obj);
        end
        
        function num = getNumOutputsImpl(obj)
            % Define total number of outputs for system with optional
            % outputs
            if obj.OutputStatus
                if obj.BlockingMode == false
                    num = 2;
                else
                    num = 1;
                end
            else
                num = 1;
            end
        end
        
        function varargout = stepImpl(obj)
            nargoutchk(1,2);
            status = uint8(1);
            %             RxData = cast(zeros(obj.DataLength,1),obj.DataType);
            if obj.BlockingMode ~= true
                % Non-blocking mode
                [RxData, status] = read(obj, obj.DataLength, obj.DataType);
            else
                %Blocking mode - wait unitl data is available.
                RxData = cast(zeros(obj.DataLength,1),obj.DataType);
                while status ~= uint8(0)
                    [RxData, status] = read(obj, obj.DataLength, obj.DataType);
                end
            end
            
            varargout{1} = RxData;
            if nargout > 1
                varargout{2} = status;
            end
        end
    end
    
    methods (Access = protected)
        function flag = isInactivePropertyImpl(obj,prop)
            flag = isInactivePropertyImpl@matlabshared.svd.SCI(obj,prop);
            switch prop
                case {'Baudrate','Parity','DataBitsLength','StopBits','HardwareFlowControl','ByteOrder'}
                    flag = true;
                case {'OutputStatus'}
                    if obj.BlockingMode == true
                        flag = true;
                    else
                        flag = false;
                    end
            end
        end
    end
    
    methods(Static, Access=protected)
        function header = getHeaderImpl()
            header = matlab.system.display.Header(mfilename('class'),...
                'ShowSourceLink', false, ...
                'Title','NXP FRDM-K64F Serial Receive', ...
                'Text', ['Read data from the Universal Asynchronous Receiver Transmitter(UART) port.' newline newline ...
                'The block outputs the values received as an [Nx1] array.']);
        end
        
        function [groups, PropertyList] = getPropertyGroupsImpl
            % SCI base property list
            [~, PropertyListOut] = matlabshared.svd.SCI.getPropertyGroupsImpl;
            PropertyListOut{1}.Description = 'UART';
            
            %DataLength Data length (N)
            DataLengthProp = matlab.system.display.internal.Property('DataLength', 'Description', 'Data length (N)');
            %DataType Data type
            DataTypeProp = matlab.system.display.internal.Property('DataType', 'Description', 'Data type');
            %BlockingMode Wait until data is received
            BlockingModeProp = matlab.system.display.internal.Property('BlockingMode', 'Description', 'Wait until data received');
            %OutputStatus Output status
            OutputStatusProp = matlab.system.display.internal.Property('OutputStatus', 'Description', 'Output status');
            %SampleTime Sample time
            SampleTimeProp = matlab.system.display.internal.Property('SampleTime', 'Description', 'Sample time');
            
            % Property list
            PropertyListOut{end+1} = DataTypeProp;
            PropertyListOut{end+1} = DataLengthProp;
            PropertyListOut{end+1} = BlockingModeProp;
            PropertyListOut{end+1} = OutputStatusProp;
            PropertyListOut{end+1} = SampleTimeProp;
            
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
    
    methods (Static)
        function name = getDescriptiveName(~)
            name = 'Serial Receive';
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
end
%[EOF]
