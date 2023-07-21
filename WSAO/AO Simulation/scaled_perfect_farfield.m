%% simulated perfect farfield, scaled down to be 200x200 image as would be returned by the camera
function ff = scaled_perfect_farfield(app)

image_resolution = app.image_resolution;

focus_radius = ((app.wavelength*app.focal_length)/(pi*app.beam_radius)) /(1 + ((app.wavelength*app.focal_length)/(pi*app.beam_radius^2))^2)^0.5;
%focus_radius = 4 * app.focal_length * app.wavelength / (pi * app.beam_radius * sqrt(2)); 
focus_radius_pixels = focus_radius / app.pixel_spacing;

[r,~] = generate_grid(image_resolution,"polar");
pupil = ( r <= 1 );



wf = nan(image_resolution,image_resolution);
wf(pupil) = 0;
pupil_func = pupil .* exp(1i * wf);

padwidth = 1500; % want to pad as much as possible for highest resolution
pupil_func(isnan(pupil_func)) = 0;
padded_pupil_func = padarray(pupil_func,[padwidth,padwidth],0,'both');
%pupil = gpuArray(pupil); % Optional gpu acceleration

ff = fftshift(fft2(padded_pupil_func));%,sz2(1),sz2(2)));

ff = ff.*conj(ff);

ff = ff / max(ff,[],'all');

focus_spot = (ff > (1/exp(2))).*ff;
focus_spot(~any(~(focus_spot==0), 2),:)=[];
focus_spot(:,~any(~(focus_spot==0), 1))=[];

pixels_diameter = size(focus_spot,1);
half_size = floor(pixels_diameter / (4*focus_radius_pixels/image_resolution));
centre = size(ff,1)/2;
ff = ff(centre-half_size:centre+half_size-1,centre-half_size:centre+half_size-1);
ff = imresize(ff,[image_resolution,image_resolution]);
ff = uint8(ff*255);
ff = im2double(ff);
%ff(ff < 0.004) = 0;
end


