classdef mirror_model < handle
    properties
        shape               % shape of mirror as resol x resol matrix
        channels            % number of channels
        voltages            % voltages vector
        influences          % influence of every actuator
        beam_resolution          % width and height of every surface of beam
        mirror_resolution   % width and height of mirror
        overhang            % how much bigger mirror_resolution is than beam_resolution on each side
        spread              % how much the influence curve spreads
        volt_const = 0.00012 %* 9.8792  % default value
        custom_mirror
        BIGS
        xderivation
        yderivation
        movements = 0
        scale = 1.5         % scale of mirror size compared to beam size
        cutout
    end
    methods
        function obj = mirror_model(varargin)
            if nargin == 1
                obj.custom_mirror = true;
                obj.influences = varargin{1};
                obj.channels = size(obj.influences,3);
                obj.mirror_resolution = size(obj.influences,1);
                obj.beam_resolution = obj.mirror_resolution / obj.scale;
                obj.spread = 'Invalid';
                obj.overhang = (obj.mirror_resolution - obj.beam_resolution) / 2; % as beam is centred in middle of mirror
                return
            end
            
            if nargin == 3
                chan = varargin{1};
                resol = varargin{2};
                spread = varargin{3};
                % Checking inputs
                if sqrt(chan) ~= round(sqrt(chan))
                    error("Number of actuators must be the square of a natural number")
                elseif spread <= 0 || resol <= 0
                    error("Invalid resolution or spread value. Must be positive")
                end
                obj.channels = chan;
                obj.beam_resolution = resol;
                obj.spread = spread;
                obj.mirror_resolution = obj.beam_resolution * obj.scale;
                obj.overhang = (obj.mirror_resolution - obj.beam_resolution) / 2; % as beam is centred in middle of mirror
                generate_influences(obj);
            else
                error("Not enough input arguments")
            end
            obj.cutout = ones(obj.mirror_resolution);
        end
        
        function set_mirror_cutout(obj,shape)
            switch  shape
                case 'O'
                    X = linspace(-1,1,obj.mirror_resolution);
                    [x,y] = meshgrid(X);
                    [~,r] = cart2pol(x,y);
                    obj.cutout = (r <= 1);
                    obj.cutout = double(obj.cutout);
                    obj.cutout(obj.cutout == 0) = nan;
                case '[]'
                    obj.cutout = ones(obj.mirror_resolution);
            end
        end

        function generate_influences(obj)
            % Default square mirror
            % Actuator placement is NxN grid such that NxN = # acts
            N = sqrt(obj.channels);
            % Create N equally spaced points in region [-1,1]
            act_positions = linspace(-1,1,N);
            % Create a meshgrid if 'resol' number of points in region [-1,1]
            [X, Y] = meshgrid(linspace(-1,1,obj.beam_resolution*obj.scale));
            obj.influences = nan(obj.mirror_resolution,obj.mirror_resolution,obj.channels);
%             obj.xderivation = nan(obj.beam_resolution,obj.beam_resolution,obj.channels);
%             obj.yderivation = nan(obj.beam_resolution,obj.beam_resolution,obj.channels);
%             S = zeros(N,N);
            k = 1;
           % int_handle = @(i,j) obj.integral_function(i,j,1,obj.spread,obj.resolution);
            for i_pos = act_positions
                for j_pos = act_positions
                    % Creating gaussian curve at (i_pos,j_pos)
                    obj.influences(:,:,k) = obj.gaussian(X,Y,i_pos,j_pos,1,obj.spread);
                   % S(i_pos,j_pos) = integral2(int_handle(i_pos,j_pos),-1,1,-1,1);
          
                    k = k + 1;

                end
            end

%             obj.BIGS = S;
        end

        function set_channels(obj,volts)
            % Sets channels to give voltages
            if isscalar(volts)
                % For ease of use, single value means all channels
                volts = ones(obj.channels,1)*volts;
            elseif isvector(volts)
                % if vector is row, transpose to column. Needed for permute
                % later on
                if isrow(volts)
                    volts = volts';
                end
            else
                error('Argument must be a vector')
            end
            % Transforming vec from 'channels'x1 to 1x1x'channels'. Shape =
            % linear combination of all influences*volt then scaled by 
            % Vconst. Influences are of size 'resol'x'resol'x'channels'
            volts = permute(volts,[3,2,1]);
            obj.movements = obj.movements + 1;
            obj.shape = obj.volt_const*sum(volts.*obj.influences,3) .* obj.cutout;
            obj.voltages = permute(volts,[3,2,1]);
        end
    end
    methods (Static)
        function z = gaussian(x,y,i,j,a,c)
            
            % Used to generate the default influences
            z = a * exp((-(x-i).^2-(y-j).^2)/c);
        end
%         function xd = xderiv(x,y,i,j,a,c)
%             xd =  (a/c) * -exp((- (x - i).^2 - (y - j).^2)/c).*(2.*x - 2*i);
%         end
%         function yd = yderiv(x,y,i,j,a,c)
%             yd = (a/c) * -exp((- (x - i).^2 - (y - j).^2)/c).*(2.*y - 2*j);
%         end
  %          [x, y] = meshgrid(linspace(-1,1,resolution));
   %         integral = (a/c) * -exp((- (x - i).^2 - (y - i).^2)/c).*(2.*x - 2*i) * ... 
    %            (a/c) * -exp((- (x - j).^2 - (y - j).^2)/c).*(2.*y - 2*j) + ...
     %           (a/c) * -exp((- (x - j).^2 - (y - j).^2)/c).*(2.*x - 2*j) * ...
      %          (a/c) * -exp((- (x - i).^2 - (y - i).^2)/c).*(2.*y - 2*i);
       % end
    end
end