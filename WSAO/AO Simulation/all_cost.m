function [cost,flatness_cost,rmse_cost,maxI_cost,cost_inbucket] = all_cost(pos,wf,mirror,FF)
 % Returns FF Quality metric from solver position
    v = pos*50; % Solver coord space -> voltage space
    mirror.set_channels(v);
    outwf = padarray(wf,[mirror.overhang mirror.overhang],nan,'both');
    outwf = outwf + mirror.shape;
    outwf = outwf(mirror.overhang+1:end-mirror.overhang,mirror.overhang+1:end-mirror.overhang);
    out_pupil_func = exp(1i * outwf);
    ff = FF.generate_farfield(out_pupil_func);
    %ff = medfilt2(ff,[3 3]); % Filter to reduce noise
    maxI = max(ff,[],'all');
    
    ff = ff/maxI;
    
    
    
    z = outwf;
    % Move z-data to the average line.
    z=z-mean(z(:),'omitnan');
    % Sa - measure of average roughness
    Sa=mean(abs(z(:)),'omitnan');
    flatness_cost = Sa;

    outwf(isnan(outwf)) = 0;
    rmse_cost = sqrt(sum(outwf(:).^2)/numel(outwf(outwf~=0)));

    maxI_cost = -maxI;
    
    cost_inbucket = sum(ff,'all');

    cost = sum(ff(:).^2)/(sum(ff(:))^2) * 200^2;
end