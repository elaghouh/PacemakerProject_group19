classdef (StrictDefaults)PushButton < matlabshared.svd.DigitalRead ...
        & coder.ExternalDependency
    %DigitalRead Read the logical state of a digital input pin.
    
    % Copyright 2015 The MathWorks, Inc.
    
    %#codegen
    properties (Nontunable)
        %Pin Pin
        Pin = uint32(45);
    end
    methods
        function set.Pin(obj,value)
            if ~coder.target('Rtw') && ~coder.target('Sfun')
                if ~isempty(obj.Hw)
                    if ~isValidDigitalPin(obj.Hw,value)
                        error(message('svd:svd:PinNotFound',value,'Push Button'));
                    end
                end
            end
            obj.Pin = uint32(value);
        end
    end
    
    methods
        function obj = PushButton(varargin)
            coder.allowpcode('plain');
            obj.Hw = freedomk64f.Hardware;
            obj.Logo = 'FRDM-K64F';
            setProperties(obj,nargin,varargin{:});
        end
    end
    
    methods (Static)
        function name = getDescriptiveName()
            name = 'NXP FRDM-K64F Board Push Button';
        end
        
        function b = isSupportedContext(context)
            b = context.isCodeGenTarget('rtw');
        end
        
        function updateBuildInfo(buildInfo, context)
            if context.isCodeGenTarget('rtw')
                sppkgroot = strrep(codertarget.freedomk64f.internal.getSpPkgRootDir(),'\','/');
                isRaccelBuild = strcmp(context.getConfigProp('SystemTargetFile'), 'raccel.tlc');
                if ~isRaccelBuild
                buildInfo.addSourceFiles( {'MW_digitalIO.c','mw_sdk_interface.c'},fullfile(sppkgroot,'src'));
                end
                addIncludePaths(buildInfo,fullfile(sppkgroot,'include'));
                addIncludeFiles(buildInfo,'MW_digitalIO.h');
            end
        end
    end
    methods(Static, Access=protected)
        function header = getHeaderImpl()
            header = matlab.system.display.Header(mfilename('class'),...
                'ShowSourceLink', false, ...
                'Title','NXP FRDM-K64F Board Push Button', ...
                'Text', [['Read the logical state of a digital input Pin.' newline newline] ...
                'The block outputs the logical state of a digital input Pin.' newline newline ...
                'Enter the Pin parameter as the name mentioned in the View pin map.']);
        end
    end
    methods (Access=protected)
        function maskDisplayCmds = getMaskDisplayImpl(obj)
            x = 1:22;
            y = double(abs(0:1/10:1)>=0.5);
            y = [y flip(y)];
            x = [x(1:5) 5.999 x(6:17) 17.001 x(18:end)]+28;
            y = [y(1:5) 0 y(6:17) 0 y(18:end)]*45+30;
            x = [x x+21];
            y = [y y];
            maskDisplayCmds = [ ...
                ['color(''white'');', newline]...                                     % Fix min and max x,y co-ordinates for autoscale mask units
                ['plot([100,100,100,100],[100,100,100,100]);', newline]...
                ['plot([0,0,0,0],[0,0,0,0]);', newline]...
                ['color(''blue'');', newline] ...                                     % Drawing mask layout of the block
                ['text(99, 92, ''' obj.Logo ''', ''horizontalAlignment'', ''right'');', newline] ...
                ['color(''black'');', newline] ...
                ['plot([' num2str(x) '],[' num2str(y) ']);', newline], ...
                ['text(50, 15,' ['''Pin: '  obj.Hw.Pinnames{obj.Pin+1} ''',''horizontalAlignment'', ''center'');' newline] ...
                ]];
        end
    end
end
%[EOF]
