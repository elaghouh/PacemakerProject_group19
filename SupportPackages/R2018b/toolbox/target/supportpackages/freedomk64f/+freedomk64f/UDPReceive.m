classdef (StrictDefaults)UDPReceive <  matlab.System & ...
        coder.ExternalDependency ...
        & matlabshared.svd.BlockSampleTime & ...
        matlab.system.mixin.internal.CustomIcon & ...
        matlab.system.mixin.Propagates
    
    % UDPRECEIVE
    % This class will be used to receive data through UDP
    % Copyright 2016 - 2017 The MathWorks, Inc.
    
    %#codegen
    %#ok<*EMCA>
    
    properties (Nontunable)
        % LocalIPPort_ - Local IP Port
        LocalIPPort_ = 25000;
        %DataType - Data type
        DataType = 'uint8';
        %DataLength - Data size (N)
        DataLength = 1;
    end
    
    properties (Nontunable,Logical)
        % BlockingMode - Wait until data received
        BlockingMode = false;
    end
    
    properties (Nontunable, Dependent, Hidden)
        DataTypeLength;
    end
    
    properties (Nontunable, Hidden)
        RemoteIPAddress_ = '0.0.0.0';
    end
    
    properties (Hidden,Transient,Constant)
        % this StringSet object creates a dropdown menu
        DataTypeSet = matlab.system.StringSet({...
            'double',...
            'single',...
            'int8',...
            'uint8',...
            'int16',...
            'uint16',...
            'int32',...
            'uint32',...
            'boolean', ...
            });
    end
    
    methods
        
        function UdpReceive(obj,varargin)
            coder.allowpcode('plain');
            % Support name-value pair arguments
            setProperties(obj,nargin,varargin{:}, 'Length');
        end
        
        function set.LocalIPPort_(obj, val)
            validateattributes(val, {'numeric'}, ...
                {'real', 'positive', 'integer', 'scalar', ...
                '>=',1,'<=',65535}, '', 'LocalIPPort');
            obj.LocalIPPort_ = val;
        end
        
        function set.DataLength(obj, val)
            validateattributes(val, {'numeric'}, ...
                {'real', 'positive', 'integer', 'scalar'},...
                '', 'DataLength');
            obj.DataLength = val;
        end
        
        function value = get.DataTypeLength(obj)
            switch obj.DataType
                case {'int8', 'uint8', 'boolean'}
                    value = 1;
                case {'int16', 'uint16'}
                    value = 2;
                case {'int32', 'uint32','single'}
                    value = 4;
                case {'double'}
                    value = 8;
            end
        end
        
    end
    
    methods (Static, Access=protected)
        function simMode = getSimulateUsingImpl(~)
            simMode = 'Interpreted execution';
        end
        
        function isVisible = showSimulateUsingImpl
            isVisible = false;
        end
        
        function header = getHeaderImpl(~)
            header = matlab.system.display.Header(mfilename('class'), ...
                'ShowSourceLink', false, ...
                'Title', 'NXP FRDM-K64F Board UDP Receive',...
                'Text', DAStudio.message('freedomk64f:blocks:UDPReceiveBlockDescription') );
        end
        
        function groups = getPropertyGroupsImpl(~)
            
            % Sample time
            SampleTimeProp = matlab.system.display.internal.Property('SampleTime',...
                'Description', 'Sample time');
            LocalIPPort_Prop = matlab.system.display.internal.Property('LocalIPPort_',...
                'Description', 'Local IP Port');
            DataTypeProp = matlab.system.display.internal.Property('DataType',...
                'Description', 'Data type');
            DataLengthProp = matlab.system.display.internal.Property('DataLength',...
                'Description', 'Data size (N)');
            BlockingModeProp = matlab.system.display.internal.Property('BlockingMode',...
                'Description', 'Wait until data received');
            
            % Create mask display
            Group = matlab.system.display.Section(...
                'Title', 'Parameters', ...
                'PropertyList',{LocalIPPort_Prop,DataTypeProp,...
                DataLengthProp,BlockingModeProp,SampleTimeProp});
            
            groups = Group;
            
        end
    end
    
    methods (Access=protected)
        
        function validatePropertiesImpl(obj)
            if (obj.DataLength * obj.DataTypeLength) > 1472
                error(message('freedomk64f:blocks:EthernetReceiveDataTooLong',...
                    obj.DataLength,obj.DataType));
            end
        end
        
        function [UDPDataOut,UDPSize] = getOutputDataTypeImpl(obj)
            if strcmp(obj.DataType,'boolean')
                UDPDataOut = 'logical';
            else
                UDPDataOut = obj.DataType;
            end
            
            UDPSize = 'uint16';
        end
        
        % getOutputNamesImpl
        function [UDPDataOut,UDPSize] = getOutputNamesImpl(~)
            UDPDataOut = 'Data';
            UDPSize = 'Size';
        end
        
        function flag = isInactivePropertyImpl(~,~)
            flag = false;
        end
        
        function flag = isInputSizeLockedImpl(~,~)
            flag = true;
        end
        
        function flag = isInputComplexityLockedImpl(~,~)
            flag = true;
        end
        
        function flag = isOutputComplexityLockedImpl(~,~)
            flag = true;
        end
        
        function OutputPorts = getNumOutputsImpl(~)
            OutputPorts = 2;
        end
        
        function [UDPDataOut,UDPSize] = isOutputFixedSizeImpl(~)
            UDPDataOut = true;
            UDPSize = true;
        end
        
        function [UDPDataOut,UDPSize] = isOutputComplexImpl(~)
            UDPDataOut = false;
            UDPSize = false;
        end
        
        function [UDPDataOut,UDPSize] = getOutputSizeImpl(obj)
            UDPDataOut = [obj.DataLength 1];
            UDPSize = [1 1];
            validateattributes((obj.DataLength * obj.DataTypeLength), {'numeric'}, ...
                {'scalar', '<=', 1472}, ...
                '', 'Size of Output');
        end
        
        function maskDisplayCmds = getMaskDisplayImpl(obj)
        
            num = 2;
            outport_label = [];
            outputs = getOutputNames(obj);
            for i = 1:num
                outport_label = [outport_label 'port_label(''output'',' num2str(i) ',''' outputs{i} ''');' newline]; %#ok<AGROW>
            end
            if isnumeric(obj.LocalIPPort_)
                LocalIPPort = ['sprintf(''Port: %d'',' num2str(uint32(obj.LocalIPPort_)) ')'];
            else
                LocalIPPort = ['sprintf(''Port%s'',''' uint32(obj.LocalIPPort_) ''')'];
            end
            
            maskDisplayCmds = [ ...
                ['color(''white'');',newline]...
                ['plot([100,100,100,100]*1,[100,100,100,100]*1);',newline]...
                ['plot([100,100,100,100]*0,[100,100,100,100]*0);',newline]...
                ['color(''blue'');',newline] ...                                     % Drawing mask layout of the block
                ['text(99, 92, ''\fontsize{9}FRDM-K64F '',''texmode'',''on'',''horizontalAlignment'', ''right'');',newline]  ...
                ['color(''black'');',newline]...
                ['sppkgroot = strrep(codertarget.freedomk64f.internal.getSpPkgRootDir(),''\'',''/'');',newline]...
                ['image(fullfile(sppkgroot,''resources'',''UDP.jpg''),''center'')',newline]...
                ['color(''black'');', newline] ...
                ['text(50,12,' LocalIPPort ' ,''horizontalAlignment'', ''center'');', newline], ...
                outport_label
                ];
            
        end
        
        function setupImpl(obj,varargin)
            %The block init function expects RemoteIPPort and Length of TX
            %data buffer size as 3rd and 4th arguments. Since these two are
            %not applicable to UDPReceive, initializing them to 0.
            RemoteIPPort = uint16(0);
            TX_Data_buffer_size = uint32(0);
            if coder.target('Rtw')% done only for code gen
                coder.cinclude('MW_Ethernet.h');
                coder.ceval('MW_UDP_Init',int16(obj.LocalIPPort_),cstr(obj.RemoteIPAddress_),...
                    RemoteIPPort,TX_Data_buffer_size,uint32(obj.DataLength * obj.DataTypeLength));
            elseif ( coder.target('Sfun') )
                %Do nothing in simulation
            end
        end
        
        function [UDPDataOut,UDPSize]= stepImpl(obj)
            UDPSize = uint16(0);
            switch(obj.DataType)
                case 'double'
                    UDPDataOut = double(zeros(obj.DataLength,1));
                case 'single'
                    UDPDataOut = single(zeros(obj.DataLength,1));
                case  'int8'
                    UDPDataOut = int8(zeros(obj.DataLength,1));
                case 'uint8'
                    UDPDataOut = uint8(zeros(obj.DataLength,1));
                case 'int16'
                    UDPDataOut = int16(zeros(obj.DataLength,1));
                case 'uint16'
                    UDPDataOut = uint16(zeros(obj.DataLength,1));
                case 'int32'
                    UDPDataOut = int32(zeros(obj.DataLength,1));
                case 'uint32'
                    UDPDataOut = uint32(zeros(obj.DataLength,1));
                case 'boolean'
                    UDPDataOut = false(obj.DataLength,1);
            end
            if coder.target('Rtw')% done only for code gen
                coder.cinclude('MW_Ethernet.h');
                UDPSize = coder.ceval('MW_UDP_Receive',obj.BlockingMode, int16(obj.LocalIPPort_),...
                    coder.wref(UDPDataOut),uint32(obj.DataLength * obj.DataTypeLength));
                UDPSize = UDPSize/obj.DataTypeLength;
            elseif ( coder.target('Sfun') )
                %Do nothing in simulation
            end
        end
        
        function releaseImpl(~)
            if coder.target('Rtw')% done only for code gen
                % free dynamically allocated memory
                coder.ceval('MW_UDP_Terminate');
            elseif ( coder.target('Sfun') )
                % do nothing in simulation
            end
        end
    end
    
    %% Methods of coder.ExternalDependency
    methods (Static)
        
        function name = getDescriptiveName(~)
            name = 'UDP Receive';
        end
        
        function b = isSupportedContext(context)
            b = context.isCodeGenTarget('rtw');
        end
        
        % Update the build-time buildInfo
        function updateBuildInfo(buildInfo, context)
            if context.isCodeGenTarget('rtw')
                sppkgroot = strrep(codertarget.freedomk64f.internal.getSpPkgRootDir(),'\','/');
                ksdkroot = strrep(codertarget.freedomk64f.internal.getKinetisSDKRootDir(),'\','/');
                lwiproot = fullfile(ksdkroot,'middleware','tcpip','lwip');
                
                isRaccelBuild = strcmp(context.getConfigProp('SystemTargetFile'), 'raccel.tlc');
                if ~isRaccelBuild
                    %Add source files from Support Package Root directory
                    buildInfo.addSourceFiles( {'MW_Ethernet.c','fsl_phy_driver.c'...
                        ,'ethernetif.c','lwip_fsl_irq.c'},...
                        fullfile(sppkgroot,'src'));
                    
                    %Add source files from ksdkroot/'platform'/'utilities'/'src' directory
                    buildInfo.addSourceFiles({'print_scan.c','fsl_debug_console.c'},...
                        fullfile(ksdkroot,'platform','utilities','src'));
                    
                    %Add source files from ksdkroot/'platform'/'system'/'src'/'hwtimer' directory
                    buildInfo.addSourceFiles({'fsl_hwtimer_pit_irq.c'},...
                        fullfile(ksdkroot,'platform','system','src','hwtimer'));
                    
                    %Add source files from lwiproot/'port' directory
                    buildInfo.addSourceFiles({'sys_arch.c'},...
                        fullfile(lwiproot,'port'));
                    
                    %Add source files from lwiproot/'src'/'core' directory
                    buildInfo.addSourceFiles({'stats.c','raw.c','udp.c','def.c','lwip_timers.c','pbuf.c',...
                        'dhcp.c','mem.c','sys.c','netif.c','init.c','memp.c',...
                        'tcp.c','tcp_in.c','tcp_out.c'},...
                        fullfile(lwiproot,'src','core'));
                    
                    %Add source files from lwiproot/'src'/'core'/'ipv4' directory
                    buildInfo.addSourceFiles({'ip_addr.c','ip.c','autoip.c','icmp.c','inet_chksum.c',...
                        'ip_frag.c','inet.c'},...
                        fullfile(lwiproot,'src','core','ipv4'));
                    
                    %Add source files from lwiproot/'src'/'api' directory
                    buildInfo.addSourceFiles({'netifapi.c','netdb.c','err.c','api_msg.c','sockets.c',...
                        'api_lib.c','netbuf.c'},fullfile(lwiproot,'src','api'));
                    
                    %Add source files from lwiproot/'src'/'netif' directory
                    buildInfo.addSourceFiles('etharp.c',fullfile(lwiproot,'src','netif'));
                    
                end
                
                %Now add include folders
                buildInfo.addIncludePaths(fullfile(lwiproot,'src','include'));
                buildInfo.addIncludePaths(fullfile(lwiproot,'port'));
                buildInfo.addIncludePaths(fullfile(lwiproot,'src','include','ipv4'));
                buildInfo.addIncludePaths(fullfile(lwiproot,'src','include','lwip'));
                buildInfo.addIncludePaths(fullfile(lwiproot,'src','include','netif'));
                buildInfo.addIncludePaths(fullfile(sppkgroot,'include'));
                buildInfo.addIncludeFiles({'MW_Ethernet.h'});
                
                %hardwwareInit needs this in order to know whether to
                %configure Ethernet
                buildInfo.addDefines('ETHERNET_INIT', 'SkipForSil');
            end
        end
    end
    
end

function str = cstr(str)
str = [str(:).', char(0)];
end
