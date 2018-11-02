function fxos8700Callback(varargin)
%I2CALLBACK Initializes the Digital Read block mask

% Copyright 2015 The MathWorks, Inc.


blk = gcb;
% Check on input "action"
action = varargin{1};
switch action
    case 'MaskInitialization'
%         set_param(blk, 'MaskDescription', DAStudio.message('freedomk64f:blocks:DigitalReadBlockDescription'));
%         set_param(blk, 'MaskHelp','eval(''codertarget.internal.helpView(''''freedomk64f'''' ,''''frdmk64flibdigitalread'''')'');');
%         set_param(blk, 'InitFcn', 'codertarget.freedomk64f.internal.digitalReadCallback(''Validate'');')
%         set_param(blk, 'CloseFcn', 'codertarget.freedomk64f.internal.pinmapOpenFcn(''close'');')
%         set_param(blk, 'DeleteFcn', 'codertarget.freedomk64f.internal.pinmapOpenFcn(''close'');')
    case 'Validate'
        validatefxos8700block(blk);     
        
    otherwise
        error('Unknown callback action "%s"', action)
end
end

function validatefxos8700block(~, varargin)

opts.familyName = 'Accel';
opts.parameterName = 'Accel_Number';
opts.parameterValue = 'Accel';
opts.parameterCallback = {'allDifferent'};
opts.blockCallback = [];
opts.errorID ={'freedomk64f:blocks:AccelModuleAlreadyUsed'};
opts.errorArgs = '';
opts.targetPrefCallback = [];
lf_registerBlockCallbackInfo(opts);

codertarget.freedomk64f.internal.i2cCallback('Validate');

end