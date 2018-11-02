classdef (StrictDefaults)AnalogInput < matlabshared.svd.AnalogInput ...
        & coder.ExternalDependency
    %AnalogInput Measure the voltage of an analog input pin.
    %
    % The block output emits the voltage as a decimal value (0.0-1.0,
    % minimum to maximum). The maximum voltage is determined by the input
    % reference voltage, VREFH, which defaults to 3.3 volt.

    % Copyright 2015-2016 The MathWorks, Inc.
    
    %#codegen
    properties (Nontunable)
        %Pin Pin
        Pin = uint32(16);
    end
    methods
        function set.Pin(obj,value)
            if ~coder.target('Rtw') && ~coder.target('Sfun')
                if ~isempty(obj.Hw)
                    if ~isValidAnalogPin(obj.Hw,value)
                        error(message('svd:svd:PinNotFound',value,'Analog Input'));
                    end
                end
            end
            obj.Pin = uint32(value);
        end
    end
    
    methods
        function obj = AnalogInput(varargin)
            coder.allowpcode('plain');
            obj.Hw = freedomk64f.Hardware;
            obj.Logo = 'FRDM-K64F';
            setProperties(obj,nargin,varargin{:});
        end     
    end
    
    methods (Access = protected)
        function flag = isInactivePropertyImpl(~,prop)
            % Don't show direction since it is fixed to 'output'
            if isequal(prop, 'Pin') ...
                    || isequal(prop, 'SampleTime')
                flag = false;
            else
                flag = true;
            end
        end
        
        function maskDisplayCmds = getMaskDisplayImpl(obj)
            maskDisplayCmds = { ...
                'color(''white'');',...                                     % Fix min and max x,y co-ordinates for autoscale mask units
                'plot([100,100,100,100]*1,[100,100,100,100]*1);',...
                'plot([100,100,100,100]*0,[100,100,100,100]*0);',...
                'color(''blue'');', ...                                     % Drawing mask layout of the block
                ['text(99, 92, ''' obj.Logo ''', ''horizontalAlignment'', ''right'');'],   ...
                'color(''black'');',...
                'plot([30:70],(sin(2*pi*[0.25:0.01:0.65]*(-5))+1)*15+35)', ...
                ['text(50, 15,' ['''Pin: '  obj.Hw.Pinnames{obj.Pin+1} ''',''horizontalAlignment'', ''center'');' newline] ...
                ]};
        end           
    end
    
    methods (Static)
        function name = getDescriptiveName()
            name = 'NXP FRDM-K64F Board Analog Input';
        end
        
        function b = isSupportedContext(context)
            b = context.isCodeGenTarget('rtw');
        end
        
        function updateBuildInfo(buildInfo, context)
            if context.isCodeGenTarget('rtw')
                sppkgroot = strrep(codertarget.freedomk64f.internal.getSpPkgRootDir(),'\','/');
                isRaccelBuild = strcmp(context.getConfigProp('SystemTargetFile'), 'raccel.tlc');
                if ~isRaccelBuild
                buildInfo.addSourceFiles( {'MW_AnalogInput.c','mw_sdk_interface.c'},fullfile(sppkgroot,'src'));
                end
                addIncludePaths(buildInfo,fullfile(sppkgroot,'include'));
                addIncludeFiles(buildInfo,'MW_AnalogIn.h');
            end
        end
    end
    
    methods(Static, Access=protected)
        function header = getHeaderImpl()
            header = matlab.system.display.Header(mfilename('class'),...
                'ShowSourceLink', false, ...
                'Title','NXP FRDM-K64F Board Analog Input', ...
                'Text', [['Measure the voltage of an analog input Pin.' newline newline] ...
                        'The block outputs the voltage as a decimal value (0.0-1.0, minimum to maximum). ' ....
                        'The maximum voltage is determined by the input reference voltage, VREFH, which defaults to 3.3 volt.' newline newline ...
                        'Enter the Pin parameter as the name mentioned in the View pin map.']);
        end
    end    
end
%[EOF]
