function profile = opt_profile_manager(varargin)
	if(mod(nargin,2))
		error('Number of arguments must be even')
	end
	profile = parse_inputs(varargin{:});
end % opt_profile_manager

function param = parse_inputs(varargin)
	parser = inputParser;
	parser.PartialMatching = false;
    
	addParameter(parser, 'shim_mode', 'global', @(x) assert(ismember(x, ["global","slice_wise_tra", "slice_wise_sag", "slice_wise_cor"]), 'Invalide shim mode'));
	addParameter(parser, 'shim_algo_inner', 'lsqlin', @(x) assert(ismember(x, ["lsqlin","pinv", "fmincon"]), 'Invalide shim algorithm (inner)'));
	addParameter(parser, 'shim_algo_outer', 'sqp', @(x) assert(ismember(x, ["sqp","interior-point","sqp-legacy","active-set"]), 'Invalide shim algorithm (outer)'));
	addParameter(parser, 'coil_shape', 'square', @(x) assert(ismember(x, ["square","circle"]), 'Invalide coil shape'));
	addParameter(parser, 'overlapping_coef', 0, @(x) assert(isnumeric(x) && numel(x) == 1 && (x>=0), 'Invalide overlapping coefficient'));
	addParameter(parser, 'dynammic_current_bound', 'true', @(x) assert(islogical(x), 'Use true or false for "dynammic current bound"'));
	addParameter(parser, 'save_path', 'empty', @(x) assert(ischar(x), 'Invalid prefix'));
	addParameter(parser, 'prefix', '', @(x) assert(ischar(x), 'Invalid prefix'));
	addParameter(parser, 'coil_no_row_rad', [32, 4, 30], @(x) assert(isnumeric(x) && numel(x) == 3 && all(x>0), 'Invalid coil [number, row, radius]'));
	addParameter(parser, 'cylinder_radius', 165, @(x) assert(isnumeric(x) && numel(x) == 1 && (x>0), 'Invalid cylinder_radius'));
	addParameter(parser, 'coil_radius_bound', [10 50], @(x) assert(isnumeric(x) && numel(x) == 2 && all(x>0), 'Invalid coil_radius_bound'));
	addParameter(parser, 'current_bound', 1.5, @(x) assert(isnumeric(x) && numel(x) == 1 && x>0, 'Invalid current_bound'));
	addParameter(parser, 'init_configuration', [], @(x) assert(isnumeric(x) && any(size(x) == 3), 'Invalid init_configuration')); % [coilN x 3] = [z, theta, r];

	parse(parser, varargin{:});

	param.shim_mode 		= parser.Results.shim_mode;
	param.shim_algo_inner 	= parser.Results.shim_algo_inner;
	param.shim_algo_outer 	= parser.Results.shim_algo_outer;
	param.coilShape 		= parser.Results.coil_shape;			% <'circle' | 'square'>
	param.nonlconCoef 		= parser.Results.overlapping_coef;      % weight parameter; we can call nonlconFun inside the objective function and give it a weight	

	param.cylnR             = parser.Results.cylinder_radius;       % mm, radius of cylinder
	param.coilN 			= parser.Results.coil_no_row_rad(1);	% total numer of coils
	param.coilNRow 			= parser.Results.coil_no_row_rad(2);	% Number of rows in initial configuration
	param.coilRD 			= parser.Results.coil_no_row_rad(3);	% mm, radius of coils, default value
	param.coilZLL           = -200;                                 % mm, coil position in z axis, lower limit (-150)
	param.coilZUL           = 130;                                  % mm, coil position in z axis, upper limit (80)
	param.coilThetaLL       = -inf;                                 % rad, coil angle lower limit
	param.coilThetaUL       = +inf;                                 % rad, coil angle in z axis upper limit
	param.coilDiv           = 12;                                   % # of coil segments
	param.coilTurn          = 25;                                   % # of wire turn per coil
	param.coilRUL           = max(parser.Results.coil_radius_bound);% mm, radius of coils upper limit
	param.coilRLL           = min(parser.Results.coil_radius_bound);% mm, radius of coils lower limit
	param.shimCL 			= max(parser.Results.current_bound);    % A, current bound
	param.shimCUL           = param.shimCL*ones(param.coilN, 1);    % Amperage, shim coils current upper limit when param.shim_algo_inner is not 'pinv'
	param.shimCLL           = -param.shimCUL;                       % Amperage, shim coils current lower limit when param.shim_algo_inner is not 'pinv'
	param.shimDCL 			= parser.Results.dynammic_current_bound;% dynamic current limit adjustment based on the coil size. A coil with a radius of param.coilRUL -> ±param.shimCL

    if ~isempty(parser.Results.init_configuration)
        if size(parser.Results.init_configuration, 1) == 3
            parser.Results.init_configuration = transpose(parser.Results.init_configuration);
        end
        param.initCoilPos.z		= parser.Results.init_configuration(:,1);
        param.initCoilPos.theta	= parser.Results.init_configuration(:,2);
        param.initCoilPos.r		= parser.Results.init_configuration(:,3);
        param.coilN             = size(parser.Results.init_configuration, 1);
        if any(param.initCoilPos.z+param.initCoilPos.r>param.coilZUL) || any(param.initCoilPos.z-param.initCoilPos.r<param.coilZLL)
            error('Initial Coil Configuration does not satisfy the constraints in Z axis');
        end
        if any(param.initCoilPos.r>param.coilRUL) || any(param.initCoilPos.r<param.coilRLL)
            error('Initial Coil Configuration does not satisfy the constraints of coils'' radius');
        end
    else
        offset = param.coilRUL - param.coilRD + sqrt(eps); % needed to fulfill the bounds
        [param.initCoilPos.z, param.initCoilPos.theta] = coil_pos_init(param.coilN, param.coilNRow, param.coilRD, [param.coilZLL+offset, param.coilZUL-offset]); %
        param.initCoilPos.r = param.coilRD*ones(param.coilNRow, param.coilN/param.coilNRow);
    end
      
	param.name          = [parser.Results.prefix, num2str(param.coilN), '_',param.shim_algo_outer, '_', param.shim_algo_inner, '_',...
                               param.coilShape, '_', param.shim_mode, '_', 'dcl', num2str(param.shimDCL), '_', 'nonlcon', num2str(param.nonlconCoef)];
	param.savePath      = parser.Results.save_path;
    if strcmp(param.savePath, 'empty')
        param.savePath 	= fullfile(fileparts(mfilename('fullpath')), 'profiles', 'opt_results', param.name);  % where to save simulation results
    end
end


