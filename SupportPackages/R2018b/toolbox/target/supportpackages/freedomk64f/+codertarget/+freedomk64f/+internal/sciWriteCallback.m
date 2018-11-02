function sciWriteCallback(current_block, varargin)
%sciWriteCallback Check number of instances of SCI Write block using same
%SCI module.

% Copyright 2016 The MathWorks, Inc.

%registering the SCI Module
scimodulenum = get_param(current_block, 'SCIModule');
opts.familyName = 'SCIWrite';
opts.parameterName = 'SCI_ModuleWrite';
opts.parameterValue = scimodulenum;
opts.parameterCallback = {'allDifferent'};
opts.blockCallback = [];
opts.errorID ={'freedomk64f:blocks:ModuleAlreadyUsed'};
opts.errorArgs = ['UART' scimodulenum];
opts.targetPrefCallback = [];
lf_registerBlockCallbackInfo(opts);

%registering the GPIO Tx Pin
scimodules = {'0','1','2','3','4'};
current_model = codertarget.utils.getModelForBlock(current_block);
targetdata = get_param(current_model, 'CoderTargetData');
 [~,index] = ismember(scimodulenum,scimodules);
uartdata = targetdata.(['UART' scimodules{index}]);

%Check if a valid Tx pin is chosen
if strcmp(uartdata.Tx_PinSelection,'No connection')
    error(message('freedomk64f:blocks:NoPinSelected',index-1,current_block,'Tx'));
end

TX_pin = uartdata.Tx_PinSelection;
%TX_pin = strsplit(TX_pin);
%TX_pin=TX_pin{1};

opts.familyName = 'GPIO';
opts.parameterName = {'GPIO_Number'};
opts.parameterValue = {TX_pin};
opts.parameterCallback = {{'allDifferent'}};
opts.blockCallback = [];
a = 'freedomk64f:blocks:GPIOPinAlreadyUsedInSCI';
opts.errorID = {a};
opts.errorArgs = {TX_pin,current_block};
opts.targetPrefCallback = [];
lf_registerBlockCallbackInfo(opts);

%Check the SCI module conflict with External Mode
codertarget.freedomk64f.internal.validateSCIModulepins(current_block);

end