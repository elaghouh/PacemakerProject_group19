function ethernetCallback(varargin)
%ETHERNETCALLBACK Validates the UDP/TCP Send and Receive blocks

% Copyright 2016 - 2017 The MathWorks, Inc.

%% Different cases addressed by this callback
%1. Register the GPIO pins used only once, even if there are multiple
% Ethernet blocks
%2. Allow multiple UDP Send blocks with local port as -1.
%3. No two Ethernet blocks can have the same local port. Expection: 1 pair
%of TCP Send and Receive blocks.
%4. If DHCP is used in the model, register the Ports only once even if
% multiple UDP blocks are present in the model.
%5.a Allow maximum of 6 UDP blocks in the model. With DHCP on, the
% maximum is restricted to 5.
%5.b Allow maximum of 6 TCP Connections in the model. A TCP Send and
%Receive pair with same local port is considered 1 TCP connection.
%6. Registering the number of UDP/TCP Receive and Send blocks used in the model.
%7. Check TCP Client connections. If 2 TCP Send/Receive blocks in Client
%mode are connected to same RemoteIP-Port combination, report Error
%%
% Check on input "action"
action = varargin{1};
blk = varargin{2};

switch action
    case 'MaskInitialization'
        
    case 'Validate'
        validateUDPblock(blk);
        
    otherwise
        error('Unknown callback action "%s"', action)
end
end

function validateUDPblock(current_block, varargin)
global modelBlockStruct;
mdlName = codertarget.utils.getModelForBlock(current_block);
try
    ctd = get_param(mdlName, 'CoderTargetData');
catch
    %Target not configured. No need to proceed further
    return;
end
blkname = [get_param(current_block, 'Parent') '/' get_param(current_block, 'Name')];
system_name = get_param(current_block,'System');
family_name = strsplit(system_name,'.');
family_name = family_name{2};
codertarget.resourcemanager.registerblock(current_block);

%Setting the 'MaxReceiveLength' and 'MatchTcpPorts' to 0, if this is the
%first Ethernet block of the model to get registered
if  ( isempty(modelBlockStruct) || ~isfield(modelBlockStruct.parameters,'LocalIPPort_') )
    %First Ethernet block (UDP or TCP) of the model
    codertarget.resourcemanager.set(current_block,'UDP','MaxReceiveLength',0);
    codertarget.resourcemanager.set(current_block,'TCP','MatchTcpPorts',0);
    parameter_callback = {{'allDifferent'}; {'allDifferent'};{'allDifferent'}; {'allDifferent'};...
        {'allDifferent'}; {'allDifferent'};{'allDifferent'}; {'allDifferent'};...
        {'allDifferent'}; {'allDifferent'};{'allDifferent'}; {'allDifferent'};...
        {'allDifferent'}; {'allDifferent'} };
else
    parameter_callback = '';
end

%%
% 1. Register the GPIO pins used only once, even if there are multiple UDP
%blocks
opts.familyName = 'Ethernet_Pins';
opts.parameterName = {'GPIO_Number';'GPIO_Number';'GPIO_Number';'GPIO_Number';...
    'GPIO_Number';'GPIO_Number';'GPIO_Number';'GPIO_Number';...
    'GPIO_Number';'GPIO_Number';'GPIO_Number';'GPIO_Number';...
    'GPIO_Number';'GPIO_Number'};
opts.parameterValue = {'PTC16 (D0)';'PTC17 (D1)';'PTC18';'PTC19';'PTB1';'PTB0';'PTA13';...
    'PTA12';'PTA14';'PTA5';'PTA16';'PTA17';'PTA15';'PTA28'};
opts.parameterCallback = parameter_callback;
opts.blockCallback = [];
a = 'freedomk64f:blocks:GPIOPinAlreadyUsed';
opts.errorID = {a;a;a;a;a;a;a;a;a;a;a;a;a;a};
opts.errorArgs = {opts.parameterValue{1};opts.parameterValue{2};...
    opts.parameterValue{3};opts.parameterValue{4};opts.parameterValue{5};...
    opts.parameterValue{6};opts.parameterValue{7};opts.parameterValue{8};...
    opts.parameterValue{9};opts.parameterValue{10};opts.parameterValue{11};...
    opts.parameterValue{12};opts.parameterValue{13};opts.parameterValue{14}};
