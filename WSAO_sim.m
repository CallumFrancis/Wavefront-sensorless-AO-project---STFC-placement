



iterations  = 3;   % Optimisation Iterations
wyant       = false;
resolution  = 200;
props.image_resolution = resolution; % having parameters in one struct can make things easier
props.orders      = 7;   % Aberration orders
props.channels    = 64;   % Number of mirror channels
props.using_zernike_polys = 0;



%rng_seed = 1122;
%rng(rng_seed)

currentfolder = pwd;
addpath('WSAO');
addpath(fullfile('WSAO','AO Simulation'));
addpath(fullfile('WSAO','Optimisation Algorithms'));
addpath(fullfile('WSAO','Utilities'));
addpath(fullfile('WSAO','AO Simulation','Mirror presets'));
d = dir(fullfile(pwd,'WSAO','AO Simulation','Mirror presets','*.mat'));

%% ask which mirror should be used
answer = listdlg('PromptString',{'Select a mirror:'}, ...
    'SelectionMode','single','ListString',{'Default' d.name});

% Create mirror object
if answer == 1
    props.mirror_sim = mirror_model(props.channels,props.image_resolution,0.09);
    %mirror_sim.volt_const = 0.6;
    props.mirror_sim.set_channels(0);
    fprintf("Default square mirror selected\n")
else
    load(d(answer-1).name,'influences');
    quest_iscircular = strcmp(questdlg('Is this mirror circular?'),'Yes');
    props.mirror_sim = mirror_model(influences);
    if quest_iscircular
        props.mirror_sim.set_mirror_cutout('O');
    end
    fprintf("%s mirror selected\n",d(answer-1).name); 
end

if props.mirror_sim.custom_mirror == true
   props.channels = props.mirror_sim.channels;
   props.image_resolution = props.mirror_sim.beam_resolution;
end

%% Generate Polynomials
[r,theta] = generate_grid(resolution,"polar");
pupil = ( r <= 1 );
r = r(pupil);
theta = theta(pupil);
[N,M] = generate_orders(2,9);
Z = myzernike(N,M,r,theta); % Zernike Library
if wyant % if using wyant indexing
    wyant = [];
    for i = 1:33 % should be enough for all polys
        wyant(i) = floor((1 + (N(i) + abs(M(i)))/2)^2 - 2*abs(M(i)) + (1 - sign(M(i)))/2) - 1;
    end
    Z = Z(:,wyant);
end


%% Create Farfield sim object
FF = FarField;
%FF.settings(4,0.2,0.07,0.07);

% Generate initial wavefront & farfield
coeffs = generate_coeffs(7);
%coeffs = good_coeffs;
initwf = nan(resolution,resolution);
num_polynomials = min(size(Z,2),size(coeffs,1));
Z = Z(:,1:num_polynomials); % so that Z and coeffs are the same size
coeffs = coeffs(1:num_polynomials);
if ~iscolumn(coeffs)
    coeffs = coeffs';
end

initwf(pupil) = Z * coeffs * FF.radian_inator;
init_pupil_func = pupil .* exp(1i * initwf);
initff = FF.generate_farfield(init_pupil_func);
initff = initff / max(initff,[],'all');

plot_handle = @(plot,type) plotter(plot,type,resolution);

%  initff(initff > 3) = 3;
%  initff = initff / max(initff,[],'all');

%% Create Figure

% fig2 = figure(1); % create table to keep track of voltages
% var = {'Voltages'};
% uit = uitable(fig2,'Data',[mirror_sim.voltages solver.grad solver.position],'ColumnName',{'Voltages','Gradient','Position'},'units','normalized','Position',[0 0 1 1]);

fig = figure(2);
axis tight manual
%fig.Position = [35 468 706 871];
tiledlayout(3,2,'TileSpacing','compact') % create figure with 3x2 layout for all plots

nexttile(1,[1 1])
plot_handle(initwf,'wf')
title("Input wavefront")

nexttile(2,[1,1])
plot_handle(initff,'ff')
title("Initial farfield")
% Prealocating cost and evaluation arrays
cost = nan(iterations+1,1);
flatness_cost = cost;
rmse_cost = cost;
maxI_cost = cost;
cost_inbucket = cost;
movements = cost;

%% 
if props.using_zernike_polys % if using zernike shapes as optimised parameters
    props.parameters = 12; % number of polynomials to use
    props.coeff_conversion = FF.radian_inator/4;
    [props.r,props.theta] = generate_grid(props.mirror_sim.mirror_resolution,"polar"); % need new zernike matrix as mirror may be bigger than wavefront
    props.pupil = (props.r <=1);
    props.r = props.r(props.pupil);
    props.theta = props.theta(props.pupil);
    props.Z = myzernike(N,M,props.r,props.theta);
    props.Z = props.Z(:,1:props.parameters); % needed for coeffs2voltages function
    cutout = props.mirror_sim.cutout==1;
    cutout_repeat = repmat(cutout,1,1,props.mirror_sim.channels);
    all_useful_points = props.mirror_sim.influences(cutout_repeat);
    props.influence_matrix = reshape(all_useful_points,[],props.mirror_sim.channels); % create influence function required for conversions later
else
    props.parameters = props.channels;
end

%% Create solver object to solve objective function
fhandle = @(r) cost_function(r,initwf,props,FF,1,plot_handle);
% ask which optimiser used
% choose the algorithm from a list
d = dir(fullfile(pwd,'WSAO','Optimisation Algorithms','*.m'));

