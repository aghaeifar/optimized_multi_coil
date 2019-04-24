

function [shimmed, coef] = opt_core_shim(mapB0, mapShim, param)
%
% This function gets B0 map and the shim profiles and try to shim according
% to the settings in 'param'
% Author: Ali Aghaeifar (ali.aghaeifar@tuebingen.mpg.de)
% Arguments:
%   mapB0: B0 map of the brain (n*m*l)
%   mapShim: shim profiles (#maps*n*m*l)
%

    mapShim_bu = mapShim; % backup
    mapB0_bu   = mapB0; % backup
    
    if strcmp(param.shim_mode, 'global') % optimize for global whole brain shimming
        mapShim = reshape(mapShim_bu, param.coilN, []);
        mapB0   = reshape(mapB0_bu, 1, []);
        mapShim(:, isnan(mapB0)) = []; % remove corresponding nan pixels of mapB0 in mapShim
        mapB0(isnan(mapB0))      = [];        
        coef = calc_shim_alg(mapB0, mapShim, param.shim_algo_inner, param.shimCLL, param.shimCUL);
        shimmed = squeeze(sum(bsxfun(@times, coef, mapShim_bu),1)) + mapB0_bu;
    else
        switch param.shim_mode
            case 'slice_wise_tra' % optimize for dynamic slice-wise shimming
                permute_order = [1 2 3];
            case 'slice_wise_cor'
                permute_order = [1 3 2];
            case 'slice_wise_sag'
                permute_order = [2 3 1];
            otherwise
                error('Invalid shim mode');
        end        
        mapB0   = permute(mapB0_bu, permute_order);             % target dim is moved to end
        mapShim = permute(mapShim_bu, [1 permute_order+1]);     % the first dim is maps #
        shimmed = permute(zeros(size(mapB0_bu)), permute_order);
        coef    = zeros(size(mapShim_bu,1), size(mapB0, 3));  % ([# of maps] * [# of slices])
        for i=1:size(mapB0, 3)
            mapShim_t = reshape(mapShim(:,:,:,i), param.coilN, []); % select a single slice
            mapB0_t   = reshape(mapB0(:,:,i), 1, []);
            mapShim_t(:, isnan(mapB0_t)) = []; % remove corresponding nan pixels of mapB0 in mapShim
            mapB0_t(isnan(mapB0_t))      = [];
            coef(:,i) = calc_shim_alg(mapB0_t, mapShim_t, param.shim_algo_inner, param.shimCLL, param.shimCUL);
            shimmed(:,:,i) = squeeze(sum(bsxfun(@times, coef(:,i), mapShim(:,:,:,i)),1)) + mapB0(:,:,i);
        end
        shimmed = ipermute(shimmed, permute_order);
    end
end 

function coef = calc_shim_alg(mapB0, mapShim, opt_method, LL, UL)
    if strcmp(opt_method, 'pinv')
        coef = calcShim_pseudoInverse(mapB0, mapShim, 'svd'); % calcShim_pseudoInverse(mapB0, mapShim, 'inv');
    elseif strcmp(opt_method, 'consTru')
        coef = calcShim_consTru(mapB0, mapShim, LL, UL);
    elseif strcmp(opt_method, 'fmincon')
        coef = calcShim_fmincon(mapB0, mapShim, LL, UL, 1, 'off');
    elseif strcmp(opt_method, 'lsqlin')
        coef = calcShim_lsqlin(mapB0, mapShim, LL, UL, 'off');
    end
end