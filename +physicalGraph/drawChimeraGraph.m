%This file generates the Chimera graph for given solver.

%Load code dictionary.
currentFilePath = mfilename('fullpath');
parentDir = fileparts(currentFilePath);
codeFile = fullfile(parentDir,'code.mat');
load(codeFile,'logicalNgbr');
numOfQubits = length(logicalNgbr);

h = ones(1,numOfQubits);
J = zeros(numOfQubits,numOfQubits);
for qubit=0:1:(numOfQubits-1)
    neighbours = logicalNgbr(qubit);
    for jj=(neighbours(neighbours>qubit))
        J(qubit+1,jj+1)=1;
    end
end

physicalGraph.draw_hamiltonian('chimeraGraph',h,J);
