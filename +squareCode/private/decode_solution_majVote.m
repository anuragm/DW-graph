function decodedSolutions = decode_solution_majVote(solution)
%DECODE_SOLUTION_MAJVOTE decodes by majority vote, and returns ties as is.
%We deocde the logical qubits by using majority vote. Qubit marked 3 were no used in
%probalem, +1 denotes up spin, -1 denotes down spin while 0 is a tie. 
%
% USAGE: 
%  decodedSolutions = decode_solution_majVote(solution)
% INPUT:
%  solution : is the 512xnum_read array from DW2.
%Output:
%  decodedSolutions - a 128xnum_read array which corresponds to
%                     solution on square graph.


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

numOfReads = size(solution,2); %Finds out number of reads.
decodedSolutions = 3*ones(128,numOfReads); %Invalid/non-used qubits default to three, just
                                           %like on DW2

for logicalQubit=setdiff(0:1:127,holes)
    
    %Find physical qubits corresponding to this logical qubit
    physicalQubits = code(logicalQubit)+1; %+1 for MATLAB indexing. 
    physicalData = solution(physicalQubits,:);
    
    %Perform majority vote
    majorityVote = sum(physicalData,1);
    if majorityVote(1) == 12 
        %If qubits wasn't used on hardware solver, do nothing.
        continue;
    end

    decodedSolutions(logicalQubit+1,:) = (majorityVote>0) - (majorityVote<0); %+ 0*(majVote==0)
end

end
