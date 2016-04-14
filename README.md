# DW-Graph package

Basic useful feature list:

 * Create and save QAC-ME graphs from given solver.
 * Submit problems on D-Wave machine on physical or QAC graphs.
 * Built-in exception handling when problems return error from machine.
 * Tries to work around various SAPI bugs in MATLAB, like a robust submission mechanism that continues to submit problems across time slots.

This is a derived package based on D-Wave SAPI version 2.3.1 . Refer to D-Wave guide on how to properly configure SAPI package for use in MATLAB. 

### Requirements

* A local TeX installation, like MacTeX on OS X, MiKTex on Windows and TexLive on Linux.
* Working SAPI package in MATLAB.
* MATLAB 2013a or above.

To use the package, first clone the repository in somewhere on your computer, say the home folder by this command. 

```shell
$ cd
$ mkdir matlab-package && cd matlab-package
$ git clone http://flux.usc.edu/gitlab/anuragm/dwGraph.git +dwGraph
```

Include the folder `matlab-package` in your MATLAB path, and you are all set!

### Basic Usage

Before you start any cumputation, you will have to tell the package about you SAPI server,token and the solver name. To do so, call the initialize function from you MATLAB prompt. 

```matlab
>> dwGraph.init()
```

This will prompt you to enter your server path and API key. The package will also create graphs of various graphical files of physical annealer and QAC graphs and store them in `_plots/` subfolder of working directory.  

The package contains to few subpackages named
```
* physicalGraph - Contains function related to physical graph of the annealer.
* squareCode    - Contains function related to square code graph.
* pudenzCode    - Contains function related to pudenz code graph. 
```

For example, following functions will return the total number of qubits on each graph. The following output is obtained on DW2X annealer.

```matlab
>> dwGraph.physicalGraph.get_total_qubits()
ans =
   1152
>> dwGraph.physicalGraph.get_total_qubits()
ans =
   288
>> dwGraph.physicalGraph.get_total_qubits()
ans =
   288
```

You can get information about all functions of the package by MATLAB `help` function.

```matlab
>> help dwGraph.submit_ising
 SUBMITINSTANCE submits an physical Ising instance to DWave and returns the result.
 USAGE:
    result = submit_ising(h_physical,J_physical,param)
 
 INPUT:
    h_physical  : The physical local fields.
    J_physical  : The physical couplings.
        Coulings will be scaled down to [-1,1] range if necessary. No scale up would be done.
    param      : parameters to be send to DW2.
 OUTPUT:
    result     : The raw result from D-Wave
```

The other function of note is `dwGraph.submit_ising_ecc` which can be invoked as

```matlab
>> result = dwGraph.submit_ising_ecc(h_logical,J_logical,param,@dwGraph.squareCode.logical_to_physical_ham)
```
to submit a problem on square code graph.

### Contact

You can contact the author at `anuragmi (at) usc.edu` if you need any help regarding the package. You can find all the functions contained in the package by checking the indvidual function files. This package is still a work in progress, and some decoding functions remain to be optimized.

### License

All right reserved, (c) Anurag Mishra (2016). You may use this package in academic research. Please request for permission if you want to modify and distribute this package. 
