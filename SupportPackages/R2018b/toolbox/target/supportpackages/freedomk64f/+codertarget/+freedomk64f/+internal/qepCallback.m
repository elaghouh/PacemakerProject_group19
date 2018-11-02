function qepCallback(varargin)
%qepCallback validateses the QEP block mask

% Copyright 2016 The MathWorks, Inc.

blk = gcb;
% Check on input "action"
action = varargin{1};
switch action
    case 'MaskInitialization'
     
    case 'Validate'
        validateQEPblock(blk);     
        
    otherwise
        error('Unknown callback action "%s"', action)
end
end

function validateQEPblock(varargin)

opts.familyName = 'GPIO';
opts.parameterName = {'GPIO_Number';'GPIO_Number'};
opts.parameterValue = {'PTB18';'PTB19'};
opts.parameterCallback = {{'allDifferent'}; {'allDifferent'}};
opts.blockCallback = [];
a = 'freedomk64f:blocks:GPIOPinAlreadyUsed';
opts.errorID = {a;a};
opts.errorArgs = {opts.parameterValue{1};opts.parameterValue{2}};
opts.targetPrefCallback = [];
lf_registerBlockCallbackInfo(opts);

end