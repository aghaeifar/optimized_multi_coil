function opt_main(profiles)
%
% use 'opt_profile_manager.m' to generate proper profles 
% profiles = opt_profile_manager('shim_mode', {'global', 'slice_wise_tra', 'slice_wise_sag', 'slice_wise_cor'}, 'shim_algo_inner', {'lsqlin', 'pinv'}, 'coilShape', {'circle'}, 'nonlconCoef', [0], 'shimDCL', [false, true]); 
%

if nargin <1
   error('Optimization profile is empty'); 
end
% List profiles and brains B0 map
addpath(fullfile(fileparts(mfilename('fullpath')), 'brain_B0maps'));

% Load B0 maps of the brain which is used as target for optimizer
subjects.folderTrain    = fullfile(fileparts(mfilename('fullpath')), 'brain_B0maps', 'train');
subjects.folderTest     = fullfile(fileparts(mfilename('fullpath')), 'brain_B0maps', 'test');
b0List                  = dir(fullfile(subjects.folderTrain, '*.mat'));
subjects.b0mapTrain_Add = fullfile(subjects.folderTrain, {b0List(:).name});
b0List                  = dir(fullfile(subjects.folderTest, '*.mat'));
subjects.b0mapTest_Add  = fullfile(subjects.folderTest, {b0List(:).name});

brain_B0map = cell(numel(subjects.b0mapTrain_Add) ,1);
for j=1:numel(subjects.b0mapTrain_Add)
    if isempty(getCurrentTask()) % don't show this message when is running on a worker
        disp(['Importing B0 map: ' subjects.b0mapTrain_Add{j}]);
    end
    load(subjects.b0mapTrain_Add{j}); % contains variable 'brain'
    brain_B0map{j} = double(brain.b0map .* brain.mask);
    clear brain;
end

for i=1:numel(profiles)
    % load settings
    if numel(profiles) == 1 && ~iscell(profiles)
        param = profiles;
    else
        param = profiles{i}; 
    end
    disp(['Running profile: ', '''',  param.name, '''']);
    param.b0mapNTrain       = numel(subjects.b0mapTrain_Add);
    param.b0mapTrain_Add    = subjects.b0mapTrain_Add;
    param.b0mapNTest        = numel(subjects.b0mapTest_Add);
    param.b0mapTest_Add     = subjects.b0mapTest_Add;
    param.fov               = brain.fov;        % mm
    param.fov_size          = brain.pixel;      % fov matrix size, Resolution = fov.fov ./ fov.fov_size
    
    if ~exist(param.savePath, 'dir')  % Folder does not exist? create it.
        mkdir(param.savePath);
    end

    % FoV setup
    [~, fov] = fov_make(brain.fov, brain.pixel);

    % Initial position
    [initCoilPos.z, initCoilPos.theta] = coil_pos_init(param.coilN, param.coilNRow, param.coilRD, [param.coilZLL, param.coilZUL]);
    initCoilPos.r = param.coilRD*ones(param.coilNRow, param.coilN/param.coilNRow);

    % Configure optimiztion process
    problem.x0          = [initCoilPos.z(:), initCoilPos.theta(:), initCoilPos.r(:)]; % [elevation of the coils in cylinder, angular position of the coils in cylinder, radius of the coils]
    problem.ub          = repmat([param.coilZUL-param.coilRUL, param.coilThetaUL, param.coilRUL], [param.coilN, 1]); %upper boundy
    problem.lb          = repmat([param.coilZLL+param.coilRUL, param.coilThetaLL, param.coilRLL], [param.coilN, 1]); %lower boundy
    problem.nonlcon     = param.nonlconFun;
    problem.objective   = @(x) opt_core(x, brain_B0map, param, fov);
    outfun              = @(x,optimValues,state) opt_outfun(x, optimValues, state, param);
    problem.solver      = 'fmincon';
    % see: https://www.mathworks.com/help/optim/ug/tolerances-and-stopping-criteria.html
    % interior-point algorithm does not support the function value stopping criterion ('FunctionTolerance')
    problem.options     = optimoptions(@fmincon, 'Algorithm', param.shim_algo_outer, 'Display', 'off', 'MaxFunEvals', 1e6, 'MaxIter', 1e5, 'OutputFcn', outfun);%, 'UseParallel', 'always'); % 'StepTolerance' 'FunctionTolerance'
    xFinal              = fmincon(problem);
    finalCoilPos        = struct('z', xFinal(:,1), 'theta', xFinal(:,2), 'r', xFinal(:,3));
    % update current limitation 
    if param.shimDCL % is dynamic current limitation enabled
        param.shimCUL = opt_currentAdj(param.shimCL, param.coilRUL, finalCoilPos.r);
        param.shimCLL = -param.shimCUL;
    end
    % Save results
    save(fullfile(param.savePath, 'opt_results.mat'), 'finalCoilPos', 'initCoilPos', 'fov', 'param');
end

