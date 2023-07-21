classdef mirror_real< handle %% This mirror takes inputs in millivolts!!
    properties
        serial % Serial connection
        port
        baud
        voltages = zeros(55,1); % voltages log
        max_voltage = 50*1000; % default value in millivolts
        channels = 55; % number of channels
        isconnected = 0;
        movements = 0;
    end
    methods
        function obj = mirror_real(port,baud)
            % When mirror object is defined, a connection is established
            obj.port = port;

            if ~isstring(obj.port)
                error('Port must be a string. eg. "COM4"')
            end

            obj.baud = baud;
            initialiseDriver(obj)
        end

        function setChannel(obj,volt,chan)
            check_connection(obj);
            if abs(volt) > obj.max_voltage
                fprintf('Too much voltage, reduced to limits')
                volt = round(volt/obj.max_voltage)*obj.max_voltage;
            elseif chan > obj.channels || chan < 1
                error('Incorrect Channel')
            end

            msg = sprintf('%d %d set_output',volt,chan);
            pause(0.01) % This needs a pause or some channels are not written correctly
            writeline(obj.serial,msg)
            obj.voltages(chan) = volt; % Logging the voltage.
            obj.movements = obj.movements + 1;
        end

        function setChannels(obj,volts)
            check_connection(obj)
            if isscalar(volts)
                msg = sprintf("%d set_all_outputs", volts);
                writeline(obj.serial, msg)
                pause(0.01)
                volts = volts * ones(obj.channels,1);
            else     
                changes = (find(volts~=obj.voltages));
                if isempty(changes)
                    fprintf("Mirror already in this position\n")
                end
                for i = transpose(changes)
                        setChannel(obj,volts(i),i)
                end
            end
            obj.voltages = volts;
            
        end

        function degaus(obj)
            for i = 1:obj.channels
                for v = linspace(-30,30,5)
                    setChannel(obj,v,i)
                end
            end
            setChannels(obj,0)
        end
        function disconnect(obj)
            check_connection(obj)
            obj.serial = [];
            obj.isconnected = 0;
            fprintf('Connection closed\n');
        end
        function initialiseDriver(obj)
            if obj.isconnected
                warning('Driver is already initialised. Skipping initialisation...')
                return
            end
            % Open serial port
            obj.serial = serialport(obj.port,obj.baud);

            % carriage return terminator
            configureTerminator(obj.serial,"CR"); % CR = carriage return
            % initial command of 3 * '~' sent to drop out of the device's legacy mode
            writeline(obj.serial,"~~~");
            pause(0.1) % give it time to write
            flush(obj.serial) % flush(device) clears serial port device buffers
            pause(0.1) % give it time to clear
            write(obj.serial,13,'char');
            readString = readline(obj.serial);
            % print to console the received response
            %fprintf(readString);
            stringCheck = strfind(readString, 'ok'); % sending carriage returns to driver box gives the output 'ok'
            if stringCheck > 0
                fprintf("\r\nMirror now ready to receive commands\r\n");
                obj.isconnected = 1;
            else
                fprintf("\r\nCommunication Error\r\n");
                obj.serial = [];
                obj.isconnected = 0;
                fprintf('Connection closed\n');
            end
        end
        function check_connection(obj)
            if ~obj.isconnected
                error('Driver not connected')
            end
        end
    end
end