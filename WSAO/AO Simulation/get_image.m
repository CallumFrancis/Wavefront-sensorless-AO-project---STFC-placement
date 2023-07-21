% New and improved centre() to average multiple pictures

function [farfield,midpoint] = get_image(cam,n_images,varargin)
for i = 1:n_images
    img{i} = im2double(getsnapshot(cam)); % difficutlt to preallocate img size as depends on camera
end
farfield = sum(cat(3,img{:}),3) / n_images;
if nargin == 3 % if centroid has been specified already
    c = varargin{1};
else
    %farfield(farfield < 0.03) = 0;
    labeledImage = logical(true(size(farfield)));
    max_of_farfield = farfield .* (farfield == max(farfield,[],'all'));
    props = regionprops(labeledImage, max_of_farfield, 'Centroid', 'WeightedCentroid');
    c = floor(props.WeightedCentroid);
    if any([c(1) < 149,c(1) > 1786,c(2) < 149,c(2) > 1166],'all')
            error('Camera needs centering');
    end

end
midpoint = c;
farfield = farfield(c(2) - 149:c(2) + 150, c(1) - 149:c(1) + 150); % cut out a square
farfield = medfilt2(farfield,[3 3]);
