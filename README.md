# Usage Instruction

Copy your train data into `.\brain_B0maps\train`. Check structure of the example train data and adapt your B0-maps accordingly. All the B0 maps in the train folder must have a same FoV and resolution. The name of the variable contains B0-map must be 'brain'. 
The structure of train data is a following:
```
* brain.b0map : 3D B0 map of brain (unit: Hz)
* brain.mask  : a mask to exclude everything outside brain. non ROI must be filled with nan (not with zero)
* brain.img   : magnitude image.
* brain.pixel : [x,y,z] number of voxels in each dimension
* brain.fov   : [x1,y1,z1;x2,y2,z2] define beginning and end of FoV in each dimension (unit: mm)
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

