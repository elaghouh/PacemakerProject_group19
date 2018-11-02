classdef (StrictDefaults)I2CMasterWrite < matlabshared.svd.I2CMasterWrite ...
        & coder.ExternalDependency
    %I2CMasterWrite Write data to an I2C slave device or an I2C slave device register.
    %
    %The block accepts a 1-D array of type uint8.
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
    
    methods
        function obj = I2CMasterWrite(varargin)
            coder.allowpcode('plain');
            obj.Hw = freedomk64f.Hardware;
            obj.Logo = 'FRDM-K64F';
            setProperties(obj,nargin,varargin{:});
        end
    end
    
    methods (Static)
        function name = getDescriptiveName(~)
            name = 'NXP FRDM-K64F Board I2C Master Write';
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
                'Title','NXP FRDM-K64F Board I2C Master Write', ...
                'Text', ['Write data to an I2C slave device or an I2C slave device register.' newline newline...
                'The block accepts a [Nx1] or [1xN] array.']);
        end
    end    
end
%[EOF]