opts.targetPrefCallback = [];
lf_registerBlockCallbackInfo(opts);

%%
%Retrieve the current 'MaxReceiveLength' of all UDP Receive blocks
max_data_length =  codertarget.resourcemanager.get('','UDP','MaxReceiveLength',getActiveConfigSet(bdroot));

if( contains(system_name,'UDPReceive') )
    datatype = get_param(current_block, 'DataType');
    switch(datatype)
        case 'double'
            datatypewidth = 8;
        case {'single','int32','uint32'}
            datatypewidth = 4;
        case  {'int8','uint8','boolean'}
            datatypewidth = 1;
        case {'int16','uint16'}
            datatypewidth = 2;
        otherwise
            datatypewidth = 1;
    end
    
    datalength = uint32(str2double(get_param(current_block, 'DataLength')));
    
    datalength_udp = datalength * datatypewidth;
    %Re-setting the new 'MaxReceiveLength' for the model. This is retrieved
    %in 'onAfterCodeGenHook' and added as a #define, which is then used in
    %'MW_Ethernet.c' to determine the buffer size.
    if(datalength_udp > max_data_length)
        codertarget.resourcemanager.set(current_block,'UDP','MaxReceiveLength',datalength_udp);
    end
end

local_port = get_param(current_block,'LocalIPPort_');
parameter_callback = {{'allDifferent'}};

%%
% 2.a Allow multiple UDP Send blocks with local port as -1.
if( contains(system_name,'UDPSend') )
    if strcmp(local_port,'-1')
        parameter_callback = '';
    end
end
%match_tcp_ports contains the number of pairs of TCP Send and receive
%blocks with same Local port.
match_tcp_ports = codertarget.resourcemanager.get('','TCP','MatchTcpPorts',getActiveConfigSet(bdroot));
%2.b Allow 1 pair of TCP Send and Receive with the same local port. Both the 
% Send and Receive blocks have to be either Client or Server.
if( isfield(modelBlockStruct.parameters,'LocalIPPort_') )
    %N gives the number of Ethernet blocks
    N = length(modelBlockStruct.parameters.LocalIPPort_);
    if contains(system_name,'TCP')
        ConnMode = get_param(current_block,'ConnectionMode');
        if strcmp(family_name,'TCPReceive')
            %This case handles when the current block is TCPReceive, and
            %atleast 1 TCPSend block is already registered.
            if( strcmp(ConnMode,'Server') && (isfield(modelBlockStruct.parameters,'TCPSendServer')) )
                %This case checks if a TCP Send (Server) is already
                %registered with same local port as the current 
                %TCP Receive (Server) block
                Num_TCP_Send_Server = length(modelBlockStruct.parameters.TCPSendServer);
                for j = 1:Num_TCP_Send_Server
                    for k = 1:N
                        %Check if the local port of any of the TCP Server Send blocks
                        %matches the local port of current TCP Server Receive block.
                        if( isequal( modelBlockStruct.parameters.TCPSendServer{j}{2}, modelBlockStruct.parameters.LocalIPPort_{k}{2} ) &&...
                                isequal(local_port,modelBlockStruct.parameters.LocalIPPort_{k}{1}) )
                            parameter_callback = '';
                            match_tcp_ports = match_tcp_ports + 1;
                            %Update the number of matched TCP Pairs
                            codertarget.resourcemanager.set(current_block,'TCP','MatchTcpPorts',match_tcp_ports);
                            registerMatchedPorts(local_port);
                        end
                    end
                end
            elseif( strcmp(ConnMode,'Client') && (isfield(modelBlockStruct.parameters,'TCPSendClient')) )
                %This case checks if a TCP Send (Client) is already
                %registered with same local port as the current 
                %TCP Receive (Client) block
                Num_TCP_Send_Client = length(modelBlockStruct.parameters.TCPSendClient);
                for j = 1:Num_TCP_Send_Client
                    for k = 1:N
                        %Check if the local port of any of the TCP Client Send blocks
                        %matches the local port of current TCP Client Receive block.
                        if( isequal( modelBlockStruct.parameters.TCPSendClient{j}{2}, modelBlockStruct.parameters.LocalIPPort_{k}{2} ) &&...
                                isequal(local_port,modelBlockStruct.parameters.LocalIPPort_{k}{1}) )
                            parameter_callback = '';
                            match_tcp_ports = match_tcp_ports + 1;
                            %Update the number of matched TCP Pairs
                            codertarget.resourcemanager.set(current_block,'TCP','MatchTcpPorts',match_tcp_ports);
                            registerMatchedPorts(local_port);
                        end
                    end
                end
            end
        elseif strcmp(family_name,'TCPSend')
            if( strcmp(ConnMode,'Server') && (isfield(modelBlockStruct.parameters,'TCPReceiveServer')) )
                %This case handles when the current block is TCPSend, and
                %atleast 1 TCPReceive block is already registered.
                Num_TCP_Receive_Server = length(modelBlockStruct.parameters.TCPReceiveServer);
                for j = 1:Num_TCP_Receive_Server
                    for k = 1:N
                        %Check if the local port of any of the TCP Receive (Server) blocks
                        %matches the local port of current TCP Send (Server) block.
                        if( isequal( modelBlockStruct.parameters.TCPReceiveServer{j}{2}, modelBlockStruct.parameters.LocalIPPort_{k}{2} ) &&...
                                isequal(local_port,modelBlockStruct.parameters.LocalIPPort_{k}{1}) )
                            parameter_callback = '';
                            match_tcp_ports = match_tcp_ports + 1;
                            %Update the number of matched TCP Pairs
                            codertarget.resourcemanager.set(current_block,'TCP','MatchTcpPorts',match_tcp_ports);
                            registerMatchedPorts(local_port);
                        end
                    end
                end
            elseif(strcmp(ConnMode,'Client') && (isfield(modelBlockStruct.parameters,'TCPReceiveClient')))

                Num_TCP_Receive_Client = length(modelBlockStruct.parameters.TCPReceiveClient);
                for j = 1:Num_TCP_Receive_Client
                    for k = 1:N
                        %Check if the local port of any of the TCP Receive (Client) blocks
                        %matches the local port of current TCP Send (CLient) block.
                        if( isequal( modelBlockStruct.parameters.TCPReceiveClient{j}{2}, modelBlockStruct.parameters.LocalIPPort_{k}{2} ) &&...
                                isequal(local_port,modelBlockStruct.parameters.LocalIPPort_{k}{1}) )
                            parameter_callback = '';
                            match_tcp_ports = match_tcp_ports + 1;
                            %Update the number of matched TCP Pairs
                            codertarget.resourcemanager.set(current_block,'TCP','MatchTcpPorts',match_tcp_ports);
                            registerMatchedPorts(local_port);
                        end
                    end
                end
            end
        end
    end
