function decodedSolutions = decode_solution_RandomFlip( solution )
%DECODE_SOLUTION_RANDOMFLIP Decodes by majority vote, followed by random flips for ties.
%We decode the logical qubits by using majority vote. If there is a tie, we
%break it by random coin toss. 

%Input :
%  solution         - a 512xnum_read array from DW2
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
        %Do nothing if qubits wasn't used on hardware solver.
        continue;
    end
    
    %After this step, if majorityVote(ii)>0, it was upSpin. If <0,
    %downSpin, if 0, we flip a coin to break the tie.    
    tiedLocations = find(majorityVote==0);
    randomCoinBreak = 2*randi([0,1],size(tiedLocations))-1; %generate Random \pm 1
    majorityVote(tiedLocations) = randomCoinBreak; %Fix the zeros with these generated \pm 1
                                                   %values

    decodedSolutions(logicalQubit+1,:) = 2*(majorityVote>0)-1; %decode by majority vote on
                                                               %"fixed" solutions.
    
end

end
