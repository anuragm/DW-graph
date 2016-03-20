function decodedSolutions = decode_solution(solution,varargin)
%DECODE_SOLUTION decodes a solution matrix generated from DW2
%This function takes the raw solution generated from DW2, and decodes it
%by the required strategy (majority vote, or EP)
% Usage: 
%   decodedSolutions = decode_solution(solution)
%   decodedSolutions = decode_solution(solution,strategy)   
% Input:
%   solution - a numOfQubitsxnum_read array of solution from DWave
%   strategy - Either 'majVote', in which case the three data qubits decide the state of
%              logical qubit with a majority vote, or 'EP', in this case the qubit is up or
%              down by unanimous vote. If the vote is not unanimous, the state of logical
%              state is set to 0,i.e. a tie.  
    
%Load required code file.
persistent code; persistent holes;
if isempty(code) || isempty(holes)
    currentFilePath = mfilename('fullpath');
    parentDir = fileparts(currentFilePath);
    codeFile = fullfile(parentDir,'code.mat');
    holeFile = fullfile(parentDir,'holes.mat');
    dataLoaded = load(holeFile);
    holes = dataLoaded.holes;
    dataLoaded= load(codeFile);
    code = dataLoaded.code;
end

p = inputParser; %To parse the variable input.
defaultStrategy = 'majvote';
validStrategy = {'majvote','ep'};
checkStrategy = @(x) any(validatestring(x,validStrategy));

p.addRequired('solution',@isnumeric);
p.addOptional('strategy',defaultStrategy,checkStrategy);
p.CaseSensitive = false;

p.parse(solution,varargin{:});

strategy = p.Results.strategy;

numOfLogicalQubits = size(solution,1)/4;
numOfReads = size(solution,2);
decodedSolutions = 3*ones(numOfLogicalQubits,numOfReads);

for logicalQubit=setdiff(0:1:(numOfLogicalQubits-1),holes)

    physicalQubits = code(logicalQubit)+1; %+1 for MATLAB indexing
    
    majorityVote = sum(solution(physicalQubits(1:3),:),1);
    if majorityVote(1) == 12 %if qubits were unused.
        continue;
    end
    
    if strcmpi(strategy,'majvote')
        decodedSolutions(logicalQubit+1,:) = +1*(majorityVote>0)-1*(majorityVote<0);
    elseif strcmpi(strategy,'ep')
        decodedSolutions(logicalQubit+1,:) = +1*(majorityVote==3)-1*(majorityVote==-3);
    else
        errObj = MException('pudenzCode:decodeSolution',['Invalid strategy to decode ' ...
                            'results']);
        throw(errObj);
    end
end

end