end

%Register Matched TCP Ports
    function registerMatchedPorts(localPort)
        %This function ensures that only 1 pair of TCP Send/Receive can
        %have the same local port. Without this function, 
        %2 TCP Send (or Receive) and 1 TCP Receive (or Send) will be
        %allowed, which is incorrect.
        options.familyName = 'TCPConnections';
        options.parameterName = 'TCPMatchedPorts';
        options.parameterValue = localPort;
        options.parameterCallback = {'allDifferent'};
        options.blockCallback = [];
        options.targetPrefCallback = '';
        options.errorID = 'freedomk64f:blocks:EthernetPortConflict';
        options.errorArgs = localPort;
        lf_registerBlockCallbackInfo(options);
    end
%%
%3. No two Ethernet blocks can have the same local port.
%Registering the Local Port for UDP/TCP Send and Receive blocks
opts.familyName = 'Ports';
opts.parameterName = 'LocalIPPort_';
opts.parameterValue = local_port;
opts.parameterCallback = parameter_callback;
%Using the error message appropriately based on the nature of conflict.
if ( strcmp(local_port,'67') || strcmp(local_port,'68') )
    %Conflict between DHCP and UDP block
    a = 'freedomk64f:blocks:DHCPPortConflict';
else
    %Conflict between 2 Ethernet blocks
    a = 'freedomk64f:blocks:EthernetPortConflict';
end
opts.errorID =a;
opts.blockCallback = [];
opts.errorArgs = local_port;
opts.targetPrefCallback = [];
lf_registerBlockCallbackInfo(opts);


%% Check for DHCP Ports
% 4. If DHCP is used in the model, register the Ports only once even if
%multiple UDP blocks are present in the model.
if (isequal(ctd.Ethernet.DhcpEnabled,1))
    if( isequal(local_port,'67') || isequal(local_port,'68') )
        DAStudio.error('freedomk64f:blocks:DHCPPortConflict',local_port,family_name);
    end
