classdef (StrictDefaults)TCPReceive < matlab.System & ...
        coder.ExternalDependency ...
        & matlabshared.svd.BlockSampleTime & ...
        matlab.system.mixin.internal.CustomIcon & ...
        matlab.system.mixin.Propagates
    % TCPRECEIVE
    % This class will be used to receive data through TCP
    % Copyright 2017 The MathWorks, Inc.
    %
    %#codegen
    %#ok<*EMCA>
    
    properties (Nontunable)
        % ConnectionMode - Connection mode
        ConnectionMode = 'Server';
        % RemoteIPAddress_ - Remote IP Address
        RemoteIPAddress_ = '192.168.1.2';
        % ServerIPPort_ - Remote IP Port
        ServerIPPort_ = 25000;  
        % LocalIPPort_ - Local IP Port
        LocalIPPort_ = 25001;
        %DataType - Data type
        DataType = 'uint8';
        %DataLength - Data size (N)
        DataLength = 1;
    end
     
    properties (Nontunable, Dependent, Hidden)
        DataTypeLength;
    end
    
    properties (Nontunable,Logical,Hidden)

        % BlockType - Indicates if this is Send or Receive block.
        %                       Send -> false, Receive -> true
        BlockType = true;
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
        ConnectionModeSet = matlab.system.StringSet({'Server','Client'});
    end
    
    properties (Nontunable,Logical)
        % BlockingMode - Wait until data received
        BlockingMode = true;
    end
    
    properties (Nontunable)
        %BlockTimeout_ - Timeout in seconds
        BlockTimeout_ = 0.1;
    end
    
    properties (Access = protected)
        MW_TCPRCVHANDLE = int32(-1);
    end
    
    methods
        function TcpReceive(obj,varargin)
            coder.allowpcode('plain');
            % Support name-value pair arguments
            setProperties(obj,nargin,varargin{:}, 'Length');
        end
        
        function set.LocalIPPort_(obj, val)
            validateattributes(val,{'numeric'}, ...
                {'real', 'positive', 'integer', 'scalar',...
                '>=',1,'<=',65535}, '', 'LocalIPPort');
            obj.LocalIPPort_ = val;
        end
        
        function set.ServerIPPort_(obj, val)
            validateattributes(val,{'numeric'}, ...
                {'real', 'positive', 'integer', 'scalar',...
                '>=',1,'<=',65535}, '', 'LocalIPPort');
            obj.ServerIPPort_ = val;
        end
        
        function set.RemoteIPAddress_(obj, val)
            validateattributes(val, ...
                {'char'}, {'nonempty'}, '', 'RemoteIPAddress');
            if isempty(coder.target)
                % ISVALIDIP    Check for validity of IP address
                val = strrep(strtrim(val), 'http://', '');
                if (length(val) > 15)
                    error(message('freedomk64f:blocks:IPAddressTooLong'));
                end
                ipAddr = val;
                expr = '25[0-5]\.|2[0-4][0-9]\.|1[0-9][0-9]\.|[1-9][0-9]\.|[1-9]\.|0\.';
                [match] = regexp([ipAddr '.'], expr, 'match');
                if ( length(match) ~= 4 )
                    error(message('freedomk64f:blocks:InvalidIPAddress','Remote IP Address'));
                end
                
                ipStr = [match{1} match{2} match{3} match{4}(1:end-1)];
                if ( (~strcmp(ipStr, ipAddr)) || (strcmp(ipStr,'0.0.0.0')) )
                    error(message('freedomk64f:blocks:InvalidIPAddress','Remote IP Address'));
                end
            end
            obj.RemoteIPAddress_ = val;
        end
        
        function set.DataLength(obj, val)
            validateattributes(val, {'numeric'}, ...
                {'real', 'positive', 'integer', 'scalar'},...
                '', 'DataLength');
            obj.DataLength = val;
        end
        
        function set.BlockTimeout_(obj, val)
            classes = {'numeric'};
            attributes = {'nonempty','nonnan','real','nonnegative','nonzero','scalar'};
            paramName = 'Timeout in seconds';
            validateattributes(val,classes,attributes,'',paramName);
            obj.BlockTimeout_ = val;
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
                'Title', 'NXP FRDM-K64F Board TCP Receive',...
                'Text', DAStudio.message('freedomk64f:blocks:TCPReceiveBlockDescription') );
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
            BlockTimeoutProp = matlab.system.display.internal.Property('BlockTimeout_',...
                'Description', 'Timeout in seconds');
            ConnectionMode_Prop = matlab.system.display.internal.Property('ConnectionMode',...
                'Description', 'Connection mode');
            RemoteIPAddress_Prop = matlab.system.display.internal.Property('RemoteIPAddress_',...
                'Description', 'Remote IP Address');
            ServerIPPort_Prop = matlab.system.display.internal.Property('ServerIPPort_',...
                'Description', 'Remote IP Port');
            % Create mask display
