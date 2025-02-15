# Usage Instruction
This code optimize size and position of individual coils to improve shimming capability of a multi-coil shim setup.


![alt text](https://github.com/aghaeifar/optimized_multi_coil/blob/master/coilPos.jpg?raw=true)


## Requirements:
Matlab with the following toolboxes 
* optimization_toolbox
* statistics_toolbox
* distrib_computing_toolbox
## Train Data
Copy your train data into `.\brain_B0maps\train`. Check structure of the example train data and adapt your B0 maps accordingly. All the B0 maps in the train folder must have a same FoV and resolution. The name of the variable contains B0 map must be `brain`. 

The structure of train data is:
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
profile  = opt_profile_manager('shim_mode', 'global',...              % Scope of optimization, global or slice-wise
					'shim_algo_inner', 'pinv',...          % The algorithm used for calculation of shim currents; 'pinv' for unconstrained shimming and 'lsqlin' for constrained shimming
					'shim_algo_outer', 'sqp',...		% The solver used for optimization of coils' position and size
					'coil_shape', 'square', ...             % Shape of the coils, 'square' or 'circle' 
					'overlapping_coef', 0,...			% Nonlinear constraint weight. Here is the coils overlapping. 
					'dynammic_current_bound', true,...                    % Adjust coil's current based on the coil's size.          
					'coil_no_row_rad', [32,4,30], ...            % Initial coils arrangment, [number of coils, number of rows, size of the coils]
					'prefix', 'Unconstrained_CoilSize30');   % A prefix for the name of destination folder (results will be saved there)
                               
```
Modify `opt_profile_manager.m` to change the optimization constraints. Boundries for coil size, position, cylinder size, and many others are in `opt_profile_manager.m` 

## Results
The result will be stored in destination folder at the end of the optimization. The destination folder is located in `.\profiles\opt_results\name_of_folder`. There will be two files: `opt_progress.mat` and `opt_results.mat`.

`opt_progress.mat` contains some information about progress of the optimization in different iterations. 

`opt_results.mat` contains initial and final coils position & size and configuration parameters.

## Is it slow?
The program comprises a lot of computations. Although the magnetic field for individual coils are computed in parallel, it may take several hours or days to complete the optimization. Here are some tips for you:
- Remove everything outside of the brain by cropping your B0 maps. 
- You can replace the matlab code for simulation of Biot-savart law with the following mex file (4x faster)
https://github.com/Aghaeifar/Biot-Savart-Matlab-mex
- If you want to force the program to stop, simply go to the destination folder, create `stop.txt` and write `1` in the file. The program checks this file every 10 iterations and will stop and save the results up to the current iteration if the file exists and contains `1`. 

# Contact me
Do you have questions or want to report a bug? Is there any suggestions? Just write me:

Ali Aghaeifar <ali.aghaeifar.mri[at]gmail[dot]com>




