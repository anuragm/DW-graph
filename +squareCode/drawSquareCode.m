%This files generates the sqaure encoded graph by use of helper function
%drawHamiltonian.

currentFilePath = mfilename('fullpath');
parentDir = fileparts(currentFilePath);
codeFile = fullfile(parentDir,'code.mat');
load(codeFile,'logicalNgbr');
totalLogicalQubits = length(logicalNgbr);

z = ones(1,totalLogicalQubits);
h = ones(1,totalLogicalQubits);
J = zeros(totalLogicalQubits,totalLogicalQubits);

for qubit = 0:(totalLogicalQubits-1)
    neighbours = dwGraph.squareCode.get_ngbrs(qubit);
    for jj=neighbours
        J(qubit+1,jj+1)=-1;
    end
end

showFields=false;
dwGraph.squareCode.draw_hamiltonian('squareCode',h,J,z,showFields);