end

%% Instances
%Retrieve the updated 'match_tcp_ports'
match_tcp_ports = codertarget.resourcemanager.get('','TCP','MatchTcpPorts',getActiveConfigSet(bdroot));
if( any(contains(family_name,["UDPSend","UDPReceive"])) )
    % 5.a. Allow maximum of 6 UDP blocks in the model. With DHCP on, the
    % maximum is restricted to 5.
    opts.familyName = 'UDP';
    opts.parameterName = family_name;
    opts.parameterValue = blkname;
    if ( isequal(ctd.Ethernet.DhcpEnabled,1) )
        opts.parameterCallback = {'instanceLimit',5};
    else
        opts.parameterCallback = {'instanceLimit',6};
    end
    opts.blockCallback = [];
    opts.targetPrefCallback = '';
    opts.errorID = 'freedomk64f:blocks:EthernetTooManyUDPPorts';
    opts.errorArgs = [];
    lf_registerBlockCallbackInfo(opts);
elseif( any(contains(family_name,["TCPSend","TCPReceive"])) )
    % 5.b. Allow maximum of 6 TCP connections in the model.
    ConnMode = get_param(current_block,'ConnectionMode');
    opts.familyName = 'TCP';
    opts.parameterName = [family_name,ConnMode];
    opts.parameterValue = blkname;
    opts.parameterCallback = {'instanceLimit',6+match_tcp_ports};
    opts.blockCallback = [];
    opts.targetPrefCallback = '';
    opts.errorID = 'freedomk64f:blocks:EthernetTooManyTCPPorts';
    opts.errorArgs = [];
    lf_registerBlockCallbackInfo(opts);
end
%%
%6. Registering the number of UDP/TCP Receive and Send blocks used in the model. This
%number is retrieved in 'onAfterCodeGenHook' and added as a #define, which
%is used in 'MW_Ethernet.c' to decide the buffer size.
if(isfield(modelBlockStruct.parameters,'UDPReceive'))
    codertarget.resourcemanager.set(current_block,'UDP','numUDPReceiveBlks',numel(modelBlockStruct.parameters.UDPReceive));
end

if(isfield(modelBlockStruct.parameters,'UDPSend'))
    codertarget.resourcemanager.set(current_block,'UDP','numUDPSendBlks',numel(modelBlockStruct.parameters.UDPSend));
end

if(isfield(modelBlockStruct.parameters,'TCPReceiveClient'))
    codertarget.resourcemanager.set(current_block,'TCP','numTCPReceiveClientBlks',numel(modelBlockStruct.parameters.TCPReceiveClient));
end

if(isfield(modelBlockStruct.parameters,'TCPReceiveServer'))
    codertarget.resourcemanager.set(current_block,'TCP','numTCPReceiveServerBlks',numel(modelBlockStruct.parameters.TCPReceiveServer));
end

if(isfield(modelBlockStruct.parameters,'TCPSendClient'))
    codertarget.resourcemanager.set(current_block,'TCP','numTCPSendClientBlks',numel(modelBlockStruct.parameters.TCPSendClient));
end

if(isfield(modelBlockStruct.parameters,'TCPSendServer'))
    codertarget.resourcemanager.set(current_block,'TCP','numTCPSendServerBlks',numel(modelBlockStruct.parameters.TCPSendServer));
end

%%
%7. Check TCP Client connections. If 2 TCP Send/Receive blocks in Client
%mode are connected to same RemoteIP-Port combination, report Error
if( contains(system_name,'TCP') )
    ConnMode = get_param(current_block,'ConnectionMode');
    if strcmp(ConnMode,'Client')
        %Check client connection already exists
        opts.familyName = family_name;
        opts.parameterName = {[opts.familyName 'Client_connection']};
        remoteAddr = get_param(current_block, 'RemoteIPAddress_');
        remotePort = get_param(current_block, 'ServerIPPort_');
        connHook = strcat(remoteAddr,':',remotePort);
        opts.parameterValue = {connHook};
        opts.errorArgs = connHook;
        opts.parameterCallback = {'allDifferent'};
        opts.errorID ={'freedomk64f:blocks:ClientConnectionConflict'};
        opts.errorArgs = {connHook,family_name};
        lf_registerBlockCallbackInfo(opts);
        
    end
end
end
