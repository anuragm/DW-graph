%This file generates a Pudenz code graph for given solver.

%Load code dictionary.
currentFilePath = mfilename('fullpath');
parentDir = fileparts(currentFilePath);
codeFile = fullfile(parentDir,'code.mat');
load(codeFile,'code','logicalNgbr');

totalQubits = 288;

h = ones(1,totalQubits);
J = zeros(totalQubits,totalQubits);
for qubit=0:(totalQubits-1)
    neighbours = logicalNgbr(qubit);
    for jj=neighbours
        J(qubit+1,jj+1)=1;
    end
end

pudenzCode.draw_hamiltonian('pudenzCode',h,J);
