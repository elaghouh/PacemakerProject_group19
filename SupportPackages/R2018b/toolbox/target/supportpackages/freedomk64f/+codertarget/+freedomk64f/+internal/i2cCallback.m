function i2cCallback(varargin)
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
        validateI2Cblock(blk);     
        
    otherwise
        error('Unknown callback action "%s"', action)
end
end

function validateI2Cblock(current_block, varargin)
global modelBlockStruct;

if (strcmp(get_param(current_block,'MaskType'),'freedomk64f.fxos8700'))
    I2CModule = '0';
else
    I2CModule = get_param(current_block, 'I2CModule');
end
parameter_name = 'GPIO_Number';
family_name = strrep(get_param(current_block,'MaskType'),'.','_');
opts.familyName = family_name;
opts.parameterName = {'GPIO_Number';'GPIO_Number'};

if strcmp(I2CModule,'0')
    pins = {'PTE24 (D15)';'PTE25 (D14)'};
else
    pins = {'PTC10 (A5)';'PTC11 (A4)'};
end
opts.parameterValue = pins;

parameter_callback = 'allDifferent';

if ~isempty(modelBlockStruct) && isfield(modelBlockStruct.parameters, parameter_name)
    params = modelBlockStruct.parameters.(parameter_name);
    for i = 1:numel(params)
        blk_family_name =strrep(get_param(params{i}{2}, 'MaskType'),'.','_');
        if (strcmp(params{i}{1}, pins{1}) || strcmp(params{i}{1}, pins{2})) && ...  % Checking for same pin number
                (strcmp(blk_family_name, 'freedomk64f_I2CMasterWrite') || ...
                strcmp(blk_family_name, 'freedomk64f_I2CMasterRead') || ...
                strcmp(blk_family_name, 'freedomk64f_fxos8700'))   % Checking for same family
            parameter_callback = '';
        end 
    end
end

opts.parameterCallback = {{parameter_callback}; {parameter_callback}};
opts.blockCallback = [];
a = 'freedomk64f:blocks:GPIOPinAlreadyUsed';
opts.errorID = {a;a};
opts.errorArgs = opts.parameterValue;
opts.targetPrefCallback = [];
lf_registerBlockCallbackInfo(opts);

end