%Initialises data for using the various chip access functions.

%% Create the solver datafile
if ~(exist('solverSettings.mat','file')==2)
    urlDwave = input('Enter the URL to access the DWave Machine : ','s');
    myToken = input('Enter the token which you want to use to access the machine : ','s');
    solverName = input('Enter the name of solver (case sensitive) : ','s');
    save solverSettings.mat urlDwave myToken solverName
else
    fprintf('Solver setting for the machine already exist. \n');
end

%% Create the code and other dictionaries for all codes.
pkgs = {'squareCode','pudenzCode','physicalGraph'};
for ii=1:length(pkgs)
    pkg = pkgs{ii};
    hGenCode = str2func([pkg '.generate_code']);
    hGenCode();
end
fprintf('Generated all the code dictionaries for different graphs\n');

%% Generate the plots of the graph and save them to _plot directory.

if ~(exist('_plots','dir')==7)
    mkdir('_plots');
end

newPlots = false;
if ~(exist('_plots/pudenzCode.pdf','file')==2)
    pudenzCode.drawPudenzCode; newPlots = true;
else
    fprintf('Graph for Pudenz code already exists. \n');
end

if ~(exist('_plots/squareCode.pdf','file')==2)
    squareCode.drawSquareCode; newPlots = true;
else
    fprintf('Graph for Square code already exists. \n');
end

if ~(exist('_plots/chimeraGraph.pdf','file')==2)
    physicalGraph.drawChimeraGraph; newPlots = true;
else
    fprintf('Physical Chimera graph already exists. \n');
end

if newPlots
    movefile('*.tex','_plots/');
    movefile('*-crop.pdf','_plots/');
    movefile('*.pdf','_plots');
end

fprintf('Graphs of all codes exist in folder _plots/ \n');
