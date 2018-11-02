function sciReadCallback(current_block, varargin)
%sciReadCallback Check number of instances of SCI Read block using same
%SCI module.

% Copyright 2016 The MathWorks, Inc.

%registering the SCI Module
scimodulenum = get_param(current_block, 'SCIModule');
opts.familyName = 'SCIRead';
opts.parameterName = 'SCI_ModuleRead';
opts.parameterValue = scimodulenum;
opts.parameterCallback = {'allDifferent'};
opts.blockCallback = [];
opts.errorID ={'freedomk64f:blocks:ModuleAlreadyUsed'};
opts.errorArgs = ['UART' scimodulenum];
opts.targetPrefCallback = [];
lf_registerBlockCallbackInfo(opts);

%registering the GPIO Rx Pin
scimodules = {'0','1','2','3','4'};
current_model = codertarget.utils.getModelForBlock(current_block);
targetdata = get_param(current_model, 'CoderTargetData');
 [~,index] = ismember(scimodulenum,scimodules);
uartdata = targetdata.(['UART' scimodules{index}]);

%Check if a valid Rx pin is chosen
if strcmp(uartdata.Rx_PinSelection,'No connection')
    error(message('freedomk64f:blocks:NoPinSelected',index-1,current_block,'Rx'));
end

RX_pin = uartdata.Rx_PinSelection;
%RX_pin = strsplit(RX_pin);
%RX_pin=RX_pin{1};

opts.familyName = 'GPIO';
opts.parameterName = {'GPIO_Number'};
opts.parameterValue = {RX_pin};
opts.parameterCallback = {{'allDifferent'}};
opts.blockCallback = [];
a = 'freedomk64f:blocks:GPIOPinAlreadyUsedInSCI';
opts.errorID = {a};
opts.errorArgs = {RX_pin,current_block};
opts.targetPrefCallback = [];
lf_registerBlockCallbackInfo(opts);

%Check the SCI module conflict with External Mode
codertarget.freedomk64f.internal.validateSCIModulepins(current_block);

end