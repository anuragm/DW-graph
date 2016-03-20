function [code,holes,logicalNgbr] = generate_code(varargin)
%GENERATE_CODE generates the code, holes and neighbors dictionary for squareCode on given
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
% also generated. Both these quantities are saved to file code.mat. The holes,the missing
% qubits, are also saved in holes.mat. 
  
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

%Generate the code dictionary.

totalLogicalQubit = totalQubits/4; 
keySet = 0:1:(totalLogicalQubit-1);
valueSet{length(keySet)}=[];
cellSize = sqrt(totalLogicalQubit/2);

for ii=1:length(keySet)
    %Find out the location of logical qubit on physical graph, and then corresponding
    %physical qubits.
    unitCellY = floor(keySet(ii)/16);
    unitCellX = mod(keySet(ii),8);
    isDownHalf = (mod(keySet(ii),16)>7); 
    
    physicalQubit1 = 8*(8*unitCellY+unitCellX) + (isDownHalf*2); %Top-left qubit.
    physicalQubit2 = physicalQubit1 + 1;                         %Bottom-left qubit.
    physicalQubit3 = physicalQubit1 + 4;                         %Top-right qubit.
    physicalQubit4 = physicalQubit1 + 5;                         %Bottom-right qubit.
    
    phyQubitCandidate = [physicalQubit1 physicalQubit2 physicalQubit3 physicalQubit4];

    %The qubit is invalid if either of the qubits are missing or one of the internal
    %coupling is missing.
    isQubitMissing = ~isempty(intersect(phyQubitCandidate,physicalHoles));
    isPenaltyMissing = ~(is_valid_coupling(physicalQubit1,physicalQubit3,workingCouplers) && ...
        is_valid_coupling(physicalQubit1,physicalQubit4,workingCouplers) && ...
        is_valid_coupling(physicalQubit2,physicalQubit3,workingCouplers) && ...
        is_valid_coupling(physicalQubit2,physicalQubit4,workingCouplers));
        
    if isQubitMissing || isPenaltyMissing
        valueSet{ii}=[];
        holes = [holes keySet(ii)]; %#ok
    else
        valueSet{ii}=phyQubitCandidate;
    end
end

code = containers.Map(keySet,valueSet);

%Generate a map that contains the logical neighbors of any logical qubit. Since square code
%is degree 5 graph, maximum number of neighbors is 5.
clearvars valueSet keySet;
keySet = 0:1:(totalLogicalQubit-1);
valueSet{length(keySet)}=[];

for ii=1:length(keySet)
    currentQubit = keySet(ii);
    
    if ismember(currentQubit,holes)
        valueSet{ii} = [];
        continue;
    end
    
    physicalQubits = code(currentQubit);
    ngbrs = [];
    %We have four neighbor in this layer, and one in the other layer. 
    isLeftEdge  = 2*( (currentQubit==0)||(mod(currentQubit,cellSize)~=0) ) - 1; %Is -1 for left
                                           %edge except 0, 1 otherwise.
    isRightEdge = 2*(mod(currentQubit+1,cellSize)~=0)-1;    %Is -1 for right edge, 1 otherwise.
    whichLayer  = 2*(mod(currentQubit,16)<8)-1; %Backlayer +1, Front layer -1
    
    perspectiveNgbrs = [(currentQubit+1)*isRightEdge (currentQubit-1)*isLeftEdge ... 
                        currentQubit+2*cellSize currentQubit-2*cellSize currentQubit+whichLayer*8];
    ngbrCandidates = setdiff(intersect(perspectiveNgbrs,keySet),holes); %filter out invalid
                                                                        %qubits
    %Now, we check each candidate to make sure that the required physical couplings exist.
    for candidate=ngbrCandidates
       candidatePhysical = code(candidate);
        
        %If left/right neighbors, check the horizontal couplings
       if abs(currentQubit-candidate)==1 %Left-right neighbors
        isValidNgbr = is_valid_coupling(physicalQubits(3),candidatePhysical(3),workingCouplers) ...
                && is_valid_coupling(physicalQubits(4),candidatePhysical(4),workingCouplers);
       elseif abs(currentQubit-candidate)==2*cellSize %Vertical neighbors
        isValidNgbr = is_valid_coupling(physicalQubits(1),candidatePhysical(1),workingCouplers) ...
                && is_valid_coupling(physicalQubits(2),candidatePhysical(2),workingCouplers);
       elseif (currentQubit-candidate)== 8 %Front-back neighbor
        isValidNgbr = is_valid_coupling(physicalQubits(1),candidatePhysical(4),workingCouplers) ...
               && is_valid_coupling(physicalQubits(3),candidatePhysical(2),workingCouplers);
       elseif (currentQubit-candidate) == -8 %back-Front neighbor
        isValidNgbr = is_valid_coupling(physicalQubits(2),candidatePhysical(3),workingCouplers) ...
             && is_valid_coupling(physicalQubits(4),candidatePhysical(1),workingCouplers);
       end
        
       if isValidNgbr
           ngbrs = [ngbrs candidate]; %#ok
       end
    end
    valueSet{ii} = ngbrs;
end

logicalNgbr = containers.Map(keySet,valueSet); 

%Saves the codes to code.mat, and holes to holes.mat in package directory.
currentFilePath = mfilename('fullpath');
parentDir = fileparts(currentFilePath);
codeFile = fullfile(parentDir,'code.mat');
holeFile = fullfile(parentDir,'holes.mat');

save(codeFile,'code','logicalNgbr');
save(holeFile,'holes');
end
