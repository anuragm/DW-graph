function [h_physical,J_physical] = logical_to_physical_ham(h_logical, J_logical, beta)
%LOGICALTOPHYSICALHAM converts a logical Ising (h,J) to physical Chimera graph (h,J)
%  Usage: [h_physical,J_physical] = logicalToPhysicalHam(h_logical, J_logical, beta)
%
%  Given the logical Ising parameters, there is a mapping that maps them to physical Ising
%Hamitonain on Chimera like graph. This funtion takes as input three parameters, the logical
%h, the logical J matrix, and the strength of penalty term, beta. The logical qubits are
%constructed by ferromagnetic stablizer terms, each of strength beta, while the relavent
%logical stablizer operators are constructed on physical graph by use of input logical h and
%J matrix. 

%Initialize return arrays
totalQubits = dwGraph.physicalGraph.get_total_qubits();
totalLogicalQubits = dwGraph.pudenzCode.get_total_qubits();
    
h_physical = zeros(totalQubits,1);
J_physical = zeros(totalQubits,totalQubits);

%Load the code and neighbor matrix once.
persistent code; persistent ngbrs;
if isempty(code)
    currentFilePath = mfilename('fullpath');
    parentDir = fileparts(currentFilePath);
    dataLoaded = load(fullfile(parentDir,'code.mat'));
    code  = dataLoaded.code;
    ngbrs = dataLoaded.logicalNgbr; 
end


J_logical = J_logical + J_logical'; %This ensures that both J_ij and J_ji are added, so that
                                    %we only have to check upper triangle for values.
for ii=1:totalLogicalQubits
    physicalQubits = code(ii-1)+1; %\pm 1 compensate for MATLAB 1-indexing.
    
    %% Translate h
    if isempty(physicalQubits) && h_logical(ii)~=0 %If the qubit being referened is invalid
        errSummary = 'translate:NonExistantQubit';
        errDesc    = sprintf(['The translation of non existant logical qubit %d cannot be ' ...
                            'done'],ii-1);
        errObj = MException(errSummary,errDesc);
        throw(errObj);
    end
    h_physical(physicalQubits)=h_logical(ii)/2;
    
    %% Translate J.
    coupledQubits = find(J_logical(ii,:)~=0)-1; %-1 'cause MATLAB 1-indexing.    
    qubit1 = ii-1;
    for qubit2=coupledQubits(coupledQubits>qubit1) %Check only in upper diagonal, as matrix
                                                   %has alreay be "symmetrised".
        if ~ismember(qubit2,ngbrs(qubit1)) %If coupling doesn't exist.
            errSummary = 'translate:NonExistantCoupling';
            errDesc    = sprintf(['The coupling between logical qubit %d and %d doesn''t ' ...
                                'exists on logical graph'],qubit1,qubit2);
            errObj = MException(errSummary,errDesc);
            throw(errObj);
        end
        physicalQubits1 = code(qubit1)+1;
        physicalQubits2 = code(qubit2)+1;
            
        %Connect the data qubits to each other
        J_physical(physicalQubits1(1),physicalQubits2(1))=J_logical(qubit1+1,qubit2+1);
        J_physical(physicalQubits1(2),physicalQubits2(2))=J_logical(qubit1+1,qubit2+1);
        J_physical(physicalQubits1(3),physicalQubits2(3))=J_logical(qubit1+1,qubit2+1);
        
    end

    %% Add penalty stablizer terms if qubit is being used and penalty qubit exists
    if (h_logical(ii)~=0) || (sum(J_logical(:,ii)~=0)>0)
        if(length(physicalQubits)==4)
            J_physical(physicalQubits(1),physicalQubits(4)) = -beta;
            J_physical(physicalQubits(2),physicalQubits(4)) = -beta;
            J_physical(physicalQubits(3),physicalQubits(4)) = -beta;
        end    
    end
end

end
