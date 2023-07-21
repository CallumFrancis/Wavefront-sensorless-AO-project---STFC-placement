classdef FarField < handle
    properties
        image
        wavefront
        near_field
        ideal_farfield
        radian_inator    = 1e-6 * 2 * pi/(636*10^-9);
        aperture_size = 0.2   % final size = initial size / aperture_size
        noise_dev     = 0.05  % Range of noise as % of max value
        noise_mean    = 0.05  % Background value as % of max value
        complex
    end
    methods
        function varargout = generate_farfield(obj,pupil_func)
            pupil_func(isnan(pupil_func)) = 0;
            rows = size(pupil_func,1);
            cols  = size(pupil_func,2);
         
            
            % Calculating padding amount from apert_size and then padding
            sz2 = [rows,cols] / obj.aperture_size;
            padwidth = floor(sz2-[rows,cols])/2;
            padded_pupil_func = padarray(pupil_func,padwidth,0,'both');
           
            %pupil = gpuArray(pupil); % Optional gpu acceleration
            
            obj.image = fftshift(fft2(padded_pupil_func));%,sz2(1),sz2(2)));
            % find centroid
            labeledImage = logical(true(size(obj.image)));
            max_of_farfield = obj.image .* (obj.image == max(obj.image,[],'all'));
            props = regionprops(labeledImage, max_of_farfield, 'Centroid', 'WeightedCentroid');
            c = props.WeightedCentroid; 
            c = sqrt(c .* conj(c)); % some of them were coming out as complex
            c = floor(c); % need to be integers
            obj.image = obj.image(c(2)-99:c(2)+100,c(1)-99:c(1)+100);
            obj.complex = obj.image;
            obj.image = obj.image.*conj(obj.image);
            % Cropping to remove extra space created by padding

            
            % Adding gaussian noise to image, simulating a real camera
            deviation = obj.noise_dev*max(obj.image,[],'all')/40;
            mean = obj.noise_mean*max(obj.image,[],'all');
            obj.image = obj.image + deviation*randn(rows,cols) + mean;
            
            %obj.image = gather(obj.image); % gather array from gpu (only when using gpuArray())
          
            
            if nargout == 1
                varargout{1} = obj.image;
            end
        end
        function wavefront = inverse(obj,farfield) % farfield should be complex
            rows = size(farfield,1);
            cols  = size(farfield,2);
            
            
            % Calculating padding amount from apert_size and then padding
            sz2 = [rows,cols] / obj.aperture_size;
            padwidth = floor(sz2-[rows,cols])/2;
            padded_ff = padarray(farfield,padwidth,0,'both');
            wavefront = ifft2(ifftshift(padded_ff));
            wavefront = wavefront(padwidth(1)+1:end-padwidth(1),... % wavefront will also be complex
                padwidth(2)+1:end-padwidth(2));         
        end
        function settings(obj,varargin)
            % Set simmulation settings, eg. obj.settings(0.1,[],0.2,0.3).
            % Index is as follows. 1.phase_gain, 2.aperture_size,
            % 3.noise_dev, 4.noise_mean. Empty array means no change.
            
            % Read object properties
            prop_array = [
                obj.radian_inator;
                obj.aperture_size;
                obj.noise_dev;
                obj.noise_mean
                ];
            % Check for non-empty elements. Non-empty: idx = 1. Else 0
            idx = ~cellfun(@isempty,varargin);
            for i = 1:nargin-1
                % If not empty, overwrite
                if idx(i)
                    prop_array(i) = varargin{i};
                end
            end
            % Change properties
            obj.radian_inator   = prop_array(1);
            obj.aperture_size   = prop_array(2);
            obj.noise_dev       = prop_array(3);
            obj.noise_mean      = prop_array(4);
        end
    end
end