answer = listdlg('PromptString',{'Select an algorithm:'}, ...
    'SelectionMode','single','ListString',{d.name});
solver_name = d(answer).name;
algorithm = str2func(solver_name(1:length(solver_name)-2)); % to remove the .m at the end
disp(props.parameters)
props.solver = algorithm(props.parameters,fhandle); % Chose one from optimisation algorithms folder
fprintf("%s algorithm selected\n", d(answer).name);
%solver.settings(0.01,0.1,0.1,0);

cost(1) = fhandle(0);
% ,flatness_cost(1),rmse_cost(1),maxI_cost(1),cost_inbucket(1)] = fhandle(0);
movements(1) = 0;
all_pos = [];
tic



%% Closed Loop
for i = 1:iterations
    
    props.solver.step();
  
    % Get voltages and plot wavefront & farfield
    v = props.solver.position;
    if props.using_zernike_polys
        v = coeffs2voltages(v,props);
    else
        v = v*50000; % Solver coord space -> voltage space
    end
    props.mirror_sim.set_channels(v);
    all_pos = [all_pos props.solver.position];
    outwf = padarray(initwf,[props.mirror_sim.overhang props.mirror_sim.overhang],nan,'both') + (props.mirror_sim.shape);
    outwf = outwf(props.mirror_sim.overhang+1:end-props.mirror_sim.overhang,props.mirror_sim.overhang+1:end-props.mirror_sim.overhang);
    out_pupil_func = pupil .* exp(1i * outwf);
    outff = FF.generate_farfield(out_pupil_func);
%     uit.Data(:,1) = mirror_sim.voltages;
%     uit.Data(:,2) = solver.grad;
%     uit.Data(:,3) = solver.position;
    
    % Log current cost and number of evals
    cost(i+1) = props.solver.cost;
%     ,flatness_cost(i+1),rmse_cost(i+1),maxI_cost(i+1),cost_inbucket(i+1)] = fhandle(solver.position); % = solver.cost?
    movements(i+1) = props.mirror_sim.movements;

    %fig = figure(1)
    %subplot(3,2,5:6)
    nexttile(6,[1,1]);
    plot(0:length(cost)-1,cost);
    title("Performance");
    xlabel("Iterations");
    ylabel("Cost");

    % add this text bit but do it properly!!
    txt = sprintf("est. Duration: %.2f min",movements(i+1)*0.1/60);
    text(0.4,0.85,txt,'Units','normalized','FontSize',10)
    drawnow
end
toc

%% Cost function
function cost = cost_function(pos,wf,props,FF,option,plot_handle)
% Returns FF Quality metric from solver position
    if isscalar(pos)
        pos = ones(props.parameters,1)*pos;
    end
    if props.using_zernike_polys
        v = coeffs2voltages(pos,props);
    else
        v = pos*50000; % Solver coord space -> voltage space
    end
    props.mirror_sim.set_channels(v);
    outwf = padarray(wf,[props.mirror_sim.overhang props.mirror_sim.overhang],nan,'both');
    outwf = outwf + props.mirror_sim.shape;
    outwf = outwf(props.mirror_sim.overhang+1:end-props.mirror_sim.overhang,props.mirror_sim.overhang+1:end-props.mirror_sim.overhang);
    out_pupil_func = exp(1i * outwf);
    ff = FF.generate_farfield(out_pupil_func);
    %ff = medfilt2(ff,[3 3]); % Filter to reduce noise
    maxI = max(ff,[],'all');
    ff = ff/maxI;
    
    
    nexttile(3,[1,1])
    plot_handle(outwf,'wf');
    title("Current wavefront")
    
    nexttile(4,[1,1])
    plot_handle(ff,'ff');
    title("Current farfield")
   
    nexttile(5,[1,1]);
    plot_handle(props.mirror_sim.shape,'wf');

    title("Mirror shape")
    %xlabel(txt)
    drawnow
    
    switch option
        case 1
            outwf(isnan(outwf)) = 0;
            cost = sqrt(sum(outwf(:).^2)/numel(outwf(outwf~=0))); % For debuging. % this is gonna be wrong because 0s still counted as elements
        case 2
            z = outwf;
            % Move z-data to the average line.
            z=z-mean(z(:),'omitnan');
            % Sa - measure of average roughness
            Sa=mean(abs(z(:)),'omitnan');
            cost = Sa;
        case 3
            cost = sum(ff(:).^2)/(sum(ff(:))^2) * 200^2;
        case 4
            cost = sum(ff,'all');
        case 5
            cost = -maxI;
    end
    drawnow
end

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
    
    
    nexttile(3,[1,1])
    plotWF(outwf);
    xlim([0 resolution + mirror.overhang])
    ylim([0 resolution + mirror.overhang])
    title("Current wavefront")
    
    nexttile(4,[1,1])
    plotFF(ff,maxI);
    title("Current farfield")
   
    nexttile(5,[1,1]);
    plotWF(mirror.shape);
    xlim([0 resolution + mirror.overhang])
    ylim([0 resolution + mirror.overhang])
    title("Mirror shape")
    %xlabel(txt)
    drawnow
    
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


%% Plot functions
function plotter(plot,type,resolution)
   switch type
       case 'wf'
           surf(plot), shading interp, colormap turbo
           %xlim([0 resolution])
          % ylim([0 resolution])
           colorbar
       case 'ff'
           imagesc(plot)
         %  xlim([0 resolution])
          % ylim([0 resolution])
           colormap turbo
           colorbar
       otherwise
           fprintf("Incorrect type argument")
   end
end
