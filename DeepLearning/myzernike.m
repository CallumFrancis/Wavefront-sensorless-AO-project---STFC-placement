
function Z = myzernike(n,m,r,theta)

    if any(r > 1)
        error('All r must be between 1 and 0')
    end
    Z = zeros(length(r),length(n));
    for i = 1:length(n)
        for s = 0:(n(i)-abs(m(i)))/2
            % calculate the radial part from summation
            Z(:,i) = Z(:,i) + (-1)^s * factorial(n(i)-s) ./ ...
                (factorial(s).* factorial((n(i)+m(i))/2 - s) .* ...
                factorial((n(i)-m(i))/2 - s)) .* r.^(n(i) - 2*s);
        end
        % multiply by angular part to find zernike function
        if m(i) < 0
            Z(:,i) = -Z(:,i) .* sin(theta * m(i));
        else
            Z(:,i) = Z(:,i) .* cos(theta * m(i));
        end
    end
end

