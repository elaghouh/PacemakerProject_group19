classdef (StrictDefaults)PWMOutput < matlabshared.svd.PWMOutput ...
        & coder.ExternalDependency
    %PWMOutput Generate pulse waveform on the specified PWM output pin.
    % The block input controls the duty cycle of the pulse waveform. An
    % input value of 0 produces a 0 percent duty cycle and an input value
    % of 100 produces a 100 percent duty cycle.

    % Copyright 2015-2018 The MathWorks, Inc.
    
    %#codegen
    properties (Nontunable)
        %Pin Pin
        Pin = uint32(3);
    end
    methods
        function set.Pin(obj,value)
            if ~coder.target('Rtw') && ~coder.target('Sfun')
                if ~isempty(obj.Hw)
                    if ~isValidPWMPin(obj.Hw,value)
                        error(message('svd:svd:PinNotFound',value,'PWM Output'));
                    end
                end
            end
            obj.Pin = uint32(value);
        end
    end
    
    methods
        function obj = PWMOutput(varargin)
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
                    || isequal(prop, 'InitialFrequency') ...
                    || isequal(prop, 'InitialDutyCycle')
                flag = false;
            else
                flag = true;
            end
        end
        
      function maskDisplayCmds = getMaskDisplayImpl(obj)
            x = 1:12;
            y = double(abs(0:1/5:1)>=0.5);
            y = [y flip(y)];
            x = [x(1:3) 3.999 x(4:9) 9.001 x(10:end)];
            y = [y(1:3) 0 y(4:9) 0 y(10:end)]*45+30;
            x = [x x+11];
            y = [y y];
            
            x1 = 1:32;
            y1 = double(abs(0:1/15:1)>=0.5);
            y1 = [y1 flip(y1)];
            x1 = [x1(1:8) 8.999 x1(9:24) 24.001 x1(25:end)];
            y1 = [y1(1:8) 0 y1(9:24) 0 y1(25:end)]*45+30;
            
            x = [x x1+x(end)]+22;
            y = [y y1];
            maskDisplayCmds = [ ...
                ['color(''white'');' newline], ...                                     % Fix min and max x,y co-ordinates for autoscale mask units
                ['plot([100,100,100,100]*1,[100,100,100,100]*1);' newline],...
                ['plot([100,100,100,100]*0,[100,100,100,100]*0);' newline],...
                ['color(''blue'');' newline], ...                                     % Drawing mask layout of the block
                ['text(99, 92, ''' obj.Logo ''', ''horizontalAlignment'', ''right'');' newline],   ...
                ['color(''black'');' newline],...
                ['plot([' num2str(x) '],[' num2str(y) '])' newline], ...
                ['text(50, 15,' ['''Pin: '  obj.Hw.Pinnames{obj.Pin+1} ''',''horizontalAlignment'', ''center'');' newline] ...
                ]];
        end        
    end
    
    methods (Static)
        function name = getDescriptiveName()
            name = 'NXP FRDM-K64F Board PWM Output';
        end
        
        function b = isSupportedContext(context)
            b = context.isCodeGenTarget('rtw');
        end
        
        function updateBuildInfo(buildInfo, context)
            if context.isCodeGenTarget('rtw')
                % PWM Output interface
                sppkgroot = strrep(codertarget.freedomk64f.internal.getSpPkgRootDir(),'\','/');
                isRaccelBuild = strcmp(context.getConfigProp('SystemTargetFile'), 'raccel.tlc');
                if ~isRaccelBuild
                buildInfo.addSourceFiles( {'MW_PWM.c','mw_sdk_interface.c'},fullfile(sppkgroot,'src'));
                end
                addIncludePaths(buildInfo,fullfile(sppkgroot,'include'));
                addIncludeFiles(buildInfo,'MW_PWM.h');
            end
        end
    end

        methods (Static, Access = protected)
        % Header for System object display
        function header = getHeaderImpl()
            filename=fullfile(codertarget.freedomk64f.internal.getSpPkgRootDir, 'resources', 'k64f_pinlayout.png');
            header = matlab.system.display.Header(mfilename('class'),...
                'ShowSourceLink', false, ...
                'Title','NXP FRDM-K64F Board PWM Output', ...
                'Text', ['Generate pulse waveform on the specified output Pin.' newline newline ...
                'The block input accepts the values between 0 to 100. The input controls the duty cycle of the square waveform. An' ...
                ' input value of 0 produces a 0 percent duty cycle and an input value' ...
                [' of 100 produces a 100 percent duty cycle.' newline newline], ...
                'Enter the Pin parameter as the name mentioned in the <a href="matlab:imshow(''' filename ''')">View pin map</a>.']);
        end
    end
end
%[EOF]
