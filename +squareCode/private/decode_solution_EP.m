function decodedSolutions = decode_solution_EP(solution)
% DECODE_SOLUTION_EP decodes the solution from machine, by using energy penalty.
%
% Energy penaly decoding implies that we only decode when all the physical
% qubits corresponding to logical qubit end up in same state. As we are
% doing majority vote decode, +4 -> upSpin, -4->downSpin, error other wise,
% denoted by 0 in result.
% Inputs:
%   solution : The 512xnumReads array from DW2
%
% Outputs:
%   decodedSolutions : the 128xnumReads decoded logical solution.

numOfReads = size(solution,2);
decodedSolutions = 3*ones(128,numOfReads);

%Load the holes and code matrix once.
persistent holes; persistent code;
if isempty(holes) || isempty(code)
    currentFilePath = mfilename('fullpath');
    parentDir = fileparts(currentFilePath);
    codeFile = fullfile(parentDir,'../code.mat');
    holeFile = fullfile(parentDir,'../holes.mat');
    dataLoaded = load(holeFile);
    holes = dataLoaded.holes;
    dataLoaded = load(codeFile);
    code = dataLoaded.code;
end

for logicalQubit = setdiff(0:1:127,holes) 
    %Find physical qubits corresponding to this logical qubit
    physicalQubits = code(logicalQubit)+1; %+1 for MATLAB numbering.
    physicalData = solution(physicalQubits,:);
    
    %Perform majority vote
    majorityVote = sum(physicalData,1); 
    
    %Now, majorityVote is 1xnumRead array of bits.
    %Check if this was a non-used qubit. In that case, the sum would be 12.
    if majorityVote(1) == 12 
        EPDecoded = 3*ones(size(majorityVote));
    else
        EPDecoded = 1*(majorityVote==4) - 1*(majorityVote==-4);
    end
    
    decodedSolutions(logicalQubit+1,:) = EPDecoded;

end
end