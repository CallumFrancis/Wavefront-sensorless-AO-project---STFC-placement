%% moves all actuators between 25 and -25V to try and remove hysteresis
function reset_mirror(mirror,cam)
    positives = nan(300,300,10);
    negatives = nan(300,300,10);
    figure()
    tiledlayout(10,2,'TileSpacing','compact')
    for i = 1:10
        tic
        mirror.setChannels(25000);
        toc
      %  positives(:,:,i) = get_image(cam,3);
        nexttile(i*2-1,[1 1])
      %  imagesc(positives(:,:,i))
        mirror.setChannels(-25000);
     %   negatives(:,:,i) = get_image(cam,3);
        nexttile(i*2,[1 1])
    %    imagesc(negatives(:,:,i))
    end
    mirror.setChannels(0);
    mirror.setChannels(0);
    mirror.setChannels(0);
    mirror.setChannels(0);
end

