function pushButtonCallback(varargin)
%PUSHBUTTONCALLBACK Initializes the Push Button block mask

% Copyright 2016 The MathWorks, Inc.


blk = gcb;
% Check on input "action"
action = varargin{1};
switch action
    case 'MaskInitialization'
        set_param(blk, 'MaskDescription', DAStudio.message('freedomk64f:blocks:PushButtonBlockDescription'));
        set_param(blk, 'MaskHelp','eval(''codertarget.internal.helpView(''''freedomk64f'''' ,''''frdmk64flibpushbutton'''')'');');
        set_param(blk, 'InitFcn', 'codertarget.freedomk64f.internal.pushButtonCallback(''Validate'');')
        set_param(blk, 'CloseFcn', 'codertarget.freedomk64f.internal.pinmapOpenFcn(''close'');')
        set_param(blk, 'DeleteFcn', 'codertarget.freedomk64f.internal.pinmapOpenFcn(''close'');')
    case 'Validate'
        validateDigitalReadblock(blk);     
        
    otherwise
        error('Unknown callback action "%s"', action)
end
end

function validateDigitalReadblock(current_block, varargin)

pinnum = get_param(current_block, 'Whichswitch');

opts.familyName = 'GPIO';
opts.parameterName = 'GPIO_Number';
opts.parameterValue = pinnum;
opts.parameterCallback = {'allDifferent'};
opts.blockCallback = [];
opts.errorID ={'freedomk64f:blocks:GPIOPinAlreadyUsed'};
opts.errorArgs = pinnum;
opts.targetPrefCallback = [];
lf_registerBlockCallbackInfo(opts);

end