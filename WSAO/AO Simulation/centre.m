function [farfield,centroid] = centre(farfield,centroid)

if size(centroid) == [1 2] % if centroid has been specified already
    c = centroid;
else
    farfield(farfield < 0.03) = 0;
    labeledImage = logical(true(size(farfield)));
    props = regionprops(labeledImage, farfield, 'Centroid', 'WeightedCentroid');
    c = floor(props.WeightedCentroid);
    if any([c(1) < 101,c(1) > 1115,c(2) < 101,c > 1835],'all')
            error('Camera needs centering');
    end

end

farfield = farfield(c(2) - 99:c(2) + 100, c(1) - 99:c(1) + 100); % cut out a square
farfield = medfilt2(farfield,[3 3]);