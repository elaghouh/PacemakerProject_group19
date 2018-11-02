classdef (StrictDefaults)fxos8700 < matlab.System & ...
        matlab.system.mixin.Propagates & ...
        matlabshared.svd.BlockSampleTime & ...
        matlab.system.mixin.internal.CustomIcon & ...
        coder.ExternalDependency
    %fxos8700 FXOS8700CQ 6-axes sensor class
    %   This class is to create FXOS8700 6-axes sensor block.
    
    % Copyright 2016 The MathWorks, Inc.    
    
    %#codegen
    
    properties (Access=private,Nontunable)
        Address=uint8(hex2dec('1D'));
    end
    
    properties (Nontunable)
        %Active sensor
        Activesensor = 'Accelerometer only';
        %Sensor output data rate (ODR)
        ODR = '800Hz';
        %Sensor output data rate (ODR)
        HybridODR = '400Hz';
        %Acceleration full scale range
        Accelfullrange = '-4g to +4g';
    end
    
    properties (Hidden,Constant)
        % Properties String Set
        ActivesensorSet = matlab.system.StringSet({'Accelerometer only','Magnetometer only','Accelerometer and Magnetometer'});
        ODRSet = matlab.system.StringSet({'800Hz','400Hz','200Hz','100Hz','50Hz','12.5Hz','6.25Hz','1.5625Hz'});
        HybridODRSet = matlab.system.StringSet({'400Hz','200Hz','100Hz','50Hz','25Hz','6.25Hz','3.125Hz','0.7813Hz'});
        AccelfullrangeSet = matlab.system.StringSet({'-2g to +2g','-4g to +4g','-8g to +8g'});
        % XYZ Data Registers
        OUT_X_MSB_REG = uint8(1);
        OUT_X_LSB_REG = uint8(2);
        OUT_Y_MSB_REG = uint8(3);
        OUT_Y_LSB_REG = uint8(4);
        OUT_Z_MSB_REG = uint8(5);
        OUT_Z_LSB_REG = uint8(6);
        
        CTRL_REG1=uint8(hex2dec('2a'));
        CTRL_REG2=uint8(hex2dec('2b'));
        CTRL_REG3=uint8(hex2dec('2c'));
        % CTRL_REG4 Interrupt Enable Register
        CTRL_REG4=uint8(hex2dec('2d'));
        % CTRL_REG5 Interrupt Configuration Register
        CTRL_REG5=uint8(hex2dec('2e'));
        % XYZ Offset Correction Registers
        OFF_X_REG=uint8(hex2dec('2f'));
        OFF_Y_REG=uint8(hex2dec('30'));
        OFF_Z_REG=uint8(hex2dec('31'));
        % M_DR_STATUS Register
        M_DR_STATUS_REG=uint8(hex2dec('32'));
        % MAG XYZ Data Registers
        M_OUT_X_MSB_REG = uint8(hex2dec('33'));
        M_OUT_X_LSB_REG = uint8(hex2dec('34'));
        M_OUT_Y_MSB_REG = uint8(hex2dec('35'));
        M_OUT_Y_LSB_REG = uint8(hex2dec('36'));
        M_OUT_Z_MSB_REG = uint8(hex2dec('37'));
        M_OUT_Z_LSB_REG = uint8(hex2dec('38'));
        % MAG CMP Data Registers
        CMP_X_MSB_REG = uint8(hex2dec('39'));
        CMP_X_LSB_REG = uint8(hex2dec('3A'));
        CMP_Y_MSB_REG = uint8(hex2dec('3B'));
        CMP_Y_LSB_REG = uint8(hex2dec('3C'));
        CMP_Z_MSB_REG = uint8(hex2dec('3D'));
        CMP_Z_LSB_REG = uint8(hex2dec('3E'));
        % MAG XYZ Offset Correction Registers
        M_OFF_X_MSB_REG =uint8(hex2dec('3F'));
        M_OFF_X_LSB_REG =uint8(hex2dec('40'));
        M_OFF_Y_MSB_REG =uint8(hex2dec('41'));
        M_OFF_Y_LSB_REG =uint8(hex2dec('42'));
        M_OFF_Z_MSB_REG =uint8(hex2dec('43'));
        M_OFF_Z_LSB_REG =uint8(hex2dec('44'));
        % MAG MAX XYZ Registers
        MAX_X_MSB_REG = uint8(hex2dec('45'));
        MAX_X_LSB_REG = uint8(hex2dec('46'));
        MAX_Y_MSB_REG = uint8(hex2dec('47'));
        MAX_Y_LSB_REG = uint8(hex2dec('48'));
        MAX_Z_MSB_REG = uint8(hex2dec('49'));
        MAX_Z_LSB_REG = uint8(hex2dec('4A'));
        % MAG MIN XYZ Registers */
        MIN_X_MSB_REG = uint8(hex2dec('4B'));
        MIN_X_LSB_REG = uint8(hex2dec('4C'));
        MIN_Y_MSB_REG = uint8(hex2dec('4D'));
        MIN_Y_LSB_REG = uint8(hex2dec('4E'));
        MIN_Z_MSB_REG = uint8(hex2dec('4F'));
        MIN_Z_LSB_REG = uint8(hex2dec('50'));
        % TEMP Registers
        TEMP_REG = uint8(hex2dec('51'));
        % MAG CTRL_REG1 System Control 1 Register
        M_CTRL_REG1 = uint8(hex2dec('5B'));
        % MAG CTRL_REG2 System Control 2 Register */
        M_CTRL_REG2 = uint8(hex2dec('5C'));
        % XYZ_DATA_CFG Sensor Data Configuration Register
        XYZ_DATA_CFG_REG = uint8(hex2dec('0E'));
    end
    
    properties (Hidden,Nontunable)
        i2cobj;
    end
    
    methods
        function obj = fxos8700()
            coder.allowpcode('plain');
            obj.i2cobj = freedomk64f.I2CMasterWrite;
            obj.i2cobj.I2CModule = '0';
            obj.i2cobj.SlaveAddress = obj.Address;
        end
        
        function varargout = fxosWriteRegister(obj,RegisterAddress,RegisterValue,DataType)
            validateattributes(RegisterAddress,{'numeric'},{'scalar','integer','>=',0,'<=',255},'','RegisterAddress');
            status = writeRegister(obj.i2cobj,RegisterAddress,RegisterValue,DataType);
            if nargout >= 1
                varargout{1} = status;
            end
        end
        
        function [RegisterValue,varargout] = fxosReadRegister(obj,RegisterAddress,DataLength,DataType)
            validateattributes(RegisterAddress,{'numeric'},{'scalar','integer','>=',0,'<=',255},'','RegisterAddress');
            [RegisterValue,status] = readRegister(obj.i2cobj,RegisterAddress,DataLength,DataType);
            if nargout > 1
                varargout{1} = status;
            end
        end
        
