function coilpos = coil_pos_make(z, theta, rCoil, rCyln, div, shape)

% Generate spatial position of the coil for the latter plotting and simulation
% Input:
%   z     : (n*1) elevation of the coil center
%   theta : (n*1)angle between the reference direction and center of
%           coil direction, unit is radian
%   rCoil : (1,n*1) radius of coils
%   rCyln : radius of cylinder
%   div   : subsegment of the coils
%   shape : shape of the coils, two options: circle or square
%   enPlot: plot results
%

if nargin <5
    div = 16;
end
if nargin <6 || isempty(shape)
    shape = 'circle';
end

nCoil = numel(z);
if numel(rCoil) == 1 % if there is just one radius, use it for all coils
    rCoil = rCoil*ones(nCoil,1);
end
if numel(rCyln) == 1
    rCyln = rCyln*ones(nCoil,1);
end
coilpos = cell(nCoil,1);

%%
for j=1:nCoil
    % Make a sample circle | square  
    if strcmp(shape, 'square')
        d = round(div/2);
        coil = [linspace(-rCoil(j), +rCoil(j), d), linspace(rCoil(j), -rCoil(j), d); 0*ones(1,2*d); -rCoil(j)*ones(1,d), rCoil(j)*ones(1,d)];
    else 
        d = 1:div;
        coil = [rCoil(j)*cos(2*pi/div*d); 0*ones(1,div); rCoil(j)*sin(2*pi/div*d)]; % a circle in XZ plane
    end
    coil(:,end+1) = coil(:,1); % the last point is the first point
    % Project circles to the cylinder surface
    for i=1:size(coil,2)
        phi = 90 - (180 - rad2deg(coil(1,i)/rCyln(j)))/2; % find rotation angle around the Z axis
        coil(:,i) = zrot(-phi) * coil(:,i);
    end
    coil(2,:) = coil(2,:) + rCyln(j); % Move to the cylinder surface in Y axis
    % Rotate    
    c3  = zrot(rad2deg(theta(j))) * coil;
    c3(3,:) = c3(3,:) + z(j);
    coilpos{j}.data = c3;
end