%             Group = matlab.system.display.Section(...
%                 'Title', 'Parameters', ...
%                 'PropertyList',{ConnectionMode_Prop,RemoteIPAddress_Prop,...
%                 ServerIPPort_Prop, LocalIPPort_Prop,DataTypeProp,...
%                 DataLengthProp,BlockingModeProp,BlockTimeoutProp,...
%                 SampleTimeProp});
%             
%             groups = Group;
            
            requiredProps = matlab.system.display.Section(...
                'PropertyList',{ConnectionMode_Prop,RemoteIPAddress_Prop,...
                ServerIPPort_Prop, LocalIPPort_Prop,DataTypeProp,...
                DataLengthProp,...
                SampleTimeProp});
            
            advancedProps = matlab.system.display.Section(...
                'PropertyList',{BlockingModeProp,BlockTimeoutProp});
            
            MainTab = matlab.system.display.SectionGroup(...
                'Title', 'Main', ...
                'Sections',  requiredProps);
            
           AdvanceTab = matlab.system.display.SectionGroup(...
                'Title', 'Advanced', ...
                'Sections',  advancedProps);
            
            groups = [MainTab,AdvanceTab];
            
        end
        
    end
    
    methods (Access=protected)
        
        function validatePropertiesImpl(obj)
            if (obj.DataLength * obj.DataTypeLength) > (2*1460) % TCP_WND is 2*1460 in lwipopts file
                error(message('freedomk64f:blocks:TCPReceiveDataTooLong',...
                    obj.DataLength,obj.DataType));
            end
        end
        
        function setupImpl(obj,varargin)
            obj.MW_TCPRCVHANDLE = uint32(0);
            if coder.target('Rtw')% done only for code gen
                
                %'getBlockType' function converts the 'BlockType'
                % to a type of 'MW_TCP_BLOCK_TYPE' enum
                
                block_type = coder.const(@obj.getBlockType,obj.BlockType);
                block_type = coder.opaque('MW_TCP_BLOCK_TYPE', block_type);
                
                %'getBlockType' function converts the 'BlockType'
                % to a type of 'MW_TCP_BLOCK_TYPE' enum
                
                connection_type = coder.const(@obj.getConnectionType,obj.ConnectionMode);
                connection_type = coder.opaque('MW_TCP_CONNECTION_TYPE', connection_type);
                coder.cinclude('MW_Ethernet.h');

                if isequal(obj.ConnectionMode,'Server')
                    obj.MW_TCPRCVHANDLE = coder.ceval('MW_TCP_Init',uint32(obj.LocalIPPort_),block_type,...
                        connection_type,uint32(0),cstr('255.255.255.255'));
                else
                    obj.MW_TCPRCVHANDLE = coder.ceval('MW_TCP_Init',uint32(obj.LocalIPPort_),block_type,...
                        connection_type, uint32(obj.ServerIPPort_),cstr(obj.RemoteIPAddress_));
                end
            elseif ( coder.target('Sfun') )
                %Do nothing in simulation
            end
        end
        
        function [TCPDataOut,TCPStatus]= stepImpl(obj)
            TCPStatus = uint8(0);
            switch(obj.DataType)
                case 'double'
                    TCPDataOut = double(zeros(obj.DataLength,1));
                case 'single'
                    TCPDataOut = single(zeros(obj.DataLength,1));
                case  'int8'
                    TCPDataOut = int8(zeros(obj.DataLength,1));
                case 'uint8'
                    TCPDataOut = uint8(zeros(obj.DataLength,1));
                case 'int16'
                    TCPDataOut = int16(zeros(obj.DataLength,1));
                case 'uint16'
                    TCPDataOut = uint16(zeros(obj.DataLength,1));
                case 'int32'
                    TCPDataOut = int32(zeros(obj.DataLength,1));
                case 'uint32'
                    TCPDataOut = uint32(zeros(obj.DataLength,1));
                case 'boolean'
                    TCPDataOut = false(obj.DataLength,1);
            end
            if coder.target('Rtw')% done only for code gen
                TCPStatus = coder.ceval('MW_TCP_Receive',uint32(obj.MW_TCPRCVHANDLE),...
                    coder.wref(TCPDataOut),uint32(obj.DataLength * obj.DataTypeLength),...
                    uint32(obj.BlockingMode),obj.BlockTimeout_);
            elseif ( coder.target('Sfun') )
                %Do nothing in simulation
            end
        end
        
        function releaseImpl(~)
            if coder.target('Rtw')% done only for code gen
                % free dynamically allocated memory
                coder.ceval('MW_TCP_Terminate');
            elseif ( coder.target('Sfun') )
                % do nothing in simulation
            end
        end
        
        function [TCPDataOut,TCPStatus] = getOutputDataTypeImpl(obj)
            if isequal(obj.DataType,'boolean')
                TCPDataOut = 'logical';
            else
                TCPDataOut = obj.DataType;
            end
            TCPStatus = 'uint8';
        end
        
        % getInputNamesImpl
        function [TCPDataOut,TCPStatus] = getOutputNamesImpl(~)
            TCPDataOut = 'Data';
            TCPStatus = 'Status';
        end
        
        function flag = isInactivePropertyImpl(obj, prop)
            switch (prop)
                case 'ConnectionMode'
                    flag = false;                    
                case 'RemoteIPAddress_'
                    if isequal(obj.ConnectionMode,'Client')
                        flag = false;
                    else 
                        flag = true;
                    end
                case 'ServerIPPort_'
                    if isequal(obj.ConnectionMode,'Client')
                        flag = false;
                    else 
                        flag = true;
                    end     
                case 'LocalIPPort_'
                    flag = false;
                case 'DataType'
                    flag = false;
                case 'DataLength'
                    flag = false;
                case 'SampleTime'
                    flag = false;
                case 'BlockingMode'
                    flag = false;
                case 'BlockTimeout_'
                    flag = ~obj.BlockingMode;
            end
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
        
        function [TCPDataOut,TCPStatus] = isOutputFixedSizeImpl(~)
            TCPDataOut = true;
            TCPStatus = true;
        end
        
        function [TCPDataOut,TCPStatus] = isOutputComplexImpl(~)
            TCPDataOut = false;
            TCPStatus = false;
        end
        
        function [TCPDataOut,TCPStatus] = getOutputSizeImpl(obj)
            
            TCPDataOut = [obj.DataLength 1];
            TCPStatus = [1 1];

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
              
    end
    
    methods (Static)
        function name = getDescriptiveName()
            name = 'TCP Receive';
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
                    buildInfo.addSourceFiles( {'MW_Ethernet.c','fsl_phy_driver.c',...
                        'ethernetif.c','lwip_fsl_irq.c'},...
                        fullfile(sppkgroot,'src'));
                    
                    %Add source files from ksdkroot/'platform'/'osa'/'src' directory
                    buildInfo.addSourceFiles({'fsl_os_abstraction_bm.c'},...
                        fullfile(ksdkroot,'platform','osa','src'));
                    
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
    
    %% Helper Functions
    methods (Static, Access=protected)
        function BlockType = getBlockType(Type)
            coder.inline('always');
            switch Type
                case 0
                    BlockType = 'TCP_SEND';
                case 1
                    BlockType = 'TCP_RECEIVE';
                otherwise
                    BlockType = 'TCP_SEND';
            end
        end
        
        function ConnectionType = getConnectionType(Type)
            coder.inline('always');
            switch Type
                case 'Server'
                    ConnectionType = 'SERVER';
                case 'Client'
                    ConnectionType = 'CLIENT';
                otherwise
                    ConnectionType = 'SERVER';
            end
        end
        
    end
    
end

function str = cstr(str)
str = [str(:).', char(0)];
end


