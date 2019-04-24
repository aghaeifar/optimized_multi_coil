function coef = calcShim_fmincon(MapB0, MAP_Shims, currLimL, currLimU, myAlgorithm, showProgress)

%
% MapB0     = 1*m
% MAP_Shims = n*m
% coef      = n*1 % but after transpose
%
    % Run optimization
    if nargin < 6
        showProgress = 'iter-detailed';
    end
    myAlgList = {'interior-point', 'sqp'};  
    
    options = optimoptions('fmincon','SpecifyObjectiveGradient',true, 'Display', showProgress, 'Algorithm', myAlgList{myAlgorithm}, 'MaxFunEvals', 10^6, 'MaxIter', 100000);
    coef = fmincon(@(x) minimizeErrFunCore(x, MapB0, MAP_Shims), zeros(1, size(MAP_Shims, 1)), [], [], [], [], currLimL, currLimU, [], options); 
    coef = transpose(coef); 
end
%%
function [err, grad] = minimizeErrFunCore(x, MapB0, Map_Shims)
    err = sum((MapB0 + x*Map_Shims).^2);
    if nargout > 1 % gradient required
        grad = 2*(MapB0 + x*Map_Shims)*Map_Shims';
    end
end
