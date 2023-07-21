%%  Gerchberg-Saxton error-reduction algorithm
% phase_retrieval % simulation version
beam_diameter  = 200;  % Resolution of all surfaces
orders      = 7;   % Aberration orders
iterations  = 200;
error       = nan(iterations+1,1);
wavelength  = 636e-9;
wyant       = 0;


addpath('WSAO');
addpath(fullfile('WSAO','Utilities'));
addpath(fullfile('WSAO','AO Simulation'));

%% Generate Polynomials
[r,theta] = generate_grid(beam_diameter,"polar");
pupil = ( r <= 1 );
r = r(pupil);
theta = theta(pupil);
[N,M] = generate_orders(2,9);
Z = myzernike(N,M,r,theta); % Zernike Library
if wyant
    for i = 1:33 % should be enough for all polys
        wyant(i) = floor((1 + (N(i) + abs(M(i)))/2)^2 - 2*abs(M(i)) + (1 - sign(M(i)))/2) - 1;
    end
    Z = Z(:,wyant);
    
end
%% Generate coeffcients
% if nargin == 2
%     coeffs_real = varargin{1};
%     coeffs_guess = varargin{2};
% else
    
    coeffs_real = generate_coeffs(orders)/1;
    coeffs_guess = generate_coeffs(orders)/1.4;
    error(1) = mean((coeffs_guess - coeffs_real).^2);
    
% end
num_polynomials = min(size(Z,2),size(coeffs_real,1));
Z = Z(:,1:num_polynomials); % so that Z and coeffs are the same size
coeffs_real = coeffs_real(1:num_polynomials);
coeffs_guess = coeffs_guess(1:num_polynomials);

%% Create Farfield sim object
initFF = FarField;
%initFF.beam_diameter = beam_diameter;
guessFF = FarField;
%guessFF.beam_diameter = beam_diameter;
%FF.settings(1,1,0.07,0.07);

%% Create wavefronts from coefficients
initwf = nan(beam_diameter,beam_diameter);
initwf(pupil) = Z * coeffs_real * initFF.radian_inator;
guesswf = nan(beam_diameter,beam_diameter);
guesswf(pupil) = Z * coeffs_guess * guessFF.radian_inator;

%% Create pupil functions
init_pupil_func = pupil .* exp(1i * initwf);
guess_pupil_func = nan(beam_diameter,beam_diameter,iterations);
guess_pupil_func(:,:,1) = pupil .* exp(1i * guesswf);

%% Create initial farfield
initff = initFF.generate_farfield(init_pupil_func);
%initff = im2double(ff_resized);

%% Create the figure
f = figure();
f.Position(3:4) = [800 1000];
pause(20)
tiledlayout(4,2,'TileSpacing','compact')
nexttile(1,[1 1])
surf(initwf),colorbar, view(0,90)
shading interp
title('Initial wavefront')

nexttile(2,[1 1])
imagesc(initff), colorbar
title('real farfield')

nexttile(3,[1 1])
surf(guesswf),colorbar, view(0,90)
shading interp
title('1st guess wavefront')

guessff = guessFF.generate_farfield(guess_pupil_func(:,:,1));

nexttile(4,[1 1])
imagesc(guessff), colorbar
title('1st guess farfield')
drawnow
%% Looping section

for k = 1:iterations
    %pupil = gpuArray(pupil); % Optional gpu acceleration

    guessff = guessFF.generate_farfield(guess_pupil_func(:,:,k)); % calculate current farfield
    nexttile(5,[1 1])
    imagesc(guessff), colorbar % show current guess wavefront
    title('Current guess farfield')
    text(10,25,'Iteration: ' + string(k),'Color','white');

    guessFF.complex = guessFF.complex ./ guessff .* initff; % change modulus of fourier transform
    nexttile(6,[1 1])
    imagesc(abs(guessFF.complex)), colorbar
    title('Replace modulus')
    drawnow        
    
    guess_pupil_func(:,:,k+1) = guessFF.inverse(guessFF.complex); % inverse fourier transform
    guess_pupil_func(:,:,k+1) = guess_pupil_func(:,:,k+1) ./ abs(guess_pupil_func(:,:,k+1)) .* abs(init_pupil_func); % change modulus of wavefront
end


guesswf = my_2D_unwrap(angle(guess_pupil_func(:,:,iterations)));
guesswf(isnan(guesswf)) = 0;
guesswf(guesswf.*pupil == 0) = nan;
nexttile(7,[1 1])
surf(guesswf),colorbar, view(0,90)
shading interp
title('Final guess wavefront')


approximation = nan(size(initwf));
coefficients = (Z' * Z)^(-1) * Z' * guesswf(pupil) / guessFF.radian_inator;
error(k+1) = mean(coefficients - coeffs_real).^2;
approximation(pupil) = Z * coefficients * guessFF.radian_inator;
nexttile(8,[1 1])
surf(approximation),colorbar, view(0,90)
shading interp
title('Zernike approximation to wavefront')



% min_error_idx = find(error == min(error,[],'all'));
% answer = questdlg('Min coefficient error found = ' + string(error(min_error_idx)), ...
%     'Phase retrieval complete','Run again from best guess', 'Run again with random guess',...
%     'Stop and keep best guess', 'none');
% switch answer
%     case 'Run again from best guess'
%         phase_retrieval(coeffs_real,coeffs(:,:,min_error_idx));
%     case 'Run again with random guess'
%         coeffs_guess = generate_coeffs(orders);
%         phase_retrieval(coeffs_real,coeffs_guess);
%     case 'Stop and keep best guess'
% end








 
