function [Acc, Beta] = svm_group_classify(X, Y, group, varargin)
% SVM_CLASSIFY()
%   Train a linear SVM to classify between 2+ classes in Y based on X.
%
% Usage:
%   > [Acc, Beta] = svm_group_classify(X, Y, group, ...);
%
% Parameters:
%   X   predictor matrix (n samples x p predictors)
%
%   Y   vector of target labels (one for each n sample)
%
%   group   vector of group labels for cross-validation 
%           ([] to use Y instead)
%
% Optional Parameters:
%   'npart'     number of folds for cross-validation (default: 5)
% 
%   'nruns"     number of times to repeate cross-validation (default: 1)
%
% Output:
%   Acc     cross-validated accuracy rate (averaged over nruns)
%
%   Beta    matrix of beta weights (p predictors x (k classes choose 2) )
%
% Author: Keith Yoder (keithyoder.com)
% University of Chicago, SCNL/CNS, 1/2018-1/2019

    %% Define defaults and parse input
    npart = 5;
    nruns = 1;
    if nargin > 2
        narg = 1;
        while narg <= length(varargin)
            if strcmpi(varargin{narg},'npart')
                narg = narg+1;
                npart = varargin{narg};
            elseif strcmpi(varargin{narg},'nruns')
                narg = narg+1;
                nruns = varargin{narg};
            else
                error(sprintf('Unrecognized keyword ''%s''\n',varargin{narg}));
            end
            narg = narg+1;
        end
    end
    
    
    if isempty(group)
        [Acc, Beta] = svm_classify(X, Y, 'npart', npart, 'nruns', nruns);
        return
    end
    
    
    if length(Y) ~= length(group)
        error('Y and group must have the same size.');
    end
    
    group_ids = unique(group);
    
    %% Create the SVM template
    % Linear SVM (for interpretable beta weights)
    % Standardize inputs
    T = templateSVM('Standardize', 1, 'KernelFunction', 'linear');
    
    %% Preallocate outputs
    Accs = zeros(nruns, 1);
    n_classes = numel(unique(Y));
    n_learners = nchoosek(n_classes,2);
    Betas = zeros(size(X,2), nruns, n_learners);
    
	%% Train and cross-validate the classifier(s)
    % For each "run" of the CV process, generate group-based CV partitions
    % Then train the linear SVM to distinguish between target labels
    % Store the fold-based accuracy rates and feature beta weights in
    % fold_acc and fold_beta, respectively, before averaging across folds
    % to store in Accs and Betas
    for run_id=1:nruns
        %% Generate the group-based CV partitions
        group_cv = cvpartition(numel(group_ids), 'KFold', npart);

        fold_accs = zeros(npart, 1);
        fold_betas = zeros(size(X,2), npart, n_learners);
        for part_id=1:npart
            %% Get the test/train indices and extract those data
            % extract indices of test subjects
            test_group = test(group_cv, part_id);
            % extract the test subject ids
            test_subs = group_ids(test_group);
                       
            % create an array of logical values
            %   1 = group at idx is a test subject
            %   0 = otherwise
            test_idx = zeros(length(group),1);
            for sub_id=1:numel(test_subs)
                test_idx(group == test_subs(sub_id)) = 1;
            end
            test_idx = logical(test_idx);
            train_idx = ~test_idx;
            
            X_train = X(train_idx,:);
            X_test = X(test_idx,:);
            
            Y_train = Y(train_idx);
            Y_test = Y(test_idx);
            
            %% Perform one-vs-one classifical for all (k choose 2) pairs
            Mdl = fitcecoc(X_train, Y_train, 'Coding', 'onevsone', 'Learners', T);
            
            %% Calculate fold accuracy
            preds = predict(Mdl, X_test);
            fold_accs(part_id) = mean(preds == Y_test);
            
            %% Extract fold Betas
            for learn_id=1:n_learners
                fold_betas(:,part_id,learn_id) = Mdl.BinaryLearners{learn_id}.Beta;
            end
        end
        Accs(run_id) = mean(fold_accs);
        Betas(:,run_id,:) = squeeze(mean(fold_betas,2));
    end
         
    assignin('base','Accs',Accs);
    assignin('base','Betas',Betas);
    Acc = mean(Accs);
    Beta = squeeze(mean(Betas,2));