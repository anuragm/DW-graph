function decodedSolutions = decode_solution_reduced_majority( solution, whichQubits )
%DECOLDE_SOLUTION_REDUCED_MAJORITY Decodes by majority vote, with subset of physical qubits.
%We decode the logical qubit by using majority vote, except instead of majority vote over
%all qubits, we only do a majority vote over a subset of physical qubits. It is assumed that
%the number of reduced qubits is odd (1 or 3), so that there are no undecodable states. In
%case two qubits are used to majority vote, logical state might contain zero, which denotes
%a case where majority vote failed. 
%Input :
%   solution    - a 512xnum_reads array from quantum solver
%   whichQubits - a row array of qubits to be used for decoding. Eg [1 2 3] or [4].
%Output:
%   decodedSolutions - a 128xnum_read array which corresponds to
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
    physicalQubits = code(logicalQubit)+1; %+1 for MATLAB numbering
    physicalData = solution(physicalQubits(whichQubits),:);
    
    %Perform majority vote
    majorityVote = sum(physicalData,1);
    if majorityVote(1) == 3*length(whichQubits)
        %Do nothing if qubits wasn't used on hardware solver.
        continue;
    end

    %After the majority vote, the locations which voted positive are upSpin(+1), locations whihc
    %voted negative are downSpin(-1). The location tied would sum to zero, and we assign
    %those states as is.

    decodedSolutions(logicalQubit+1,:) = (majorityVote>0) - (majorityVote<0); 

end

end
