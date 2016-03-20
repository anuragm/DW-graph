function [holes,logicalNgbr] = generate_code(varargin)
%GENERATE_CODE generates the holes and neighbors dictionary for Chimera graph.
% USAGE: [holes,logicalNgbr] = generate_code(solver)
%        [holes,logicalNgbr] = generate_code()
% Inputs is either blank, in case where the file solverSettings.mat is used to generate a
% solver, or if a DW2 solver is provided, it is used to generate relavent parameters for
% that solver. 
%
% This function generates a neighbor dictionary variable which contains the neighbors of a
% given physical qubit. It also generates a list of holes, which is saved to a file as well.
    
%Create solver if not supplied as argument.
if isempty(varargin)
    if exist('solverSettings.mat','file')==2
        load('solverSettings.mat','urlDwave','myToken','solverName');
    else
        errObj = MException('genCode:noSolver',['No solver supplied as argument, and ' ...
                            'solverSettings.mat does not exists']);
        throw(errObj);
    end
    
    while(true)
        try
            connHandle = sapiRemoteConnection(urlDwave,myToken);
            solver = sapiSolver(connHandle,solverName);
            break;
        catch errorE
            disp(errorE)
            fprintf(['Fatal error in creating a solver. Are you sure you can connect' ...
                     ' to DW2? \n']);     
            fprintf('Retrying in 60 seconds...\n');
            pause(60);
        end
    end    
else
    solver = varargin{1};
end
    
propertiesDW = sapiSolverProperties(solver);
workingQubits = propertiesDW.qubits; %column vector
workingCouplers = propertiesDW.couplers; %2xnumberOfCouplings matrix
totalQubits = propertiesDW.num_qubits; %Total number of qubits on graph, working or
                                       %otherwise

%holes are the non-functional qubits.
holes = setdiff(0:1:(totalQubits-1), workingQubits');

%Construct a code map.
keySet = 0:1:(totalQubits-1);
valueSet{length(keySet)}= []; 

J = zeros(totalQubits,totalQubits);
%Construct an adjacency matrix from working couplers. 
for ii=1:size(workingCouplers,2)
    qubitX = workingCouplers(1,ii);
    qubitY = workingCouplers(2,ii);
    J(qubitX+1,qubitY+1) = 1;
    J(qubitY+1,qubitX+1) = 1;
end

if ~isequal(J,J')
    errObj = MException('code:MissingCouplers',['The adjacency matrix generated from list ' ...
                        'of couplers is not symmetric']);
    throw(errObj);
end

for ii=1:totalQubits
    ngbrs = find(J(ii,:)~=0)-1; %Subtract one to convert to zero numbering
    valueSet{ii} = ngbrs;
end

%Create the map.
logicalNgbr = containers.Map(keySet,valueSet);

%And now save all these structures.
currentFilePath = mfilename('fullpath');
parentDir = fileparts(currentFilePath);
codeFile = fullfile(parentDir,'code.mat');
holeFile = fullfile(parentDir,'holes.mat');

save(codeFile,'logicalNgbr');
save(holeFile,'holes');

end