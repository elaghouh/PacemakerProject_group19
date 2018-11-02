classdef (StrictDefaults)UDPSend < matlab.System & ...
        coder.ExternalDependency & ...
        matlab.system.mixin.Propagates & ...
        matlab.system.mixin.internal.CustomIcon
    
    % UDPSend
    % This class will be used to send data through UDP
    % Copyright 2016 - 2017 The MathWorks, Inc.
    %
    %#codegen
    %#ok<*EMCA>
    
    properties (Nontunable)
        % RemoteIPAddress_ - Remote IP address (255.255.255.255 for broadcast)
        RemoteIPAddress_ = '192.168.1.2';
        % RemoteIPPort_ - Remote IP Port
        RemoteIPPort_ = 25000;
        % LocalIPPort_ - Local IP Port (-1 for automatic port assignment)
        LocalIPPort_ = -1;
    end
    
    properties ( Hidden, Access=private)
        %Keep track of a allocated Local IP Port
        LocalIPPort_Allocated = uint16(0);
    end
    
    methods
        
        function obj = UdpSend(obj,varargin)
            coder.allowpcode('plain');
            % Support name-value pair arguments
            setProperties(obj,nargin,varargin{:}, 'Length');
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
        
        function set.RemoteIPPort_(obj, val)
            validateattributes(val, {'numeric'}, ...
                {'real', 'positive', 'integer', 'scalar', ...
                '>=',1,'<=',65535}, '', 'RemoteIPPort');
            obj.RemoteIPPort_ = val;
        end
        
        function set.LocalIPPort_(obj, val)
            validateattributes(val, {'numeric'}, ...
                {'real', 'integer', 'nonzero', 'scalar', ...
                '>=',-1,'<=',65535}, '', 'LocalIPPort');
            obj.LocalIPPort_ = val;
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
                'Title', 'NXP FRDM-K64F Board UDP Send',...
                'Text', DAStudio.message('freedomk64f:blocks:UDPSendBlockDescription'));
        end
    end
    
    
    methods (Access=protected)
        
        function validateInputsImpl(obj,dataInput) %#ok<*INUSD>
            if((numel(dataInput) * obj.parseDataType(dataInput) )>1472)
                error(DAStudio.message('freedomk64f:blocks:EthernetSendDataTooLong'));
            end
            validateattributes(dataInput, {'numeric','logical'}, ...
                {'nonnan', 'finite', 'real'}, '', '');
        end
        
        function flag = isInactivePropertyImpl(~, prop)
            flag = false;
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
                LocalIPPort = ['sprintf(''Port: %d'',' num2str(int32(obj.LocalIPPort_)) ')'];
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
        
        function setupImpl(obj,dataInp)
            %Initializing the obj property that keeps count of the
            %allocated Local IP Port for the UDP Send
            obj.LocalIPPort_Allocated = uint16(0);
            %The block init function expects the Data length requested on
            %UDP Receive block. Since this is
            %not applicable to UDPSend, initializing it to 0.
            Rx_requested_length = uint32(0);
            if coder.target('Rtw')% done only for code gen
                coder.cinclude('MW_Ethernet.h');
                obj.LocalIPPort_Allocated = coder.ceval('MW_UDP_Init',int16(obj.LocalIPPort_),...
                    cstr(obj.RemoteIPAddress_),uint16(obj.RemoteIPPort_),...
                    uint32(numel(dataInp) * obj.parseDataType(dataInp)),...
                    Rx_requested_length);
            elseif ( coder.target('Sfun') )
                %Do nothing in simulation
            end
        end
        
        function stepImpl(obj,dataInp)
            if coder.target('Rtw')% done only for code gen
                coder.ceval('MW_UDP_Transmit',uint16(obj.RemoteIPPort_),...
                    uint16(obj.LocalIPPort_Allocated),coder.rref(dataInp),...
                    uint32(numel(dataInp) * obj.parseDataType(dataInp)));
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
    
    methods (Static)
        
        function dataSizeInBytes = parseDataType(dataInput)
            
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
    
    %% Methods of coder.ExternalDependency
    methods (Static)
        
        function name = getDescriptiveName(~)
            name = 'UDP Send';
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
    
end

function str = cstr(str)
str = [str(:).', char(0)];
end