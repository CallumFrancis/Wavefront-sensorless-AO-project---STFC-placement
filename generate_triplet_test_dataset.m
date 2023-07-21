function generate_triplet_test_dataset(dataset_size,resolution,orders)
    % Initialise workers (threads)
    poolobj = gcp;
    % Attach required files to workers
    addAttachedFiles(poolobj,{'myzernike.m','FarField.m','Utilities'})
    % Get number of workers
    workers = poolobj.NumWorkers;
    
    % How many files each worker generates (floored)
    files_per_worker = floor(dataset_size/workers);
    mkdir('Recognition_Dataset_nonroot')
    mkdir(fullfile('Recognition_Dataset_nonroot','Test'))
    mkdir(fullfile('Recognition_Dataset_nonroot','Test','Labels'))
    mkdir(fullfile('Recognition_Dataset_nonroot','Test','Image_A'))
    mkdir(fullfile('Recognition_Dataset_nonroot','Test','Image_P'))
    mkdir(fullfile('Recognition_Dataset_nonroot','Test','Image_N'))
    
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
            coefficients_A = generate_coeffs(orders);
            coefficients_N = generate_coeffs(orders);
            
            num_polynomials = min(size(Z,2),size(coefficients_A,1));
            Z = Z(:,1:num_polynomials); % so that Z and coeffs are the same size
            coefficients_A = coefficients_A(1:num_polynomials);
            coefficients_N = coefficients_N(1:num_polynomials);
            if ~iscolumn(coefficients_A)
                coefficients_A = coefficients_A';
            end
            if ~iscolumn(coefficients_N)
                coefficients_N = coefficients_N';
            end
            
            small_change = (rand(size(coefficients_A)) - 0.5)/40 % small change to positive image coefficients
            coefficients_P = coefficients_A + small_change; % rest of image augmentation done in python
            
            wavefront_A = nan(resolution,resolution);
            wavefront_N = wavefront_A, wavefront_P = wavefront_N;
            
            wavefront_A(pupil) = Z * coefficients_A * FF.radian_inator;
            wavefront_P(pupil) = Z * coefficients_P * FF.radian_inator;
            wavefront_N(pupil) = Z * coefficients_N * FF.radian_inator;
            
            pupil_func_A = pupil .* exp(1i * wavefront_A);
            pupil_func_P = pupil .* exp(1i * wavefront_P);
            pupil_func_N = pupil .* exp(1i * wavefront_N);
            
            farfield_A = FF.generate_farfield(pupil_func_A);
            farfield_P = FF.generate_farfield(pupil_func_P);
            farfield_N = FF.generate_farfield(pupil_func_N);
            
            farfield_A = farfield_A / max(farfield_A,[],'all');
            farfield_P = farfield_P / max(farfield_P,[],'all');
            farfield_N = farfield_N / max(farfield_N,[],'all');
                
            
            fname = sprintf('Image_A_%i.png',i);
            fdir = fullfile('Recognition_Dataset_nonroot','Test','Image_A',fname);
            imwrite(farfield_A,fdir);
            
            fname = sprintf('Image_P_%i.png',i);
            fdir = fullfile('Recognition_Dataset_nonroot','Test','Image_P',fname);
            imwrite(farfield_P,fdir);
            
            fname = sprintf('Image_N_%i.png',i);
            fdir = fullfile('Recognition_Dataset_nonroot','Test','Image_N',fname);
            imwrite(farfield_N,fdir);
            
%             fname = sprintf('Label_%i.csv',i);
%             fdir = fullfile('Recognition_Dataset','Test','Labels',fname);
%             writematrix(label,fdir);
        end
    end
end

            
         