function [fov_grids, fov] = fov_make(fov_vol, fov_size)
%
% This script generate proper FoV grid for biot-savart simulation script
% Inputs  
%   fov_vol : volume of FoV, a single number for equal FoV for all dimensions or 2*3 matrix to specify start and end points [x_start, y_start, z_start; x_end, y_end, z_end]
%   fov_size: number of points in each dimension, a single number for equal size for all dimensions or 1*3 matrix to specify size for the individual dimensions
%

if numel(fov_vol) == 1
    fov.fov  = [-fov_vol, -fov_vol ,-fov_vol; ...
                 fov_vol, fov_vol, fov_vol]/2;        
elseif isequal(size(fov_vol), [2 3])
    fov.fov = fov_vol;
elseif isequal(size(fov_vol), [3 2])
    fov.fov = transpose(fov_vol);
else
    error('fov_vol is not in one of the recognized structures');
end

 % fov matrix size, Resolution = fov.fov ./ fov.fov_size
if numel(fov_size) == 1
    fov.fov_size  = [fov_size, fov_size, fov_size];
elseif numel(fov_size) == 3
    fov.fov_size = fov_size;
else
    error('fov_size is not in one of the recognized structures');
end

fov.voxel_offset    = (fov.fov(2,:)-fov.fov(1,:)) ./ fov.fov_size / 2;
fov.dim_start       = fov.fov(1,:) + fov.voxel_offset;
fov.dim_stop        = fov.fov(2,:) - fov.voxel_offset;
fov.dim_skip        = (fov.dim_stop - fov.dim_start) ./ (fov.fov_size-1);
fov.dim_x           = fov.dim_start(1):fov.dim_skip(1):fov.dim_stop(1);
fov.dim_y           = fov.dim_start(2):fov.dim_skip(2):fov.dim_stop(2);
fov.dim_z           = fov.dim_start(3):fov.dim_skip(3):fov.dim_stop(3);
[fov.fov_x, fov.fov_y, fov.fov_z] = ndgrid(fov.dim_x, fov.dim_y, fov.dim_z);
fov_grids           = [fov.fov_x(:), fov.fov_y(:), fov.fov_z(:)];