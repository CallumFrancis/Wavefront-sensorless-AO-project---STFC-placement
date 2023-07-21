function [maxI,norm_I] = strehl_ratio(image)
  %  assert(size(image,1) == size(image,2),'Image needs to be square')
%     [r,~] = generate_grid(size(image,1),"polar");
%     r(:,1:floor(size(r,1)/2)) = -r(:,1:floor(size(r,1)/2));
%     I = zeros(size(unique(r)));
%     j=1;
%     for i = unique(r)'
%         [~,~,v] = find(image .* (r==i));
%         I(j) = mean(v,"all");
%         j=j+1;
%     end
    %I(isnan(I)) = 0;
   % image(image < 0.004) = 0;
    image(isnan(image)) = 0;
    integral = sum(image(:));
    norm_I = image/integral;
    maxI = max(norm_I,[],"all");
end
