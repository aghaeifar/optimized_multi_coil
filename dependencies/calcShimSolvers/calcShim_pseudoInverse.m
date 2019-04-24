function coef = calcShim_pseudoInverse(MapB0, MAP_Shims, method)
%
% MapB0     = 1*m
% MAP_Shims = n*m
% coef      = n*1 % but after transpose
%

if nargin < 3
    method = 'svd';
end

%% Apply pseudoinverse
if strcmp(method, 'svd')
    MAP_Shims_inv = pinv(MAP_Shims);
elseif strcmp(method, 'inv') % this approach is faster
    MAP_Shims_inv = transpose(MAP_Shims)/(MAP_Shims*transpose(MAP_Shims));
end

coef = transpose(-MapB0 * MAP_Shims_inv);
% fval =  sqrt(sum((MapB0 + x*MAP_Shims).^2));
        