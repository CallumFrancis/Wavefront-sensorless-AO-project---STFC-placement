
classdef filter_wheel < handle
    properties
        serial
        port
        baud
        isconnected = 0;
        position=0;
        slots = [2,3,3.5,4,4.3,0];

    end
    methods
        function obj = filter_wheel(port,baud)
            obj.port = port;
            if ~isstring(obj.port)
                error('Port must be a string. eg. "COM4"')
            end
            
            obj.baud = baud;
            initialiseDriver(obj)
            obj.setPosition(1)
        end
        function setPosition(obj,position)
            if ~isstring(position) && ~ischar(position)
                position = num2str(position);
            end
            if str2double(position) > 6 || str2double(position) < 1 
                fprintf(position)
                error("Position must be between 1  and 6")
            end
            writeline(obj.serial,"pos="+position)
            readString = readline(obj.serial);
            obj.position = str2double(position);

        end
        function checkPosition(obj)
            writeline(obj.serial,"pos?");
            readString = readline(obj.serial);
            readString = readline(obj.serial);
            fprintf("Position: %s\n", readString)
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
            obj.serial = serialport(obj.port,obj.baud);
        
            % carriage return terminator
            configureTerminator(obj.serial,"CR");
            
            write(obj.serial,13,'char');
            readString = readline(obj.serial);
            readString = readline(obj.serial);
            % print to console the received response
            %fprintf(readString);
            stringCheck = strfind(readString, 'Command error CMD_NOT_DEFINED');
            if stringCheck > 0
                fprintf("\r\nFilter wheel now ready to receive commands\r\n");
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