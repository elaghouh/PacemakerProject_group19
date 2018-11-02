classdef (StrictDefaults)I2CMasterRead < matlabshared.svd.I2CMasterRead ...
        & coder.ExternalDependency
    %I2CMasterRead Read data from an I2C slave device or an I2C slave device register.
    %
    %The block outputs the values received as an 1-D uint8 array.
    %
    
    %#codegen
    properties (Nontunable)
        %I2CModule I2C module
        I2CModule = '0';
    end
    properties (Constant, Hidden)
        I2CModuleSet = matlab.system.StringSet({'0','1'})
    end
    methods
        function set.I2CModule(obj,value)
            if ~coder.target('Rtw') && ~coder.target('Sfun')
                if ~isempty(obj.Hw)
                    if ~isValidI2CModule(obj.Hw,value)
                        error(message('svd:svd:ModuleNotFound','I2C',value));
                    end
                end
            end
            obj.I2CModule = value;
        end
    end
    %#codegen
    methods
        function obj = I2CMasterRead(varargin)
            coder.allowpcode('plain');
            obj.Hw = freedomk64f.Hardware;
            obj.Logo = 'FRDM-K64F';
            setProperties(obj,nargin,varargin{:});
        end
    end
    
    methods (Static)
        function name = getDescriptiveName(~)
            name = 'NXP FRDM-K64F Board I2C Master Read';
        end
        
        function b = isSupportedContext(context)
            b = context.isCodeGenTarget('rtw');
        end
        
        function updateBuildInfo(buildInfo, context)
            if context.isCodeGenTarget('rtw')
                sppkgroot = strrep(codertarget.freedomk64f.internal.getSpPkgRootDir(),'\','/');
                isRaccelBuild = strcmp(context.getConfigProp('SystemTargetFile'), 'raccel.tlc');
                if ~isRaccelBuild
                buildInfo.addSourceFiles( {'i2c_api.c','MW_I2C.c','mw_sdk_interface.c'},fullfile(sppkgroot,'src'));
                end                
                addIncludePaths(buildInfo,fullfile(sppkgroot,'include'));
                addIncludeFiles(buildInfo,'MW_I2C.h');
            end
        end
    end
    
    methods(Static, Access=protected)
        function header = getHeaderImpl()
            header = matlab.system.display.Header(mfilename('class'),...
                'ShowSourceLink', false, ...
                'Title','NXP FRDM-K64F Board I2C Master Read', ...
                'Text', ['Read data from an I2C slave device or an I2C slave device register.' newline newline ...
                'The block outputs the values received as an [Nx1] array.']);
        end
    end
end
%[EOF]
