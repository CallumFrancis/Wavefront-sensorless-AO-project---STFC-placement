classdef Manual_control < handle % manual control derived from thesis by Stanislav K Vassilev
    properties
        FIGURE
        running
        mirror
        V               % voltages
        chanslider
        voltslider
    end
    methods
        function self = Manual_control(varargin)
            self.mirror = mirror("COM4",115200);
            
            self.V = zeros(1:length(self.mirror.channels));
            disp(self.V)
            self.FIGURE = figure('Toolbar','none','Menubar', 'none','NumberTitle','Off','Name','Manual Mirror Control');
            % Channel slider and label
            self.chanslider = uicontrol('Style','slider','Value',1,...
                'Max',64,'Min',1,'SliderStep',[0.0158730158,0.1],...
                'Position',[320 350 200 20]);
  
            uicontrol('Style','text','Position',[320 372 200 16],...
                'String','Channel Number (1-64) Value:');
            % Voltage slider and label
            self.voltslider = uicontrol('Style','slider','Value',0,...
                'Max',64,'Min',-64,'SliderStep',[0.0078125,0.1],...
                'Position',[320 300 200 20]);
            uicontrol('Style','text','Position',[320 322 200 16],...
                'String','Voltage at Channel (-64V-+64V) Value:');
            
            self.main_loop();
        end
        function main_loop(self)
            self.running = true;
            for i =1:3
                chan = get(self.chanslider,'Value');
                chan = round(chan);
                self.V(chan) = get(self.voltslider,'Value')
                
                self.mirror.setChannels(self.V)
                self.running = false;
            end
        end
    end
end