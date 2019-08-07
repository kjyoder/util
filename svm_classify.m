function [Acc, Beta] = svm_classify(X, Y, varargin)
% SVM_CLASSIFY()
%   Train a linear SVM to classify between 2+ classes in Y based on X.
%
% Usage:
%   > [Acc, Beta] = svm_classify(X, Y, ...);
%
% Parameters:
%   X   predictor matrix (n samples x p predictors)
%
%   Y   vector of target labels (one for each n sample)
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
    
    %% Create the SVM template
    T = templateSVM('Standardize', 1, 'KernelFunction', 'linear');
    
    %% Perform one-vs-one classifical for all (k choose 2) pairs
    Mdl = fitcecoc(X, Y, 'Coding', 'onevsone', 'Learners', T);
    
    %% Preallocate outputs
    Accs = zeros(nruns, 1);
    n_classes = numel(unique(Y));
    n_learners = nchoosek(n_classes,2);
    Betas = zeros(size(X,2), npart, n_learners);
    
    %% Calculate cross-validated accuracy
    for run_i=1:nruns
        CVMdl = crossval(Mdl, 'kfold', npart);
        Accs(run_i) = 1-kfoldLoss(CVMdl);
    end
    
    Acc = mean(Accs);
    
    %% Calculate feature beta weights
    for part_i=1:npart
        for learn_i=1:n_learners
            Betas(:,part_i,learn_i) = CVMdl.Trained{part_i}.BinaryLearners{learn_i}.Beta;
        end
    end
    Beta = squeeze(mean(Betas,2));