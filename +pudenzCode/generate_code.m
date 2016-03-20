function [code,holes,logicalNgbr] = generate_code(varargin)
%GENERATE_CODE generates the code, holes and neighbors dictionary for pudenzCode on given
%physical graph.
% USAGE: [code,holes,logicalNgbr] = generate_code(solver)
%        [code,holes,logicalNgbr] = generate_code()
% Inputs is either blank, in case where the file solverSettings.mat is used to generate a
% solver, or if a DW2 solver is provided, it is used to generate relavent parameters for
% that solver. 
%
% This function generates a code dictionary, where keys are the integers from 0 to 127, the
% 128 logical qubits. The values of each key is an array, which is the list of physical
% qubits that correspond to that logical qubit.
% Additionally, a second variable which contains the neighbors of a given logical qubit is
% also generated. Both these quantities are saved to file code.mat. 
  
import physicalGraph.is_valid_coupling;

holes = [];
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
totalQubits = propertiesDW.num_qubits; %Total number of qubits on graph, working or otherwise
%holes are the non-functional qubits on physical graph.
physicalHoles = setdiff(0:1:(totalQubits-1), workingQubits');

%From here on, we travese unit cell by unitcell and see if we can get group of three qubits on
%one half of the cell, and the penalty qubit on the other side. The first three qubits are the
%data qubits, the last qubit is the penalty qubit. If the last qubit is missing, we can still
%work with three qubits, with a penalty term missing.

totalLogicalQubit = totalQubits/4; 
keySet = 0:1:(totalLogicalQubit-1);
valueSet{length(keySet)}=[];
cellSize = sqrt(totalLogicalQubit/2);
for ii=0:8:(totalQubits-8) %Assuming unit cells of size 8.

    leftLogical = 2*floor(ii/8); rightLogical = leftLogical+1;
    leftPhysical = [ii ii+1 ii+2];
    rightPhysical = [ii+4 ii+5 ii+6];
    
    %Add the penalty qubits if present.
    if ~ismember(ii+7,physicalHoles)
        leftPhysical = [leftPhysical ii+7]; %#ok
    end
    if ~ismember(ii+3,physicalHoles)
        rightPhysical = [rightPhysical ii+3];  %#ok
    end
    
    if ~isempty(intersect(leftPhysical(1:3),physicalHoles)) %Is data qubit missing on left.
        leftPhysical = [];
        holes = [holes leftLogical]; %#ok
    end

    if ~isempty(intersect(rightPhysical(1:3),physicalHoles)) %Is data qubit missing on right.
        rightPhysical = [];
        holes = [holes rightLogical]; %#ok
    end
    
    valueSet{leftLogical+1} = leftPhysical;
    valueSet{rightLogical+1} = rightPhysical;
end

code = containers.Map(keySet,valueSet);
%Now, we shall check if the neighbor-neighbor physical links exist. For each qubit, there
%are at max three other neighbors. We shall check if these three neighbors can be actaully
%connected, and add them to neighbor dictionary.

clearvars valueSet keySet;
keySet = 0:1:(totalLogicalQubit-1);
valueSet{length(keySet)}=[];
validLogicalQubits = setdiff(keySet,holes);
for ii=keySet

    if ismember(ii,holes)
        valueSet{ii+1}=[];
        continue;
    end
    
    %There are three neighbors, one on left/right or up/down, and other in the same unit cell.
    ngbrs = [];
    physicalQubits = code(ii);
    %Check if all the the links for up-down and in-unit cell exist.
    if mod(ii,2)==0 %Logical qubit from left half of unit cell.  
        candidates =  intersect([ii+1 ii+2*cellSize ii-2*cellSize],validLogicalQubits);
    else            %Logical qubit from right half of unit cell.
        candidates = intersect([ii-2 ii-1 ii+2],validLogicalQubits);
    end
    
    for candidate = candidates
        if ismember(candidate,holes)
            continue;
        end
        candidatePhysical = code(candidate);
        if is_valid_coupling(physicalQubits(1),candidatePhysical(1),workingCouplers) && ...
                is_valid_coupling(physicalQubits(2),candidatePhysical(2),workingCouplers) && ...
                is_valid_coupling(physicalQubits(3),candidatePhysical(3),workingCouplers)
            ngbrs = [ngbrs candidate]; %#ok
        end
    end
    
    valueSet{ii+1} = ngbrs;
end
logicalNgbr = containers.Map(keySet,valueSet);        

%And now save all these structures.
currentFilePath = mfilename('fullpath');
parentDir = fileparts(currentFilePath);
codeFile = fullfile(parentDir,'code.mat');
holeFile = fullfile(parentDir,'holes.mat');

save(codeFile,'code','logicalNgbr');
save(holeFile,'holes');

end
