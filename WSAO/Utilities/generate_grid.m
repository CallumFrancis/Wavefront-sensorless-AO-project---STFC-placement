%% Generates a square grid of size resolution in cartesian or polar coordinates

function [x,y] = generate_grid(resolution,system)
        X = linspace(-1,1,resolution);
        [x,y] = meshgrid(X);
        y = -y;
        if system == "polar"
            [theta,r] = cart2pol(x,y);
            x = r;
            y = theta;
        end
end