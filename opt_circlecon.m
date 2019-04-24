function [c, ceq] = opt_circlecon(x, param)
    % this function is used to check there is no overlap between coils
    % x: n*3 (z, theta, r)
    z       = x(:,1);
    theta   = x(:,2);
    rCoil   = x(:,3); 
    
    theta   = mod(theta, 2*pi); % we are un-bounded for theta and need to wrap values between 0 and 2pi
    dTheta  = abs(bsxfun(@minus, theta, theta'));   % find angular difference
    dTheta(dTheta > pi) = 2*pi - dTheta(dTheta > pi); % use shorter path
    dZ      = abs(bsxfun(@minus,z, z'));
    sRcoil  = bsxfun(@plus,rCoil, rCoil');
    
    if strcmp(param.coilShape, 'square')
        D = max(sRcoil - dZ, sRcoil - param.cylnR*dTheta); % Maximum of overlap in vertical and horizontal direction
    else % we have circular coils
        D = sRcoil.^2 - (dZ.^2 + (param.cylnR*dTheta).^2); % D shows how much two circles overlapped 
    end 

    idx = 1==eye(param.coilN);
    D(idx) = -inf;  
    
    c = max(D, [], 2);    
    ceq     = [];
end