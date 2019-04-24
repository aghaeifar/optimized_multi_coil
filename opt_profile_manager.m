function profiles = opt_profile_manager(varargin)
%
% Generate a list of profiles which are used as a configuration for optimization of coils position 
% opt_profile_manager('shim_mode', {'global', 'slice_wise_tra', 'slice_wise_sag'}, 'shim_algo_inner', {'lsqlin', 'pinv'}, 'coilShape', {'circle'}, 'nonlconCoef', [0], 'shimDCL', [false, true]);
%

if(mod(nargin,2))
    error('Number of arguments must be even')
end

shim_mode       = {'global', 'slice_wise_tra', 'slice_wise_sag', 'slice_wise_cor'};
shim_algo_inner = {'lsqlin', 'pinv'};
shim_algo_outer = {'interior-point', 'sqp'}; % 'interior-point', 'sqp', 'active-set', 'sqp-legacy'
coilShape       = {'circle', 'square'};
nonlconCoef     = [0, 100];
shimDCL         = [false, true];
parent_path     = fileparts(mfilename('fullpath'));
prefix          = '';
coil_no_row     = [32, 4, 30];
for i=1:2:nargin
    switch varargin{i}
        case 'shim_mode'
            shim_mode = varargin{i+1};
        case 'shim_algo_inner'
            shim_algo_inner = varargin{i+1};
        case 'shim_algo_outer'
            shim_algo_outer = varargin{i+1};
        case 'coilShape'
            coilShape = varargin{i+1};
        case 'nonlconCoef'
            nonlconCoef = varargin{i+1};
        case 'shimDCL'
            shimDCL = varargin{i+1};
        case 'parent_path'
            parent_path = varargin{i+1};
        case 'prefix'
            prefix = varargin{i+1};
        case 'coil_no_row'
            coil_no_row = varargin{i+1};
    end
end

param.cylnR             = 165;          % mm, radius of cylinder
param.coilN             = 32;           % total numer of coils
param.coilNRow          = 4;            % Number of rows in initial configuration
param.coilRD            = 40;%30;       % mm, radius of coils, default value
param.coilRLL           = 10;           % mm, radius of coils lower limit
param.coilRUL           = 50;           % mm, radius of coils upper limit
param.coilZLL           = -200;         % mm, coil position in z axis, lower limit (-150)
param.coilZUL           = 130;          % mm, coil position in z axis, upper limit (80)
param.coilThetaLL       = -inf;         % rad, coil angle lower limit
param.coilThetaUL       = +inf;         % rad, coil angle in z axis upper limit
param.coilShape         = 'circle';     % <'circle' | 'square'>
param.coilDiv           = 12;           % # of coil segments
param.coilTurn          = 25;           % # of wire turn per coil
param.shim_algo_inner   = 'lsqlin';     % <'pinv' | 'fmincon' | 'consTru' | 'lsqlin'> algorithm to calculate shim coefficients, this is not for coil position optimization
param.shim_algo_outer   = 'sqp';        % 'interior-point'
param.shim_mode         = 'global';     % <'global' | 'slice-wise'> shimming mode,
param.shimCL            = 1.5;			% Current limit
param.shimCLL           = repmat(-param.shimCL, [param.coilN, 1]);   % Amperage, shim coils current lower limit when param.shim_algo_inner is not 'pinv'
param.shimCUL           = repmat(+param.shimCL, [param.coilN, 1]);   % Amperage, shim coils current upper limit when param.shim_algo_inner is not 'pinv'
param.shimDCL           = false;        % dynamic current limit adjustment based on the coil size. A coil with a radius of param.coilRUL -> ±param.shimCL
param.nonlconFun        = [];           %@(x) opt_circlecon(x, param);
param.nonlconCoef       = 0;            % weight parameter; we can call nonlconFun inside the objective function and give it a weight

%generate all possible profiless
profiles = cell(numel(shim_algo_outer)*numel(shim_algo_inner)*numel(shimDCL)*numel(coilShape)*numel(nonlconCoef)*numel(shim_mode)*size(coil_no_row, 1), 1);
ind = 0;
for shim_algo_o = 1:numel(shim_algo_outer)
    for shim_algo_i = 1:numel(shim_algo_inner)
        for shimDCL_c = 1:numel(shimDCL)
            for coilShape_c = 1:numel(coilShape)
                for nonlconCoef_c = 1:numel(nonlconCoef)
                    for shim_mode_c = 1:numel(shim_mode)
                        for coil_no_row_c = 1:size(coil_no_row, 1)
                            ind                     = ind + 1;
                            param.shim_mode         = shim_mode{shim_mode_c};
                            param.shim_algo_inner   = shim_algo_inner{shim_algo_i};
                            param.shim_algo_outer   = shim_algo_outer{shim_algo_o};
                            param.coilShape         = coilShape{coilShape_c};
                            param.nonlconCoef       = nonlconCoef(nonlconCoef_c);
                            param.shimDCL           = shimDCL(shimDCL_c);                            
                            param.coilN             = coil_no_row(coil_no_row_c, 1);
                            param.coilNRow          = coil_no_row(coil_no_row_c, 2);
                            param.coilRD            = coil_no_row(coil_no_row_c, 3);
                            param.shimCUL           = repmat(+param.shimCL, [param.coilN, 1]); 
                            param.shimCLL           = -param.shimCUL;
                            
                            param.name              = [prefix,num2str(param.coilN),'_',param.shim_algo_outer,'_',param.shim_algo_inner,'_',param.coilShape,'_',param.shim_mode,'_','dcl',num2str(param.shimDCL),'_','nonlcon',num2str(param.nonlconCoef)];
                            param.savePath          = fullfile(parent_path, 'profiles', 'opt_results', param.name);  % where to save simulation results
                            profiles{ind}           = param;
                        end
                    end
                end
            end
        end
    end
end
 

