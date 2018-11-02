classdef (StrictDefaults)TCPSend < matlab.System & ...
        coder.ExternalDependency & ...
        matlab.system.mixin.Propagates & ...
        matlab.system.mixin.internal.CustomIcon
    % TCPSend
    % This class will be used to send data through TCP
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
        LocalIPPort_ = 25000;
    end
    
    properties (Nontunable,Logical,Hidden)
        % BlockingMode - Wait until previous packet transmitted
        BlockingMode = true;
        % BlockType - Indicates if this is Send or Receive block.
        %                       Send -> false, Receive -> true
        BlockType = false;
    end
    
    properties (Hidden,Transient,Constant)
        ConnectionModeSet = matlab.system.StringSet({'Server','Client'});
    end   
    
    properties (Access = protected)
        MW_TCPSENDHANDLE = int32(-1);
    end
    
    methods
        function TcpSend(obj,varargin)
            coder.allowpcode('plain');
            % Support name-value pair arguments
            setProperties(obj,nargin,varargin{:}, 'Length');
        end
        
        function set.LocalIPPort_(obj, val)
            validateattributes(val,{'numeric'}, ...
                {'real', 'positive', 'integer', 'scalar',...
                '>=',1,'<=',65535}, '', 'Local IP Port');
            obj.LocalIPPort_ = val;
        end
        
        function set.ServerIPPort_(obj, val)
            validateattributes(val,{'numeric'}, ...
                {'real', 'positive', 'integer', 'scalar',...
                '>=',1,'<=',65535}, '', 'Server IP Port');
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
                'Title', 'NXP FRDM-K64F Board TCP Send',...
                'Text', DAStudio.message('freedomk64f:blocks:TCPSendBlockDescription'));
        end
    end
    
    methods (Access=protected)
        function validateInputsImpl(obj,dataInput) %#ok<*INUSD>
            if((numel(dataInput) * obj.parseDataType(dataInput) )> (2*1460) ) %in lwipots, TCP_SND_BUF = 2 * 1460
                error(DAStudio.message('freedomk64f:blocks:TCPSendDataTooLong'));
            end
            validateattributes(dataInput, {'numeric','logical'}, ...
                {'nonnan', 'finite', 'real'}, '', '');
        end
        
        function validatePropertiesImpl(~)
        end
        
        function setupImpl(obj,varargin)
            obj.MW_TCPSENDHANDLE = uint32(0);
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
                    obj.MW_TCPSENDHANDLE = coder.ceval('MW_TCP_Init',uint32(obj.LocalIPPort_),block_type,...
                        connection_type,uint32(0),cstr('255.255.255.255'));
                else
                    obj.MW_TCPSENDHANDLE = coder.ceval('MW_TCP_Init',uint32(obj.LocalIPPort_),block_type,...
                        connection_type, uint32(obj.ServerIPPort_),cstr(obj.RemoteIPAddress_));
                end
            elseif ( coder.target('Sfun') )
                %Do nothing in simulation
            end
        end
        
        function stepImpl(obj,dataInp)
            if coder.target('Rtw')% done only for code gen
                coder.ceval('MW_TCP_Transmit',uint32(obj.MW_TCPSENDHANDLE),coder.rref(dataInp),...
                    uint32(numel(dataInp) * obj.parseDataType(dataInp)) );
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
        
        % getInputNamesImpl
        function inputname = getInputNamesImpl(~)
            inputname = 'data';
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
                case 'BlockingMode'
                    flag = true;
            end
        end
        
        function flag = isInputSizeLockedImpl(~,~)
            flag = true;
        end
        
        function flag = isInputComplexityLockedImpl(~,~)
            flag = true;
        end
        
        function InputPorts = getNumInputsImpl(~)
            InputPorts = 1;
        end
        
        function OutputPorts = getNumOutputsImpl(~)
            OutputPorts = 0;
        end

        function maskDisplayCmds = getMaskDisplayImpl(obj)
            
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
                ['text(50,15,' LocalIPPort ' ,''horizontalAlignment'', ''center'');', newline], ...
                ];
        end
        
    end
    
    methods (Static)
        function name = getDescriptiveName()
            name = 'TCP Send';
        end
        
        function dataSizeInBytes = parseDataType(dataInput)
            if isa(dataInput, 'embedded.fi')
                dataSizeInBytes = dataInput.WordLength/8;
            else
                switch (class(dataInput))
                    case 'double'
                        dataSizeInBytes =  8;
                    case {'single','int32','uint32'}
                        dataSizeInBytes =  4;
                    case {'int16','uint16'}
                        dataSizeInBytes =  2;
                    case {'int8','uint8','boolean','logical'}
                        dataSizeInBytes =  1;
                    otherwise
                        dataSizeInBytes = 0;
                end
            end
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
