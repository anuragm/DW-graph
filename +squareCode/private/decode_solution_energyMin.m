function [decodedSolutions,maxClusterSize] = decode_solution_energyMin( solution, varargin )
%DECODE_SOLUTION_ENERGYMIN implements a energy minimization scheme on majority vote state.
% Energy minimisation decoding implies that we only decode when mojority of physical qubits
% agrees on a state, 0 otherwise. We term these undecided qubits as ties. On this resulting
% solution, we perform optimization by checking if each of the ``tie" can be flipped in a
% way to lower the energy state.
%
% USAGE:
%  decodedSolutions = decode_solution_EP_optimise(solution,h,J)
%  decodedSolutions = decode_solution_EP_optimise(solution,h,J,maxClusterToOptimize)
% INPUTS:
%    solution : The physical solution matrix from DW2 annealer, 512xnum_reads array
%           h : The logical local fields, 1x128 array
%           J : The logical couplers, 128x128 array
%    maxClusterToOptimize: (Optional) the size of biggest cluster to optimize. If not
%               specified, the default value of 12 qubits is chosen.
%
% OUTPUTS:
%    decodedSolutions : The 128xnum_reads decoded solution.
    
persistent ngbrDict;
if isempty(ngbrDict)
    currentFilePath = mfilename('fullpath');
    parentDir = fileparts(currentFilePath);
    dataLoaded = load(fullfile(parentDir,'../code.mat'));
    ngbrDict = dataLoaded.logicalNgbr;
end

numOfReads = size(solution,2);
numOfLogicalQubits = size(solution,1)/4;
decodedSolutions = decode_solution_majVote(solution); %First decode the solution by majvote.

p = parseArguments(numOfLogicalQubits,varargin);
h = p.Results.h;
J = p.Results.J;
maxClusterToOptimize = p.Results.maxClusterToOptimize;

maxClusterSize = 0;  
%Now we optimize each run with respect to energy. 
for ii=1:numOfReads
    stateVector = decodedSolutions(:,ii);
    tiesLoc = find(stateVector==0); %Find which qubits are tied.
    
    while ~isempty(tiesLoc) %While there are still ties left.
        
        %Find a cluster of ties.
        qubitCluster = findCluster(tiesLoc);
        clusterSize  = length(qubitCluster);
        
        if clusterSize>maxClusterSize
            maxClusterSize = clusterSize;
        end
        
        %Now, optimize this cluster.
        if clusterSize<=maxClusterToOptimize %Don't optimize clusters bigger than this.
            
            h_eff = zeros(clusterSize,1);
            J_eff = zeros(clusterSize,clusterSize);
            for llClusQ=1:clusterSize
                tiedQubit = qubitCluster(llClusQ);
                ngbrs     = ngbrDict(tiedQubit-1)+1; %\pm 1 for MATLAB numbering.
                
                %Effective local field is the local field + field from boundry.
                localField = h(tiedQubit);
                effLocalFieldDueToBoundary = 0;
                for iiNgbr = 1:length(ngbrs)
                    effLocalFieldDueToBoundary = effLocalFieldDueToBoundary + ...
                        (J(tiedQubit,ngbrs(iiNgbr))+J(ngbrs(iiNgbr),tiedQubit))* ...
                        stateVector(ngbrs(iiNgbr));  
                end
                
                h_eff(llClusQ) = localField + effLocalFieldDueToBoundary;
                
                for jj=(llClusQ+1):clusterSize 
                    J_eff(llClusQ,jj) = J(qubitCluster(llClusQ),qubitCluster(jj)) + ...
                        J(qubitCluster(jj),qubitCluster(llClusQ));
                end
            end
            
            [clusterSoln,~] = exactSolver(h_eff,J_eff);
            stateVector(qubitCluster) = clusterSoln;
            
        else
            %Optimize by flip decoding.
            stateVector(qubitCluster) = 2*randi([0,1],size(qubitCluster))-1;
        end    
        
        %Remove the optimized qubits from tied locations.
        tiesLoc = MY_setdiff(tiesLoc,qubitCluster);
    end
    decodedSolutions(:,ii) = stateVector;
end

end

% -----------------------------------------------------------------------%
%Parsing sub function.
function p = parseArguments(numOfLogicalQubits,variableArg)
    p = inputParser;
    
    %Accept the ISING parameters h and J
    h_validValues = @(x) (isnumeric(x) && (length(x(:))==numOfLogicalQubits));
    J_validValues = @(x) (isnumeric(x) && (isequal(size(x), ... 
                                           [numOfLogicalQubits numOfLogicalQubits])));
    defaultMaxClusterToOptimize = 12;
    p.addRequired('h',h_validValues);
    p.addRequired('J',J_validValues);
    p.addOptional('maxClusterToOptimize',defaultMaxClusterToOptimize,@isnumeric);
    
    p.CaseSensitive = false;
    p.parse(variableArg{:});
end

% -----------------------------------------------------------------------%
%Cluster finding subfunction.
function qubitCluster = findCluster(tiesLoc) 
% Finds a cluster on squareCode graph, where the qubits are tied at location `tiesLoc'.

% -- We would here like to note that the cluster found might not be actually a
% cluster as defined by the J matrix of the problem, but rather looks like cluster
% on the logical graph. This does not changes any conclusions (the optimized answer),
% however, the algorithm might work on "clusters" which are diconnected in the
% problem, but are neighbors of the logical graph. This increases the complexity of
% decoding to a certain extent. 

    persistent ngbrDict;
    if isempty(ngbrDict)
        currentFilePath = mfilename('fullpath');
        parentDir = fileparts(currentFilePath);
        dataLoaded = load(fullfile(parentDir,'../code.mat'));
        ngbrDict = dataLoaded.logicalNgbr;
    end
    
    qubitCluster = tiesLoc(1); %Pick the first remaining tied qubit.
    clusterCompleted = false;
    while ~clusterCompleted

        ngbrs = [];                          
        for iiQubitCluster=1:length(qubitCluster)
            ngbrs = [ngbrs ngbrDict(qubitCluster(iiQubitCluster)-1)+1];%#ok
        end
        
        tiedNgbrs = MY_intersect(tiesLoc,ngbrs);
        
        %Inline unique trick from http://goo.gl/IwsKeb
        newCluster = sort([qubitCluster(:); tiedNgbrs(:)]);
        newCluster(newCluster((1:end-1)') == newCluster((2:end)')) = []; %Drop non-unique values.
        if length(newCluster)>length(qubitCluster)
            qubitCluster = newCluster;
        else
            clusterCompleted = true;
        end
    end
    qubitCluster = sort(qubitCluster);
end
% -----------------------------------------------------------------------%
% Custom function to speed up intersection. http://goo.gl/fBwQSc
function C = MY_intersect(A,B)
    if ~isempty(A)&&~isempty(B)
        P = zeros(1, max(max(A),max(B)) ) ;
        P(A) = 1;
        C = B(logical(P(B)));
    else
        C = [];
    end
end

%Function taken from http://goo.gl/pACfMl
function C = MY_setdiff(A,B)
% MYSETDIFF Set difference of two sets of positive integers (much faster than built-in setdiff)
% C = my_setdiff(A,B)
% C = A \ B = { things in A that are not in B }

    if isempty(A)
        C = [];
        return;
    elseif isempty(B)
        C = A;
        return; 
    else % both non-empty
        bits = zeros(1, max(max(A), max(B)));
        bits(A) = 1;
        bits(B) = 0;
        C = A(logical(bits(A)));
    end
end
