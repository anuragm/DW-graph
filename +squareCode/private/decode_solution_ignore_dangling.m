function decodedSolutions = decode_solution_ignore_dangling( solution, listOfQubits, ...
                                                  weightDangling )
%DECOLDE_SOLUTION_IGNORE_DANGLING Decodes by ignoring dangling qubits.
% We decode by ignoring the dangling qubit, i.e., the qubits which are not part of problem
%qubit. This occurs because of the connectivity graph. If logical qubits are part of
%straight chain, then only the qubits on right/left are used. We would like to prefer the
%problem qubits, and demote contribution of dangling qubits.  
% If a tie still persists, it is broken by random flips. (For now)
%
%Input :
%   solution       - a 512xnum_reads array from quantum solver
%   weightDangling - a fraction between 0 and 1, which tells how much weight should dangling
%   qubits have in decoding scheme. The weight on qubits that are part of problem is
%   (1-weightDangling). 
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

%If invalid qubits are used in chains, throw error and abort
if ~isempty(intersect(holes,listOfQubits))
    err = MException('DecodeSolution:InvalidLogicalQubits',['The logical AFM chain contains' ...
                      ' invalid qubits']);
    throw(err);
end

numOfReads = size(solution,2); %Finds out number of reads.
decodedSolutions = 3*ones(128,numOfReads); %Invalid/non-used qubits default to three, just
                                           %like on DW2

%We construct the degree of connection of each qubit. To do this, construct the
%physical J martix, and from the symettric physical J matrix, we can get the adjeceny
%matrix. Sum the adjeceny matrix to get the degree of connectivity for each qubit. 

%Construct a logical h and J
h_logical = zeros(1,128);
J_logical = zeros(128,128);

%Connect qubits by AFM coupling in chain
for ii=1:(length(listOfQubits)-1)
    qubit1 = listOfQubits(ii)+1; %+1 to accomodate for MATLAB indexing.
    qubit2 = listOfQubits(ii+1)+1;
    J_logical(qubit1,qubit2) = 1;
end

%Get the physical Hamiltonian, with penalty strength of 1 applied.
[~, J_physical] = squareCode.logicalToPhysicalHam(h_logical,J_logical,1);
if ~isequal(J_physical,J_physical')
    J_physical = J_physical + J_physical';
end

%Create adjeceny matrix from this.
physicalAdjeceny = (J_physical~=0);
physicalQubitDegree = sum(physicalAdjeceny,1);

for logicalQubit=listOfQubits
    
    %Find physical qubits corresponding to this logical qubit
    physicalQubits = code(logicalQubit)+1; %+1 for MATLAB indexing.
    %Dangling qubits have only two neighbors, the penalty term connections.
    danglingQubits = physicalQubits(physicalQubitDegree(physicalQubits)==2);
    notDanglingQubits = setdiff(physicalQubits,danglingQubits);
    majorityVote = weightDangling*sum(solution(danglingQubits,:),1) + (1-weightDangling)* ...
        sum(solution(notDanglingQubits,:),1);
    
    %After this step, if majorityVote(ii)>0, it was upSpin. If <0,
    %downSpin, if 0, we flip a coin to break the tie.    
    tiedLocations = find(majorityVote==0);
    randomCoinBreak = 2*randi([0,1],size(tiedLocations))-1; %generate Random \pm 1
    majorityVote(tiedLocations) = randomCoinBreak; %Fix the zeros with these generated \pm 1
                                                   %values
    decodedSolutions(logicalQubit+1,:) = (majorityVote>0)-(majorityVote<0);

end

end
