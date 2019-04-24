# Usage Instruction
## Train Data
Copy your train data into `.\brain_B0maps\train`. Check structure of the example train data and adapt your B0 maps accordingly. All the B0 maps in the train folder must have a same FoV and resolution. The name of the variable contains B0 map must be `brain`. 
The structure of train data is a following:
```
* brain.b0map : 3D B0 map of brain (unit: Hz)
* brain.mask  : a mask to exclude everything outside brain. non ROI must be filled with nan (not with zero)
* brain.img   : magnitude image.
* brain.pixel : [x,y,z] number of voxels in each dimension
* brain.fov   : [x1,y1,z1;x2,y2,z2] define beginning and end of FoV in each dimension (unit: mm)
```
## Optimization Settings 
Use `opt_profile_manager.m` to configure the optimization. For an example:
```
profile  = opt_profile_manager('shim_mode', {'global'},...              % Skope of optimization, global or slice-wise
                               'shim_algo_inner', {'pinv'},...          % The algorithm used for calculation of shim currents; 'pinv' for unconstrained shimming and 'lsqlin' for constrained shimming
                               'shim_algo_outer', {'sqp'},...		% The solver used for optimization of coils' position and size
                               'coilShape', {'square'}, ...             % Shape of the coils, 'square' or 'circle' 
                               'nonlconCoef', [0],...			% Nonlinear constraint weight. Here is the coils overlapping. 
                               'shimDCL', [true],...                    % Adjust coil's current based on the coil's size.          
                               'coil_no_row', [32,4,30], ...            % Initial coils arrangment, [number of coils, number of rows, size of the coils]
                               'prefix', 'Unconstrained_CoilSize30');   % A prefix for the name of destination folder (results will be saved there)
```


Optimization of coils arrangment & size in a multi-coil shim setup.


User can define the initial positions of the coils (normally a symmetric arrangment).  



You can replace the matlab code for simulation of Biot-savart law with the following mex file (4x faster)
https://github.com/Aghaeifar/Biot-Savart-Matlab-mex

Questions, bug reports, and suggestions are welcome.  Please contact:
Ali Aghaeifar <ali.aghaeifar[at]tuebingen.mpg.de>


# Requirements:
Matlab with the following toolboxes 
* optimization_toolbox
* statistics_toolbox
* distrib_computing_toolbox

