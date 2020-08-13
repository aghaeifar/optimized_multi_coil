
%
% This code shows examples of coils optimization
% Please see 'READ_ME' for more details
%
% Author: Ali Aghaeifar <ali.aghaeifar@tuebingen.mpg.de>
% Created: April 2019
%

addpath(genpath('.\dependencies'));

%% Generate a Profile   
% a profile contains some of the required settings for optimization. Rest of the settings can be changed by modyfing 'opt_profile_manager.m'                        
profile  = opt_profile_manager('shim_mode', 'global',...              % Skope of optimization, global or slice-wise
                               'shim_algo_inner', 'pinv',...          % The algorithm used for calculation of shim currents; 'pinv' for unconstrained shimming and 'lsqlin' for constrained shimming
                               'shim_algo_outer', 'sqp',...		    % The solver used for optimization of coils' position and size
                               'coil_shape', 'square', ...             % Shape of the coils, 'square' or 'circle' 
                               'overlapping_coef', 0,...				    % Nonlinear constraint weight. Here is the coils overlapping. 
                               'dynammic_current_bound', true,...                    % Adjust coil's current based on the coil's size.          
                               'coil_no_row_rad', [32,4,30], ...            % Initial coils arrangment, [number of coils, number of rows, size of the coils]
                               'prefix', 'Unconstrained_CoilSize30');   % A prefix for the name of destination folder (results will be saved there)

opt_main(profile); % execute optimization based on the profile
							   							   