%         function accelrange = getAccelfullrangeset(obj)
%             if (strcmp(obj.Accelfullrange,'-2g to +2g'))
%                 accelrange = 0;
%             elseif (strcmp(obj.Accelfullrange,'-4g to +4g'))
%                 accelrange = 1;
%             else
%                 accelrange = 2;
%             end
%         end
%         
%         function ODRval = getSensorODR(obj)
%             if (strcmp(obj.Activesensor,'Accelerometer and Magnetometer'))
%                 if (strcmp(obj.HybridODR,'400Hz'))
%                     ODRval = 0;
%                 elseif (strcmp(obj.HybridODR,'200Hz'))
%                     ODRval = 1;
%                 elseif (strcmp(obj.HybridODR,'100Hz'))
%                     ODRval = 2;
%                 elseif (strcmp(obj.HybridODR,'50Hz'))
%                     ODRval = 3;
%                 elseif (strcmp(obj.HybridODR,'25Hz'))
%                     ODRval = 4;
%                 elseif (strcmp(obj.HybridODR,'6.25Hz'))
%                     ODRval = 5;
%                 elseif (strcmp(obj.HybridODR,'3.125Hz'))
%                     ODRval = 6;
%                 elseif (strcmp(obj.HybridODR,'0.7813Hz'))
%                     ODRval = 7;
%                 end
%             else
%                 if (strcmp(obj.ODR,'800Hz'))
%                     ODRval = 0;
%                 elseif (strcmp(obj.ODR,'400Hz'))
%                     ODRval = 1;
%                 elseif (strcmp(obj.ODR,'200Hz'))
%                     ODRval = 2;
%                 elseif (strcmp(obj.ODR,'100Hz'))
%                     ODRval = 3;
%                 elseif (strcmp(obj.ODR,'50Hz'))
%                     ODRval = 4;
%                 elseif (strcmp(obj.ODR,'12.5Hz'))
%                     ODRval = 5;
%                 elseif (strcmp(obj.ODR,'6.25Hz'))
%                     ODRval = 6;
%                 elseif (strcmp(obj.ODR,'1.5625Hz'))
%                     ODRval = 7;
%                 end
%             end
%         end
        
        function initfxos8700(obj)
            % Initialize I2C and set the bus speed to 100kHz
            open(obj.i2cobj,100000);
            % Reset Device
            fxosWriteRegister(obj, obj.CTRL_REG2, uint8(hex2dec('40')), 'uint8');

            if coder.target('MATLAB') || coder.target('RtwForRapid') || coder.target('RtwForSfun')
                j = 1;
                % wait for a delay
                for i=1:100000
                    j = j +1;
                end
            else
                coder.ceval('OSA_TimeDelay',uint32(500));
            end
            
            % Put the device to standby
            RegisterValue = fxosReadRegister(obj,obj.CTRL_REG1,1,'uint8');
            fxosWriteRegister(obj,obj.CTRL_REG1, bitand(RegisterValue,bitcmp(uint8(01))),'uint8');
            
            %Set the acceleration full range.
            fxosWriteRegister(obj, obj.XYZ_DATA_CFG_REG, uint8(getAccelfullrangeset(obj)),'uint8');
            if (strcmp(obj.Activesensor,'Accelerometer and Magnetometer'))
                % set up Mag OSR and Hybrid mode using M_CTRL_REG1
                fxosWriteRegister(obj, obj.M_CTRL_REG1, uint8(hex2dec('03')),'uint8');
                % Enable hyrid mode auto increment using M_CTRL_REG2
                fxosWriteRegister(obj, obj.M_CTRL_REG2, uint8(hex2dec('20')),'uint8');
            elseif (strcmp(obj.Activesensor,'Magnetometer only'))
                % set up Mag OSR and Magnetometer only mode using M_CTRL_REG1
                fxosWriteRegister(obj, obj.M_CTRL_REG1, uint8(hex2dec('01')),'uint8');
            else
                % set up Accelerometer only mode using M_CTRL_REG1
                fxosWriteRegister(obj, obj.M_CTRL_REG1, uint8(hex2dec('00')),'uint8');
            end
            
            % Setup the ODR for the selected mode and activate the sensor */
            fxosWriteRegister(obj, obj.CTRL_REG1, bitor(uint8(bitshift(getSensorODR(obj),3)),uint8(1)),'uint8');
        end
        
        function [magn,accel,varargout] = readAccelMangnticField(obj)
            [RegisterValue, status] = fxosReadRegister(obj,obj.OUT_X_MSB_REG,6,'int16');
            accel = double(bitshift(RegisterValue(1:3),-2))*(2^getAccelfullrangeset(obj))*0.244/1000;
            accel = accel';
            magn = double(RegisterValue(4:6))*0.1;
            magn = magn';
            
            if nargout > 2
                varargout{1} = status;
            end
        end
        
        function [accel,varargout] = readAccelField(obj)
            [RegisterValue, status] = fxosReadRegister(obj,obj.OUT_X_MSB_REG,3,'int16');
            accel = double(bitshift(RegisterValue(1:3),-2))*(2^getAccelfullrangeset(obj))*0.244/1000;
            accel = accel';
            
            if nargout > 2
                varargout{1} = status;
            end
        end
        
        function [magn,varargout] = readMangnticField(obj)
            [RegisterValue, status] = fxosReadRegister(obj,obj.M_OUT_X_MSB_REG,3,'int16');
            magn = double(RegisterValue(1:3))*0.1;
            magn = magn';
            
            if nargout > 2
                varargout{1} = status;
            end
        end
    end
    
    methods (Access = protected)
        function setupImpl(obj)
            initfxos8700(obj);
        end
        
        function releaseImpl(obj)
            % Release resources, such as file handles
            close(obj.i2cobj);
        end
        
        function num = getNumInputsImpl(~)
            % Define total number of inputs for system with optional inputs
            num = 0;
            % if obj.UseOptionalInput
            %     num = 2;
            % end
        end
        
        function num = getNumOutputsImpl(obj)
            % Define total number of outputs for system with optional
            % outputs
            
            if (strcmp(obj.Activesensor,'Accelerometer and Magnetometer'))
                num = 2;
            else
                num = 1;
            end
        end
        
        function flag = isInactivePropertyImpl(obj,propertyName)
            % Return false if property is visible based on object
            % configuration, for the command line and System block dialog
            %flag = false;
            if strcmp(propertyName,'Accelfullrange')
                if (strcmp(obj.Activesensor,'Magnetometer only'))
                    flag = true;
                else
                    flag = false;
                end
            elseif strcmp(propertyName,'ODR')
                if (strcmp(obj.Activesensor,'Accelerometer and Magnetometer'))
                    flag = true;
                else
                    flag = false;
                end
            elseif strcmp(propertyName,'HybridODR')
                if (strcmp(obj.Activesensor,'Accelerometer and Magnetometer'))
                    flag = false;
                else
                    flag = true;
                end
            else
                flag = false;
            end
        end
        
        function varargout = getOutputNamesImpl(obj)
            if (strcmp(obj.Activesensor,'Accelerometer and Magnetometer'))
                varargout{1} = 'Magnet';
                varargout{2} = 'Accel';
            elseif (strcmp(obj.Activesensor,'Accelerometer only'))
                varargout{1} = 'Accel';
            elseif (strcmp(obj.Activesensor,'Magnetometer only'))
                varargout{1} = 'Magnet';
            end
        end
        
        function varargout = getOutputSizeImpl(obj)
            % Return size for each output port
            %accel = [1 3];
            %magnet = [1 3];
            if (strcmp(obj.Activesensor,'Accelerometer and Magnetometer'))
                varargout{1} = [1 3];
                varargout{2} = [1 3];
            else
                varargout{1} = [1 3];
            end
        end
        
        function varargout = getOutputDataTypeImpl(obj)
            % Return data type for each output port
            %             varargout{1} = 'double';
            %             varargout{2} = 'double';
            if (strcmp(obj.Activesensor,'Accelerometer and Magnetometer'))
                varargout{1} = 'double';
                varargout{2} = 'double';
            else
                varargout{1} = 'double';
            end
        end
        
        function varargout = isOutputComplexImpl(~)
            % Return true for each output port with complex data
            varargout{1} = false;
            varargout{2} = false;
        end
        
        function varargout = isOutputFixedSizeImpl(~)
            % Return true for each output port with fixed size
            varargout{1} = true;
            varargout{2} = true;
        end
        
        function varargout = stepImpl(obj)
            if isequal(obj.Activesensor,'Accelerometer and Magnetometer')
                [varargout{1}, varargout{2}] = readAccelMangnticField(obj);
            elseif isequal(obj.Activesensor,'Accelerometer only')
                varargout{1} = readAccelField(obj);
            else % isequal(obj.Activesensor,'Magnetometer only')
                varargout{1} = readMangnticField(obj);
            end
        end
        
        function maskDisplayCmds = getMaskDisplayImpl(obj)
            inport_label = [];
            num = getNumInputsImpl(obj);
            if num > 0
                inputs = cell(1,num);
                [inputs{1:num}] = getInputNamesImpl(obj);
                for i = 1:num
                    inport_label = [inport_label 'port_label(''input'',' num2str(i) ',''' inputs{i} ''');' char(10)]; %#ok<AGROW>
                end
            end
            
            outport_label = [];
            num = getNumOutputsImpl(obj);
            if num > 0
                outputs = cell(1,num);
                [outputs{1:num}] = getOutputNamesImpl(obj);
                for i = 1:num
                    outport_label = [outport_label 'port_label(''output'',' num2str(i) ',''' outputs{i} ''');' char(10)]; %#ok<AGROW>
                end
            end
            
            if (strcmp(obj.Activesensor,'Accelerometer and Magnetometer'))
                acceloffsetx = 'accoffsetx = 27;';
                acceloffsety = 'accoffsety = 30;';
            elseif (strcmp(obj.Activesensor,'Magnetometer only'))
                acceloffsetx = 'accoffsetx = 23;';
                acceloffsety = 'accoffsety = 15;';
            else
                acceloffsetx = 'accoffsetx = 45;';
                acceloffsety = 'accoffsety = 50;';
            end
            
            maskimageaccel = [...
                ['pos = [0 1/2 5/4] * pi;' char(10)]...
                [acceloffsetx char(10)]...
                [acceloffsety char(10)]...
                ['accrad = 50;' char(10)]...
                ['x = accrad*cos(pos)/2+accoffsetx;' char(10)]...
                ['y = accrad*sin(pos)/2+accoffsety;' char(10)]...
                ['plot([accoffsetx x(1)],[accoffsety y(1)]);' char(10)]...
                ['plot([accoffsetx x(2)],[accoffsety y(2)]);' char(10)]...
                ['plot([accoffsetx x(3)],[accoffsety y(3)]);' char(10)]...
                ['p1_angle = 0;' char(10)]...
                ['p2_angle = 5*pi/180;' char(10)]...
                ['p3_angle = -5*pi/180;' char(10)]...
                ['rad = accrad*0.85/2;' char(10)]...
                ['rad1 = accrad*1/2;' char(10)]...
                ['ptsx = [rad1*cos(p1_angle) rad*cos(p2_angle) rad*cos(p3_angle)]+accoffsetx;' char(10)]...
                ['ptsy = [rad1*sin(p1_angle) rad*sin(p2_angle) rad*sin(p3_angle)]+accoffsety;' char(10)]...
                ['patch(ptsx,ptsy,[0 0 0]);' char(10)]...
                ['ptsx1 = [rad1*cos(p1_angle+pi/2) rad*cos(p2_angle+pi/2) rad*cos(p3_angle+pi/2)]+accoffsetx+1.2;' char(10)]...
                ['ptsy1 = [rad1*sin(p1_angle+pi/2) rad*sin(p2_angle+pi/2) rad*sin(p3_angle+pi/2)]+accoffsety;' char(10)]...
                ['patch(ptsx1,ptsy1,[0 0 0]);' char(10)]...
                ['ptsx2 = [rad1*cos(p1_angle+5*pi/4) rad*cos(p2_angle+5*pi/4) rad*cos(p3_angle+5*pi/4)]+accoffsetx;' char(10)]...
                ['ptsy2 = [rad1*sin(p1_angle+5*pi/4) rad*sin(p2_angle+5*pi/4) rad*sin(p3_angle+5*pi/4)]+accoffsety;' char(10)]...
                ['patch(ptsx2,ptsy2,[0 0 0]);' char(10)]...
                ];
            maskimagemagnet = [...
                ['r = 0.15*100;' char(10)]...
                [acceloffsetx char(10)]...
                [acceloffsety char(10)]...
                ['offsetx = 20+accoffsetx;' char(10)]...
                ['offsety = 35+accoffsety;' char(10)]...
                ['theta = linspace(0,2*pi);' char(10)]...
                ['x = r*cos(theta) + offsetx;' char(10)]...
                ['y = r*sin(theta) + offsety;' char(10)]...
                ['plot(x,y);' char(10)]...
                ['u1 = [offsetx-r/4 offsetx offsetx+r/4];' char(10)]...
                ['u2 = [offsety offsety+r-2     offsety];' char(10)]...
                ['plot(u1,u2);' char(10)]...
                ['d1 = [offsetx-r/4 offsetx offsetx+r/4]+1;' char(10)]...
                ['d2 = [offsety offsety-r+2 offsety];' char(10)]...
                ['patch(d1,d2,[0 0 0]);' char(10)]...
                ];
            
            if (strcmp(obj.Activesensor,'Magnetometer only'))
                maskimageaccel = '';
            elseif (strcmp(obj.Activesensor,'Accelerometer only'))
                maskimagemagnet = '';
            end
            
            maskDisplayCmds = [ ...
                ['color(''white'');', char(10)]...                                     % Fix min and max x,y co-ordinates for autoscale mask units
                ['plot([100,100,100,100],[100,100,100,100]);', char(10)]...
                ['plot([0,0,0,0],[0,0,0,0]);', char(10)]...
                ['color(''blue'');', char(10)] ...                                     % Drawing mask layout of the block
                ['text(99, 92, ''' obj.i2cobj.Logo ''', ''horizontalAlignment'', ''right'');', char(10)] ...
                ['color(''black'');', char(10)] ...
                [maskimageaccel maskimagemagnet char(10)] ...
                inport_label, ...
                outport_label, ...
                ];
        end
    end
    
    % Internal functions
    methods (Access = protected)
        function accelrange = getAccelfullrangeset(obj)
            if (strcmp(obj.Accelfullrange,'-2g to +2g'))
                accelrange = 0;
            elseif (strcmp(obj.Accelfullrange,'-4g to +4g'))
                accelrange = 1;
            else
                accelrange = 2;
            end
        end
        
        function ODRval = getSensorODR(obj)
            if (strcmp(obj.Activesensor,'Accelerometer and Magnetometer'))
                if (strcmp(obj.HybridODR,'400Hz'))
                    ODRval = 0;
                elseif (strcmp(obj.HybridODR,'200Hz'))
                    ODRval = 1;
                elseif (strcmp(obj.HybridODR,'100Hz'))
                    ODRval = 2;
                elseif (strcmp(obj.HybridODR,'50Hz'))
                    ODRval = 3;
                elseif (strcmp(obj.HybridODR,'25Hz'))
                    ODRval = 4;
                elseif (strcmp(obj.HybridODR,'6.25Hz'))
                    ODRval = 5;
                elseif (strcmp(obj.HybridODR,'3.125Hz'))
                    ODRval = 6;
                elseif (strcmp(obj.HybridODR,'0.7813Hz'))
                    ODRval = 7;
                end
            else
                if (strcmp(obj.ODR,'800Hz'))
                    ODRval = 0;
                elseif (strcmp(obj.ODR,'400Hz'))
                    ODRval = 1;
                elseif (strcmp(obj.ODR,'200Hz'))
                    ODRval = 2;
                elseif (strcmp(obj.ODR,'100Hz'))
                    ODRval = 3;
                elseif (strcmp(obj.ODR,'50Hz'))
                    ODRval = 4;
                elseif (strcmp(obj.ODR,'12.5Hz'))
                    ODRval = 5;
                elseif (strcmp(obj.ODR,'6.25Hz'))
                    ODRval = 6;
                elseif (strcmp(obj.ODR,'1.5625Hz'))
                    ODRval = 7;
                end
            end
        end
    end
    
    methods (Static)
        function name = getDescriptiveName(~)
            name = 'NXP FRDM-K64F Board FXOS8700';
        end
        
        function b = isSupportedContext(context)
            b = context.isCodeGenTarget('rtw');
        end
        
        function updateBuildInfo(buildInfo, context)
            freedomk64f.I2CMasterWrite.updateBuildInfo(buildInfo, context);
        end
    end
    
    methods(Access = protected, Static)
        function simMode = getSimulateUsingImpl
            % Return only allowed simulation mode in System block dialog
            simMode = 'Interpreted execution';
        end
        
        function flag = showSimulateUsingImpl
            % Return false if simulation mode hidden in System block dialog
            flag = false;
        end
        
        function header = getHeaderImpl()
            header = matlab.system.display.Header(mfilename('class'),...
                'ShowSourceLink', false, ...
                'Title','NXP FRDM-K64F Board FXOS8700CQ 6-Axes Sensor', ...
                'Text', ['Measure linear acceleration and magnetic field along the X, Y and Z axes.' char(10) char(10) ...
                'The block outputs acceleration as a [1x3] vector of double values' char(10) ...
                'in g (9.8 m/s^2) and magnetic field as a [1x3] vector of double values in uT.']);
        end
    end
end
