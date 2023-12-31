
%% Generate farfields & coefficients
orders = 7;
resolution = 200;
msg = 'Do you want to generate new data sets?';
dlgtitle = 'Generate datasets';
answer = questdlg(msg,dlgtitle,'Yes','No','No');
if strcmp(answer,'Yes')

        num_train_files = 36000; % Optionally should be a mutiple of pool workers
        num_valid_files =  1800; % Optionally should be a mutiple of pool workers

        generate_train_dataset(num_train_files,resolution,orders);
        generate_validation_dataset(num_valid_files,resolution,orders);
end

% Lightweight network for testing
layers = alexnet('Weights','None');
layers(1) = imageInputLayer([resolution,resolution,1],'Name','input');
layers(16) = maxPooling2dLayer([3 3],'Stride',[2,2],'Padding','same','Name','pool5');
layers(end-1) = regressionLayer('Name','output'); % regression layer added to end of CNN instead of classifier?
layers(end-2) = fullyConnectedLayer(1,'Name','fc8'); 
layers(end) = [];

layerGraph(layers)

%% Load to memory dialog
msg = 'Load to memory? (Speeds up training but will take a long time to load)';
dlgtitle = 'Load options';
answer = questdlg(msg,dlgtitle,'Yes','No','Yes');
switch answer
    case 'Yes'
        memload = true;
    otherwise
        memload = false;
end

%% Create datastore(s)
dsO = fileDatastore('.\Dataset\Observations','ReadFcn',@imread);
dsR = fileDatastore('.\Dataset\Responses','ReadFcn',@readmatrix);
trainDS = combine(dsO,dsR);
dsO = fileDatastore('.\Dataset\Observations\Validation','ReadFcn',@imread);
dsR = fileDatastore('.\Dataset\Responses\Validation','ReadFcn',@readmatrix);
validDS = combine(dsO,dsR);

%% Load, Train, Predict
if memload
    %% Load to RAM (optional)
    tic
    trainSet = readall(trainDS);
    validSet = readall(validDS);
    fprintf("Loaded in: %.1f min\n",toc/60);

    trainIms = permute(imcell2numeric(trainSet(:,1)),[1,2,4,3]);
    trainTar = permute(imcell2numeric(trainSet(:,2)),[3,1,2]);

    validIms = permute(imcell2numeric(validSet(:,1)),[1,2,4,3]);
    validTar = permute(imcell2numeric(validSet(:,2)),[3,1,2]);
end

if memload
       %% Train network (Loaded)
        options = trainingOptions('adam',...
            'plots','training-progress',...
            'MiniBatchSize',64,...
            'Shuffle','every-epoch',...
            'ValidationData',{validIms,validTar},...
            'ValidationPatience',inf,...
            'ValidationFrequency',40,... & validation done every n iterations
            'ExecutionEnvironment','gpu',...
            'MaxEpoch',20,...
            'InitialLearnRate',0.5e-6, ...
            'LearnRateSchedule','piecewise', ...
            'LearnRateDropFactor',0.95, ...
            'LearnRateDropPeriod',1);
            

        net = trainNetwork(trainIms,trainTar,layers,options);
else
    %% Train network (From disk)
    
    options = trainingOptions('adam',...
        'plots','training-progress',...
        'MiniBatchSize',64,...
        'Shuffle','never',...
        'ValidationData',validDS,...
        'ValidationPatience',inf,...
        'ValidationFrequency',10,...
        'ExecutionEnvironment','gpu',...
        'MaxEpoch',100,...
        'InitialLearnRate',0.8e-6, ...
        'LearnRateSchedule','piecewise', ...
        'LearnRateDropFactor',0.95, ...
        'LearnRateDropPeriod',1);

    net = trainNetwork(trainDS,layers,options);
end

if memload
    %% Prediction (Loaded)
    idx = round((size(validTar,1)-1) * rand + 1);
    preds = predict(net,validIms(:,:,1,idx));

    figure(1)
    plot(preds,'r');
    hold on
    plot(validTar(idx,:),'b');
    %plot(preds - validTar(idx,:),'k');
    hold off
    legend('Predicted','Actual')%,'Sum')
    title('Testing once')
else
    %% Prediction (From disk)
    dataset = read(validDS);

    validIms = permute(imcell2numeric(dataset(:,1)),[1,2,4,3]);
    validTar = permute(imcell2numeric(dataset(:,2)),[3,1,2]);

    preds = predict(net,validIms(:,:,1));

    figure(1)
    plot(preds,'r');
    hold on
    plot(validTar(1,:),'b');
    plot(preds - validTar(1,:),'k');
    hold off
    legend('Predicted','Actual','Sum')
    title('Testing once')
end
