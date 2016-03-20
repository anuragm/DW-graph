function neighbours = get_ngbrs(qubit,varargin)
%GET_NGBRS Returns the neighbors of requested qubit.
% Usage:
%    neighbours = get_ngbrs(qubit)
%    neighbours = get_chain(qubit,graphType)    
% Inputs:
%    qubit: The qubit whose neighbours are required.
%    graphType: 'CompleteQubitsOnly', default option, ignores neighbors which are missing
%                penalty qubit. 'UseFullGraph' returns neighbors on full graph.     
% Outputs:
%    neighbours : An array of all the neighbours of qubit. Invalid qubits have no neighbours.  
    
%Load the dictionary once.
persistent ngbrDict; persistent codeDict;
if isempty(ngbrDict)
    currentFilePath = mfilename('fullpath');
    parentDir = fileparts(currentFilePath);
    dataLoaded = load(fullfile(parentDir,'code.mat'));
    ngbrDict = dataLoaded.logicalNgbr;
    codeDict = dataLoaded.code;
end

p = parseArguments(varargin{:});

neighbours = ngbrDict(qubit);

if strcmpi(p.Results.graphType,'CompleteQubitsOnly')
    %Remove any logical neighbors that have only 3 physical qubits.
    numOfPhysicalQubits = arrayfun(@(x) length(codeDict(x)),neighbours);
    neighbours = neighbours(numOfPhysicalQubits==4);

    %If this qubit is one of the holes or the orange qubit, return no neighbors, as this is an
    %invalid qubit for our purpose.
    if length(codeDict(qubit))<4 
        neighbours = [];
    end
end

% -----------------------------------------------------------------------%
%Parsing sub function.
function p = parseArguments(varargin)
    p = inputParser;
    %Add the type of graph. 'UseFullGraph' vs 'CompleteQubitsOnly'
    defaultGraph = 'CompleteQubitsOnly';
    validGraphIdentifiers = {'CompleteQubitsOnly','UseFullGraph'};
    checkGraphIdentifiers = @(x) any(validatestring(x,validGraphIdentifiers));
    
    p.addOptional('graphType',defaultGraph,checkGraphIdentifiers);
    
    p.CaseSensitive = false;
    p.parse(varargin{:});
end
% -----------------------------------------------------------------------%

end
