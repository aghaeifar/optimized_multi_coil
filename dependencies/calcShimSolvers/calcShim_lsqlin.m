function coef = calcShim_lsqlin(MapB0, MAP_Shims, currLimL, currLimU, showProgress)

%
% MapB0     = 1*m  % function will transpose it later
% MAP_Shims = n*m  % function will transpose it later
% coef      = n*1 
%

if nargin < 5
    showProgress = 'iter-detailed';
end
if isempty(MapB0) || isempty(MAP_Shims)
    coef = zeros(size(MAP_Shims,1), 1);
else
    %% Run optimization
    options = optimoptions('lsqlin','Display', showProgress, 'Algorithm', 'interior-point', 'MaxIter', 100000); % sometimes the method gives not results as well as fmincon without this options
    coef = lsqlin(MAP_Shims', -MapB0', [], [], [], [], currLimL, currLimU,[],options);
end   