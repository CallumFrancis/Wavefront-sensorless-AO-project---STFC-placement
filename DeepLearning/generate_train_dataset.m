function generate_train_dataset(dataset_size,resolution,orders)
    % Generates dataset of farfields vs zernike
    % Requires parallel computing toolbox mirror_model.m, FarField.m and crop_matrix.m
        
    

    % Initialise workers
    
    % Initialise workers (threads)
    poolobj = gcp;
    % Attach required files to workers
    addAttachedFiles(poolobj,{'myzernike.m','FarField.m','Utilities'})
    % Get number of workers
    workers = poolobj.NumWorkers;
    
    % How many files each worker generates (floored)
    files_per_worker = floor(dataset_size/workers);
    
    
    if files_per_worker ~= dataset_size/workers
        line1 = sprintf("You have %i workers available", workers);
%         line2 = sprintf("Make sure your dataset size evenly divides with the number of workers");
%         line3 = sprintf("or some images may be skipped due to index rounding");
%         line4 = sprintf("Do you wish  to continue ?");
        line2 = "Make sure your dataset size evenly divides with the number of workers or some images may be skipped due to index rounding.";
        line3 = "Do you wish  to continue?";
        answer = questdlg([line1,line2,line3],'Yes');

        if ~strcmp(answer,'Yes')
            error('Did not generate dataset');
        end
    end
    
    tic
    
    % Create Dataset directory
    mkdir('Dataset')
    mkdir(fullfile('Dataset','Train'))
    mkdir(fullfile('Dataset','Train','Images'))
    mkdir(fullfile('Dataset','Train','Labels'))
    
    
    % Begin parallel process
    parfor worker = 1:workers
        [r,theta] = generate_grid(resolution,"polar");

        pupil = ( r <= 1 );
        r = r(pupil);
        theta = theta(pupil);
        
        [N,M] = generate_orders(2,9); %ignore first 3 orders
        
        Z = myzernike(N,M,r,theta); % Zernike Library

        FF = FarField;  % Farfield simulation
        %FF.settings(4,0.2,0.1,0.1); % Farfield settings (phase_gain,apert_size,noise1,noise2)
        
        % Starting and ending point for each worker
        start_idx = worker * files_per_worker - files_per_worker + 1;
        final_idx = start_idx + files_per_worker - 1;
        
        % Begin generating images
        for i = start_idx:final_idx
            
            coeffs = generate_coeffs(orders)
            num_polynomials = min(size(Z,2),size(coeffs,1));
            Z = Z(:,1:num_polynomials); % so that Z and coeffs are the same size
            coeffs = coeffs(1:num_polynomials);
            if ~iscolumn(coeffs)
                coeffs = coeffs';
            end
            wf = nan(resolution,resolution);
            wf(pupil) = Z * coeffs * FF.radian_inator;	% Calculate wavefront (& crop 10 pixels each side - not entirely sure why probably just remove useless space)
            wf_pupil_func = pupil .* exp(1i * wf);
            ff = FF.generate_farfield(wf_pupil_func)               % Generate resulting farfield (intensity surface, wavefront/phase surface)
            %ff(ff>15) = 15;
            %ff = ff .* r;
            %ff = log(abs(ff));%this line is new
            ff = ff/max(ff,[],'all');
            %ff(ff < 0.22) = ff(ff < 0.22) * 2;
            %ff = ff.^(1/2);
            ff = uint8(mat2gray(ff)*255);                   % Convert to 8bit greyscale (normalised)
            
            wf(isnan(wf)) = 0;
           
            fname = sprintf('coeffs_%i.csv',i);             % Name of coeffs file, "coeffs_index.csv"
            fdir = fullfile('Dataset','Train','Labels',fname);   % Full path to save it to ".\Dataset\Responses\coeffs_index.csv".
            writematrix(coeffs(1:12),fdir);                       % Write file
            
            fname = sprintf("farfield_%i.png",i);               % Name of farfield image, "farfield_idex.png"
            fdir = fullfile('Dataset','Train','Images',fname);    % Full path to save it to ".\Dataset\Observations\farfield_idex.png".
            imwrite(ff,fdir);                                   % Write file
        end
    end
    end_time = toc;
    fprintf("Training set generation duration: %.2f sec\n",end_time);
end