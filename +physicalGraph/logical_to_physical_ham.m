function [h_physical,J_physical] = logical_to_physical_ham(h_logical, J_logical)
%LOGICALTOPHYSICALHAM converts a logical Ising (h,J) to physical Chimera graph (h,J)
%  Usage: [h_physical,J_physical] = logicalToPhysicalHam(h_logical, J_logical)
%
%  For direct phyiscal graph, no conversion needs to be done. Never the less, this function
%  performs some sanity check aout existing qubits and couplings. The returned Ising
%  Hamiltonian can be directly embedded on the machine. Additionally, this can be used as a
%  stub for functions which require a translation function for codes.

%Initialize return arrays
totalQubits = dwGraph.physicalGraph.get_total_qubits();
h_physical = zeros(totalQubits,1);
J_physical = zeros(totalQubits,totalQubits);

%Load the code and neighbor matrix once.
persistent holes; persistent ngbrs;
if isempty(ngbrs)
    currentFilePath = mfilename('fullpath');
    parentDir = fileparts(currentFilePath);
    ngbrLoaded  = load(fullfile(parentDir,'code.mat'));
    holesLoaded = load(fullfile(parentDir,'holes.mat'));
    ngbrs = ngbrLoaded.logicalNgbr; 
    holes = holesLoaded.holes;
end

J_logical = triu(J_logical + J_logical'); %This ensures that both J_ij and J_ji are added,
                                          %so that we only have to check upper triangle for
                                          %values. 

for ii=1:totalQubits
    physicalQubit = ii-1; %\pm 1 for MATLAB indexing.
    
    %Translate h
    if ismember(physicalQubit,holes) && h_logical(ii)~=0 %If qubit being refered is invalid
        errSummary = 'translate:NonExistantQubit';
        errDesc    = sprintf(['The translation of non existant physical qubit %d cannot be ' ...
                            'done'],ii-1);
        errObj = MException(errSummary,errDesc);
        throw(errObj);
    end
    h_physical(ii)=h_logical(ii);
    
    %Translate J.
    coupledQubits = find(J_logical(ii,:)~=0)-1; %Qubits this qubit couples to.
    qubit1 = ii-1;
    for qubit2=coupledQubits(coupledQubits>qubit1) %Upper triangle.
        if ~ismember(qubit2,ngbrs(qubit1)) %If coupling doesn't exist.
            errSummary = 'translate:NonExistantCoupling';
            errDesc    = sprintf(['The coupling between physical qubit %d and %d doesn''t ' ...
                                'exists on physical graph'],qubit1,qubit2);
            errObj = MException(errSummary,errDesc);
            throw(errObj);
        end
        
        physicalQubit1 = qubit1+1;
        physicalQubit2 = qubit2+1; %+1 for MATLAB numbering.
        
        J_physical(physicalQubit1,physicalQubit2) = J_logical(qubit1+1,qubit2+1);
    end
end

end %End of function.
