function [z, theta] = coil_pos_init(nCoil, nRow, rCoil, lCyln)

% Calculate position of coil (symmetrical) on surface of a cylinder in cylindrical coordinate system
% INPUT:
%       nCoil: total number of coils
%       nRows: number of rows to arrange coils
%       rCoil: radius of coil 
%       lCyln: length of cylinder
%
% OUTPUT:
%       z: elevation of coil
%       theta: angle between the reference direction and center of coil direction
%

coil_per_row= nCoil/nRow;
z           = zeros(nRow, coil_per_row);
theta       = zeros(nRow, coil_per_row);
% dis_per_row = 2*pi*rCyln/coil_per_row;
if numel(lCyln) == 2 % when start and end points of cylinder exist
    z_row = linspace(lCyln(1) + rCoil, lCyln(2) - rCoil, nRow);
else
    z_row = linspace(-lCyln/2 + rCoil, lCyln/2 - rCoil, nRow);
end
%     error('Overlap betweem coils happened');
% end

if nRow == 1
   z_row = 0; 
end

for i=1:nRow
    z(i,:) = z_row(i);
    theta(i,:) = linspace(0, 2*pi-2*pi/coil_per_row, coil_per_row) + mod(i+1,2)*pi/coil_per_row;
end