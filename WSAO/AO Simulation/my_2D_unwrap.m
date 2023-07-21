
function unwrapped_wavefront = my_2D_unwrap(wavefront)

% wavefront(isnan(wavefront)) = 17*pi;
% wavefront = padarray(wavefront,[1 1],17*pi,"both");
% figure
% surf(wavefront),shading interp
% unwrapped_wavefront = unwrap(wavefront,[],1);
% 
% 
%wavefront = image1_wrapped;
sf=1;
wavefront = wavefront *sf;

mid_row = floor(size(wavefront,1)/2); % find middle of the wavefront matrix
%mid_row = mid_row(1);

% Unwrap the middle row
wavefront(mid_row,:) = unwrap(wavefront(mid_row,:),[],2);

% Split wavefront into 2 'halves' both containing the middle row
upper_half = wavefront(1:mid_row,:);
lower_half = wavefront(mid_row:end,:);

% Invert top half so unwrap starts from middle row
upper_half = flipud(upper_half);

% Unwrap along columns
unwrapped_upper = unwrap(upper_half,[],1);
unwrapped_lower = unwrap(lower_half,[],1);

% Reflip top
unwrapped_upper = flipud(unwrapped_upper);

% Combine top and bottom
unwrapped_wavefront = [unwrapped_upper; unwrapped_lower(2:end,:)];



