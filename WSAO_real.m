%% This is an old script - generally should use the app version

%% Delete existing objects
clear dmirror
clear fhandle
clear fig
clear solver
clear mirror
clear fw
%cam.ExposureTimeAbs =9988;

resolution  = 200;  % Resolution of all surfaces
orders      = 8;    % Aberration orders
channels    = 55;   % Number of mirror channels
iterations  = 5;   % Optimisation Iterations
n_images    = 1;    % Number of images farfield is averaged over
max_voltage = 50000; % (millivolts)
cost_case   = 4;

parameters = containers.Map(["channels","n_images","max_voltage","orders","resolution","cost_case"], ...
    [channels n_images max_voltage orders resolution cost_case]);


%rng_seed = 1122;
%rng(rng_seed)
%connect_camera;
addpath('WSAO')
addpath(fullfile('WSAO','AO Simulation'));
addpath(fullfile('WSAO','Optimisation Algorithms'));
addpath(fullfile('WSAO','Utilities'));

%% Connect to mirror
dmirror = mirror_real("COM4",115200);

%% Connect to filter wheel
fw = filter_wheel("COM5",115200);
fw.setPosition(1)
pause(1)

%% Create solver object to solve objective function
fhandle = @(r) cost_function(r,dmirror,cam,fw,parameters);
% choose the algorithm from a list
d = dir(fullfile(pwd,'WSAO','Optimisation Algorithms','*.m'));

answer = listdlg('PromptString',{'Select an algorithm:'}, ...
    'SelectionMode','single','ListString',{d.name});
solver_name = d(answer).name;
algorithm = str2func(solver_name(1:length(solver_name)-2)); % to remover the .m at the end
solver = algorithm(channels,fhandle); % Chose one from optimisation algorithms folder ,initff(pupil),initwf,Z
fprintf("%s algorithm selected\n", d(answer).name);
%solver.settings(0.01,0.1,0.1,0);

fig = figure(1);
axis tight manual
%fig.Position = [35 468 706 871];
tiledlayout(2,2,'TileSpacing','compact')
initff = get_image(cam,n_images);

nexttile(1,[1,1])
plotFF(initff)
title(['Initial farfield, OD=' num2str(fw.slots(fw.position)) ', cost = ' num2str(solver.cost)])
% Prealocating cost array
cost = nan(iterations+1,1);
cost(1) = solver.cost;
pause(1)

allv = nan(55,iterations);

%% Closed Loop
tic
for i = 1:iterations
    %reset_mirror(dmirror)
    solver.step();
    % Get voltages and plot wavefront & farfield
    v = floor(solver.position * 50*1000);
    allv(:,i) = v;
    outff = get_image(cam,n_images);
    % Log current cost and number of evals
    cost(i+1) = solver.cost;
    nexttile(3,[1,1])
    plotFF(outff);
    title(['Previous iteration, OD=' num2str(fw.slots(fw.position))]);
    %subplot(3,2,5:6)

    nexttile(4,[1,1]);
    plot(0:length(cost)-1,cost);
    title("Performance");
    xlabel("Evaluations");
    ylabel("Cost");
    %text(0.6,0.85,txt,'Units','normalized','FontSize',14)
end
toc

%% Cost function
function cost = cost_function(pos,mirror,cam,fw,parameters)
% Returns FF Quality metric from solver position
    % Solver position will be between -1:1, driver box wants inputs in
    % millivolts 
    cost_case = parameters("cost_case");
    n_images = parameters("n_images");
    resolution = parameters("resolution");

    v = floor(pos*50*1000); % Solver coord space -> voltage space
    mirror.setChannels(v); 
    
    %pause(0.1)
   % [~,outff] = strehl_ratio(cam,fw);
    outff = get_image(cam,n_images);
    maxI = max(outff,[],'all');
    if maxI < 0.11
        fw.position = fw.position - 1;
        fw.setPosition(fw.position)
        pause(1);
        outff = get_image(cam,n_images);
        maxI = max(outff,[],'all');
    end
    while maxI == 1
        fw.position = fw.position + 1;
        fw.setPosition(fw.position)
        pause(1);
        outff = get_image(cam,n_images);
        pause(1)
        maxI = max(outff,[],'all');
    end
    switch cost_case
        case 1
            cost = -(maxI * 10^(fw.slots(fw.position)))/750;
        case 2
            cost = -maxI;
        case 3
            cost = sum(outff(:).^2)/(sum(outff(:))^2) * resolution^2;
        case 4
            cost = sum(outff,'all');          
    end
    outff = outff/maxI;
    nexttile(2,[1,1])
    plotFF(outff);
    title(['Current farfield, OD=' num2str(fw.slots(fw.position)) ', cost = ' num2str(cost)]);
    drawnow
end

%% Plot function
function plotFF(ff)
    if max(ff,[],'all') ~= 1
        ff = ff / max(ff,[],'all');
    end
% Plots farfield image
    imagesc(ff)
    colormap jet
    colorbar
end