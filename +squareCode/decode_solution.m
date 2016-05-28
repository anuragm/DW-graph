function [decodedSolutions,varargout] = decode_solution(solution, varargin)
%DECODE_SOLUTION decodes a solution matrix generated from DW2
%This function takes the raw solution generated from DW2, and decodes it
%according to requested decoded strategy. If no specific strategy is
%requested, coin flip to break tie strategy is used.
%Usage: decodedSolutions = decode_solution(solution, strategy,...)
%  Input :
%  solution         - a 512xnum_read array from DW2
%  strategy         - optional, deafult 'flip'; can take value of
%   'majVote': solution is a simple majority vote of 4 physical qubits, 0 if tied.
%   'flip'   : decodes majVote state by breaking tie by random flip
%   'EP'     : Only energy penalty decoding is used.
%   'majVoteOpt' : Ties after majority vote are broken by exactly finding state by lowering
%                  energy. Requires additional ising parameters 'h' and 'J' Thus
%                  decode_solution(solution,'majVoteOpt','h',h_logical,'J',J_logical)      
%    'epOpt'    : performs energy optimisation over EP state. Required additional ising
%                 parameters 'h' and 'J' Thus
%                 decode_solution(solution,'epOpt','h',h_logical,'J',J_logical)      
%   'reducedMajority' : When we want to do majority decoding with less than four
%                       qubits. Parameter value pair ('whichQubits', [xx yy zz])should be
%                       supplied. Example, [1 2 3] would decode by using those three qubits.   
%   'dangling' : Decodes by giving different weights to dangling qubits, which are the
%                physical qubits that don't experience logical inter-qubit coupling. In this
%                case,'listOfQubits' that form the chain and 'weightDangling': the weight on
%                dangling qubits for majority voting should be specified.
%     ...           -  additional elements required for strategy.
%Output:
%  decodedSolutions - a 128xnum_read array which corresponds to
%                     solution on square graph.
    
%Setup a parser to read all the arguments.
p = inputParser;

%Add decoding strategy names.
defaultStrategy = 'flip';
validStrategy = {'flip','majVoteOpt','ep','reducedMajority','dangling','majVote','epOpt'};
checkStrategy = @(x) any(validatestring(x,validStrategy));

%Other optional parameters. 
defaultWhichQubits = [1 2 3]; defaultDanglingWeight = 0.2;
checkWhichQubits = @(x) (length(x)==3);
defaultListOfQubits = -1;

%Add parameters to parser.
p.addRequired('solution',@isnumeric); %We can validate the solution here as well.
p.addOptional('strategy',defaultStrategy,checkStrategy);
p.addParameter('whichQubits',defaultWhichQubits,checkWhichQubits);
p.addParameter('weightDangling',defaultDanglingWeight,@isnumeric);
p.addParameter('listOfQubits',defaultListOfQubits,@isnumeric);
p.addParameter('h',zeros(1,128),@isnumeric);
p.addParameter('J',zeros(128,128),@isnumeric);

%We don't care about capitalization. 
p.CaseSensitive = false;

%Parse the input variables.
p.parse(solution,varargin{:});

listOfQubits   = p.Results.listOfQubits;
whichQubits    = p.Results.whichQubits;
weightDangling = p.Results.weightDangling;
h_logical      = p.Results.h;
J_logical      = p.Results.J;

%Now, we calculate accoring to the strategy we want to use.
switch lower(p.Results.strategy)

  case 'flip'
    decodedSolutions = decode_solution_RandomFlip(solution);
  
  case 'ep'
    decodedSolutions = decode_solution_EP(solution);
  
  case 'reducedmajority'  
    if ismember('whichQubits',p.UsingDefaults)
        warning('Using default set of qubits [1 2 3] for decoding under reduced majority');
    end
    decodedSolutions = decode_solution_reduced_majority(solution,whichQubits);
  
  case 'dangling'
    if ismember('weightDangling',p.UsingDefaults)
        warning('Using default weight of 0.2 for dangling qubit decoding');
    end
    %list of qubits much be specified.
    if(listOfQubits == -1)
        errObj = MException('decodeSolution:energyMin',['A list of qubits forming the chain ' ...
                            'must be supplied for decoding']);
        throw(errObj);
    end
    decodedSolutions = decode_solution_ignore_dangling(solution,listOfQubits,weightDangling);

  case 'majvote'
    decodedSolutions = decode_solution_majVote(solution);
    
  case 'epopt'
    [decodedSolutions,maxClusterSize]=decode_solution_EP_optimize(solution,h_logical,J_logical);
    nout = max(nargout,1)-1;
    if nout==1
        varargout{1} = maxClusterSize;
    end

  case 'majvoteopt'
    [decodedSolutions,maxClusterSize]=decode_solution_energyMin(solution,h_logical,J_logical);
    nout = max(nargout,1)-1;
    if nout==1
        varargout{1} = maxClusterSize;
    end
      
end
    
end
