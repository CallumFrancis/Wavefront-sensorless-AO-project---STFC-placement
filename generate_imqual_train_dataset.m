function generate_imqual_train_dataset(dataset_size,resolution,orders)
    % Initialise workers (threads)
    poolobj = gcp;
    % Attach required files to workers
    addAttachedFiles(poolobj,{'myzernike.m','FarField.m','Utilities'})
    % Get number of workers
    workers = poolobj.NumWorkers;
    
    % How many files each worker generates (floored)
    files_per_worker = floor(dataset_size/workers);
    mkdir('ImQual_Dataset_nonroot2')
    mkdir(fullfile('ImQual_Dataset_nonroot','Train'))
    mkdir(fullfile('ImQual_Dataset_nonroot','Train','Labels'))
    mkdir(fullfile('ImQual_Dataset_nonroot','Train','Images'))
    
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
            coefficients = generate_coeffs(orders);
            
            num_polynomials = min(size(Z,2),size(coefficients,1));
            Z = Z(:,1:num_polynomials); % so that Z and coeffs are the same size
            coefficients = coefficients(1:num_polynomials);
            if ~iscolumn(coefficients)
                coefficients = coefficients';
            end

            wavefront = nan(resolution,resolution);
            
            wavefront(pupil) = Z * coefficients * FF.radian_inator;
            
            pupil_func = pupil .* exp(1i * wavefront);
            
            farfield = FF.generate_farfield(pupil_func);        
            farfield = farfield / max(farfield,[],'all');
    
            fname = sprintf('Image_%i.png',i);
            fdir = fullfile('ImQual_Dataset_nonroot','Train','Images',fname);
            imwrite(farfield,fdir);
            
            fname = sprintf('Label_%i.csv',i);
            fdir = fullfile('ImQual_Dataset_nonroot','Train','Labels',fname);
            writematrix(coefficients,fdir);
        end
    end
end
